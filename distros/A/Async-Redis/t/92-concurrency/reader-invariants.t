use strict;
use warnings;
use lib 't/lib';
use Test2::V0;
use Future::AsyncAwait;
use Future::IO;
use Async::Redis;
use Test::Async::Redis qw(inject_eof force_read_timeout);

# Prevent SIGPIPE from killing the process when fault-injection tests close
# the underlying socket while a write is in flight. Writes fail with EPIPE
# instead, which propagates through the error handling path cleanly.
$SIG{PIPE} = 'IGNORE';

plan skip_all => 'REDIS_HOST not set' unless $ENV{REDIS_HOST};

sub new_redis {
    Async::Redis->new(
        host => $ENV{REDIS_HOST},
        port => $ENV{REDIS_PORT} // 6379,
    );
}

subtest 'single normal command round-trips' => sub {
    (async sub {
        my $r = new_redis();
        await $r->connect;
        my $pong = await $r->command('PING');
        is $pong, 'PONG';
        $r->disconnect;
    })->()->get;
};

subtest 'two concurrent normal commands both succeed and match responses' => sub {
    (async sub {
        my $r = new_redis();
        await $r->connect;
        await $r->set('k1', 'v1');
        await $r->set('k2', 'v2');

        my $f1 = $r->get('k1');
        my $f2 = $r->get('k2');
        my ($v1, $v2) = await Future->needs_all($f1, $f2);

        is $v1, 'v1', 'first command got its response';
        is $v2, 'v2', 'second command got its response';

        await $r->del('k1', 'k2');
        $r->disconnect;
    })->()->get;
};

subtest 'reader exits cleanly when inflight drains, restarts on next submission' => sub {
    (async sub {
        my $r = new_redis();
        await $r->connect;
        await $r->set('k', '1');
        await $r->get('k');
        # If the reader doesn't exit, the next command's ensure_reader
        # would no-op and the command would hang. A second command
        # after a quiet period proves the reader restarts cleanly.
        await Future::IO->sleep(0.05);
        my $v = await $r->get('k');
        is $v, '1';
        await $r->del('k');
        $r->disconnect;
    })->()->get;
};

# Local helper: true if an arrayref contains at least one Async::Redis::Error.
sub _array_has_error {
    my ($results) = @_;
    return 0 unless ref($results) eq 'ARRAY';
    for my $r (@$results) {
        return 1 if ref($r) && eval { $r->isa('Async::Redis::Error') };
    }
    return 0;
}

subtest 'synthetic EOF mid-pipeline fails all pipeline entries with typed error' => sub {
    (async sub {
        my $r = new_redis();
        await $r->connect;

        # Schedule the pipeline but do NOT await yet — inject EOF
        # synchronously before yielding to the event loop so the reader
        # sees a closed socket before any response arrives.
        my $pipe_f = $r->_execute_pipeline([
            ['SET', 'eof-k1', '1'],
            ['SET', 'eof-k2', '2'],
            ['GET', 'eof-k1'],
        ]);
        inject_eof($r);

        my $ok = eval { await $pipe_f; 1 };
        ok !$ok || _array_has_error(($pipe_f->is_done ? [$pipe_f->get] : [])),
            'pipeline ended with failure or inline error objects';
        is $r->{connected}, 0, 'connection marked disconnected';
    })->()->get;
};

subtest 'typed-error preservation on synthetic timeout' => sub {
    (async sub {
        my $r = new_redis();
        await $r->connect;

        # BLPOP on a list that has no elements blocks on the server side,
        # giving us a clean window: write completes, server waits, then we
        # inject the synthetic timeout and verify the typed error propagates.
        my $blpop_f = $r->command('BLPOP', 'test-timeout-injection-list', 30);

        # Yield briefly so the write goes out and the reader is waiting.
        await Future::IO->sleep(0.02);
        force_read_timeout($r);

        my $ok = eval { await $blpop_f; 1 };
        ok !$ok, 'blpop failed';
        my $err = $@;
        isa_ok $err, ['Async::Redis::Error::Timeout'];
    })->()->get;
};

subtest 'fuzz: randomized mix of ops, every future resolves or fails' => sub {
    (async sub {
        my $r = new_redis();
        await $r->connect;

        my @ops;
        for my $i (1..30) {
            my $choice = int(rand(3));
            if ($choice == 0) {
                push @ops, $r->set("fuzz-$i", "v$i");
            } elsif ($choice == 1) {
                push @ops, $r->get("fuzz-$i");
            } else {
                push @ops, $r->_execute_pipeline([
                    ['SET', "fuzz-p$i", "pv$i"],
                    ['GET', "fuzz-p$i"],
                ]);
            }
        }

        for my $f (@ops) {
            eval { await $f };
            ok $f->is_ready, "future resolved (is_ready)";
        }

        # Clean up all keys
        await $r->command('DEL', map { ("fuzz-$_", "fuzz-p$_") } 1..30);
        $r->disconnect;
    })->()->get;
};

done_testing;
