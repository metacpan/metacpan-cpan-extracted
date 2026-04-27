package Stress::Workload;
use strict;
use warnings;
use Future;
use Future::AsyncAwait;
use Future::IO;
use Time::HiRes qw(time);
use Scalar::Util qw(blessed);

# Each run_* function is an async sub that loops until $stop is ready.
# Errors are typed and counted on $metrics; the harness halts only on
# integrity violations, not on per-op errors.

async sub run_kv {
    my %args = @_;
    my $pool      = $args{pool};
    my $metrics   = $args{metrics};
    my $integrity = $args{integrity};
    my $stop      = $args{stop};
    my $buckets   = $args{buckets}    // 64;
    my $prefix    = $args{key_prefix} // 'stress:kv';

    my $seq = 0;

    while (!$stop->is_ready) {
        my $bucket = int rand $buckets;
        my $key    = "${prefix}_b${bucket}";

        if (rand() < 0.5) {
            $seq++;
            my $value = "seq=${seq}:rand=" . int(rand 1_000_000);
            my $t0 = time;
            my $ok = eval {
                await $pool->with(sub {
                    my ($r) = @_;
                    return $r->set($key, $value);
                });
                1;
            };
            $metrics->record_latency('set', time - $t0) if $ok;
            if ($ok) {
                $metrics->incr_op('set');
            } else {
                _record_error($metrics, $@);
            }
        } else {
            my $t0 = time;
            my $val;
            my $ok = eval {
                $val = await $pool->with(sub {
                    my ($r) = @_;
                    return $r->get($key);
                });
                1;
            };
            $metrics->record_latency('get', time - $t0) if $ok;
            if ($ok) {
                $metrics->incr_op('get');
                if (defined $val && $val =~ /^seq=(\d+):/) {
                    $integrity->note_kv_observation("b${bucket}", $1);
                }
            } else {
                _record_error($metrics, $@);
            }
        }

        await Future::IO->sleep(0);
    }
    return;
}

sub _record_error {
    my ($metrics, $err) = @_;
    my $type = (blessed($err) && $err->isa('Async::Redis::Error'))
        ? ref($err)
        : 'Unclassified';
    $metrics->{errors_typed}{$type}++;
    return;
}

async sub run_autopipe {
    my %args = @_;
    my $client     = $args{client};
    my $metrics    = $args{metrics};
    my $stop       = $args{stop};
    my $burst_size = $args{burst_size} // 100;
    my $prefix     = $args{key_prefix} // 'stress:ap';

    my $seq = 0;

    while (!$stop->is_ready) {
        my @futures;
        my $t0 = time;
        for my $i (1 .. $burst_size) {
            $seq++;
            my $key = "${prefix}_${seq}";
            push @futures, $client->set($key, "seq=${seq}");
        }
        my $ok = eval { await Future->wait_all(@futures); 1 };
        if ($ok) {
            my $count = grep { $_->is_done } @futures;
            $metrics->incr_op('set', $count);
            my $elapsed = time - $t0;
            $metrics->record_latency('autopipe_burst', $elapsed);
            for my $f (@futures) {
                next unless $f->is_failed;
                _record_error($metrics, ($f->failure)[0]);
            }
        } else {
            _record_error($metrics, $@);
        }
        await Future::IO->sleep(0);
    }
    return;
}

async sub run_blocking_consumer {
    my %args = @_;
    my $client    = $args{client};
    my $metrics   = $args{metrics};
    my $integrity = $args{integrity};
    my $queue     = $args{queue};
    my $stop      = $args{stop};

    while (!$stop->is_ready) {
        my $t0 = time;
        my $res;
        my $ok = eval {
            $res = await $client->blpop($queue, 1);  # 1-second BLPOP timeout
            1;
        };
        if ($ok) {
            # BLPOP returns undef on timeout, an arrayref on success.
            # Only a successful pop counts as a queue operation; a
            # timeout means we waited and got nothing.
            if (defined $res) {
                $metrics->record_latency('blpop', time - $t0);
                $metrics->incr_op('blpop');
                $integrity->note_queue_popped;
            }
        } else {
            _record_error($metrics, $@);
        }
    }
    return;
}

async sub run_blocking_driver {
    my %args = @_;
    my $client    = $args{client};
    my $metrics   = $args{metrics};
    my $integrity = $args{integrity};
    my $queue     = $args{queue};
    my $rate_hz   = $args{rate_hz} // 100;
    my $stop      = $args{stop};

    my $seq = 0;
    my $period = 1.0 / $rate_hz;

    while (!$stop->is_ready) {
        $seq++;
        my $job = "job_${seq}";
        # Pre-increment pushed BEFORE the await. Otherwise the Perl event
        # loop can fire the consumer's BLPOP-response continuation before
        # the driver's LPUSH-response continuation, creating a transient
        # popped > pushed state even though Redis itself never popped a
        # phantom message. By bumping pushed synchronously, any BLPOP
        # wakeup necessarily sees pushed >= corresponding popped.
        #
        # We do NOT decrement on LPUSH failure: under chaos, an await can
        # fail after the bytes reached Redis (response lost on disconnect),
        # so we can't reliably know whether the push actually happened.
        # Treating pushed as ATTEMPTS — not successes — is conservative:
        # pushed never falls below actual pushes, so the invariant
        # "popped > pushed" remains a true bug indicator.
        $integrity->note_queue_pushed;
        my $t0 = time;
        my $ok = eval { await $client->lpush($queue, $job); 1 };
        $metrics->record_latency('lpush', time - $t0) if $ok;
        if ($ok) {
            $metrics->incr_op('lpush');
        } else {
            _record_error($metrics, $@);
        }
        await Future::IO->sleep($period);
    }
    return;
}

async sub run_pubsub_subscriber {
    my %args = @_;
    my $client    = $args{client};
    my $channels  = $args{channels};
    my $metrics   = $args{metrics};
    my $integrity = $args{integrity};
    my $stop      = $args{stop};

    my $sub = await $client->subscribe(@$channels);

    while (!$stop->is_ready) {
        my $msg = eval { await $sub->next };
        # next() returns undef cleanly when the harness disconnects the
        # client; on any other failure, the eval traps and we re-check stop.
        if (!defined $msg) {
            _record_error($metrics, $@) if $@;
            await Future::IO->sleep(0.01);
            next;
        }
        $metrics->incr_op('message_rx');
        # Use the channel from the message envelope rather than parsing
        # it out of the payload — Redis channel names can (and do)
        # contain colons (`stress:bus:0`), so a `[^:]+` extraction
        # would miss most realistic naming schemes.
        my $payload = $msg->{data} // '';
        if ($payload =~ /^seq=(\d+):/) {
            $integrity->note_pubsub_observation($msg->{channel}, $1);
        }
    }
    return;
}

async sub run_pubsub_publisher {
    my %args = @_;
    my $client   = $args{client};
    my $channels = $args{channels};
    my $metrics  = $args{metrics};
    my $stop     = $args{stop};
    my $rate_hz  = $args{rate_hz} // 100;

    my %seq;
    my $period = 1.0 / $rate_hz;
    my $i = 0;

    while (!$stop->is_ready) {
        my $ch = $channels->[ $i++ % scalar @$channels ];
        $seq{$ch}++;
        my $payload = "seq=$seq{$ch}:t=" . time;
        my $t0 = time;
        my $ok = eval { await $client->publish($ch, $payload); 1 };
        $metrics->record_latency('publish', time - $t0) if $ok;
        if ($ok) {
            $metrics->incr_op('publish');
        } else {
            _record_error($metrics, $@);
        }
        await Future::IO->sleep($period);
    }
    return;
}

async sub run_pattern_subscriber {
    my %args = @_;
    my $client    = $args{client};
    my $pattern   = $args{pattern};
    my $metrics   = $args{metrics};
    my $integrity = $args{integrity};
    my $stop      = $args{stop};

    my $sub = await $client->psubscribe($pattern);

    while (!$stop->is_ready) {
        my $msg = eval { await $sub->next };
        # next() returns undef cleanly on disconnect; classify any other
        # trapped failure so it shows up in errors_typed.
        if (!defined $msg) {
            _record_error($metrics, $@) if $@;
            await Future::IO->sleep(0.01);
            next;
        }
        $metrics->incr_op('pattern_rx');
        my $payload = $msg->{data} // '';
        # id is `<pid>_<seq>` — colon-free, so [^:]+ is safe.
        if ($payload =~ /^id=([^:]+)/) {
            $integrity->note_pattern_received($1);
        }
    }
    return;
}

async sub run_pattern_publisher {
    my %args = @_;
    my $client    = $args{client};
    my $prefix    = $args{prefix};
    my $suffixes  = $args{suffixes} // 8;
    my $metrics   = $args{metrics};
    my $integrity = $args{integrity};
    my $stop      = $args{stop};
    my $rate_hz   = $args{rate_hz} // 50;

    my $period = 1.0 / $rate_hz;
    my $msg_id = 0;

    while (!$stop->is_ready) {
        $msg_id++;
        my $suf = int rand $suffixes;
        my $ch = "${prefix}:${suf}";
        my $id_str = "${$}_${msg_id}";
        my $payload = "id=${id_str}:t=" . time;
        my $ok = eval { await $client->publish($ch, $payload); 1 };
        if ($ok) {
            $metrics->incr_op('pattern_publish');
            $integrity->note_pattern_published($id_str);
        } else {
            _record_error($metrics, $@);
        }
        await Future::IO->sleep($period);
    }
    return;
}

1;
