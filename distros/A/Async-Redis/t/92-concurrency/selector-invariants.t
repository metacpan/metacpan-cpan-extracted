use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use Future::IO;
use Future;
use Scalar::Util qw(blessed);
use Async::Redis;

# Writing to a just-closed socket raises SIGPIPE; tests that exercise
# disconnect-under-load would otherwise die from the signal.
local $SIG{PIPE} = 'IGNORE';

plan skip_all => 'REDIS_HOST not set' unless $ENV{REDIS_HOST};

# Structured-concurrency invariants for the Future::Selector-backed
# task ownership model. Complements reader-unhandled-exception.t and
# existing pubsub/reconnect tests by covering whole-lifecycle
# properties: task failure reaches awaiting callers, disconnect under
# load closes cleanly, reconnect cycles don't leak state.

sub new_redis {
    Async::Redis->new(
        host => $ENV{REDIS_HOST},
        port => $ENV{REDIS_PORT} // 6379,
    );
}

subtest 'task failure reaches awaiting caller (generic structured-concurrency property)' => sub {
    # This is the broader sibling of reader-unhandled-exception.t: any
    # fire-and-forget task failure, not just reader bugs, should reach
    # a concurrent caller that's inside run_until_ready.
    #
    # We drive this by monkey-patching _decode_response_result (same
    # as the reader test) but verify against a COMMAND that doesn't
    # need the reader to respond — a pure write-only submit. The
    # selector propagates the reader task's failure to the command's
    # awaiting future via run_until_ready.

    (async sub {
        my $r = new_redis();
        await $r->connect;

        # Baseline.
        await $r->set('sel_inv_key', 'before');

        # Arm the trap on the next decode.
        my $orig = \&Async::Redis::_decode_response_result;
        my $armed = 1;
        {
            no warnings 'redefine';
            *Async::Redis::_decode_response_result = sub {
                if ($armed) { $armed = 0; die "SELECTOR_INVARIANT_TEST_BUG\n" }
                return $orig->(@_);
            };
        }

        # Issue a read (GET); the reader will try to decode the response,
        # hit the trap, and fail. The selector propagates that failure
        # to our awaiting run_until_ready.
        my $outcome;
        my $done = Future->new;
        my $get_f = $r->get('sel_inv_key');
        $get_f->on_done(sub { $outcome = 'done';   $done->done unless $done->is_ready });
        $get_f->on_fail(sub { $outcome = 'failed'; $done->done unless $done->is_ready });
        my $timeout = Future::IO->sleep(2);
        $timeout->on_done(sub {
            $outcome //= 'hung'; $done->done unless $done->is_ready;
        });

        await $done;

        is $outcome, 'failed', 'awaiting caller saw task failure (not hung, not done)';

        # Restore.
        { no warnings 'redefine'; *Async::Redis::_decode_response_result = $orig; }
        eval { $r->disconnect };
    })->()->get;
};

subtest 'disconnect under load: write-gate waiters unwind cleanly' => sub {
    # Fire many concurrent commands without awaiting individually, so
    # most end up waiting on _acquire_write_lock rather than in the
    # inflight queue. Then disconnect and await them all. Verify:
    #   - every future resolves (no pending futures left)
    #   - only Disconnected / Connection error types appear
    #   - no Timeout, Protocol, or generic die leaking out
    # Uses BLPOP with a 0.1s server-side timeout so commands are slow
    # enough that disconnect actually catches some mid-flight even on
    # fast loopback.

    (async sub {
        my $r = new_redis();
        await $r->connect;

        my @futures;
        for my $i (1..30) {
            push @futures, $r->blpop("load_list_$i", 0.1);
        }
        # Disconnect immediately without yielding — waiters in the gate
        # chain and in the inflight queue all need to unwind.
        $r->disconnect;

        # Await all so the event loop pumps and suspended awaits resolve.
        my $timeout = Future::IO->sleep(5);
        my $all = Future->wait_all(@futures);
        my $race = Future->wait_any($all, $timeout);
        eval { await $race };   # may fail with any of them; we check state below

        my %type_counts;
        my $still_pending = 0;
        for my $f (@futures) {
            if (!$f->is_ready) {
                $still_pending++;
                next;
            }
            if ($f->is_done) {
                $type_counts{done}++;
                next;
            }
            my ($err) = $f->failure;
            my $t = (blessed($err) && $err->can('isa'))
                ? (ref $err)
                : 'string';
            $type_counts{$t}++;
        }

        is $still_pending, 0, 'every future resolved after disconnect+pump';

        # Acceptable terminal states: done (command raced to completion),
        # Async::Redis::Error::Disconnected, Async::Redis::Error::Connection.
        my %allowed = map { $_ => 1 } (
            'done',
            'Async::Redis::Error::Disconnected',
            'Async::Redis::Error::Connection',
        );
        my @unexpected = grep { !$allowed{$_} } keys %type_counts;
        is \@unexpected, [], 'no unexpected error types';
    })->()->get;
};

subtest 'reconnect cycles do not leak state' => sub {
    (async sub {
        my $sub_redis = Async::Redis->new(
            host            => $ENV{REDIS_HOST},
            port            => $ENV{REDIS_PORT} // 6379,
            reconnect       => 1,
            reconnect_delay => 0.05,
        );
        my $pub = new_redis();
        await $sub_redis->connect;
        await $pub->connect;

        my $ch = 'selector_leak_' . $$;
        my $sub = await $sub_redis->subscribe($ch);

        # Cycle through N reconnects by repeatedly killing the socket.
        my $CYCLES = 3;
        for my $cycle (1 .. $CYCLES) {
            # Publish + receive one message to confirm the subscription
            # is live in this cycle.
            my $published = (async sub {
                await Future::IO->sleep(0.05);
                await $pub->publish($ch, "cycle-$cycle");
            })->();

            my $m_f = $sub->next;
            my $timeout = Future::IO->sleep(2);
            my $got_msg;
            my $done = Future->new;
            $m_f->on_done(sub {
                $got_msg = $_[0];
                $done->done unless $done->is_ready;
            });
            $m_f->on_fail(sub {
                $done->done unless $done->is_ready;
            });
            $timeout->on_done(sub {
                $done->done unless $done->is_ready;
            });
            await $done;
            eval { await $published };

            ok $got_msg && $got_msg->{data} eq "cycle-$cycle",
                "cycle $cycle: received expected message";

            # Force a disconnect to trigger reconnect. Use CLIENT KILL
            # from the publisher so the server closes the subscriber's
            # connection — kernel delivers EOF cleanly through Future::IO's
            # poller. Closing the client socket locally would leave a stale
            # poller with undef fileno in the select loop.
            my $sub_sock = $sub_redis->{socket};
            my $sub_addr = $sub_sock->sockhost . ':' . $sub_sock->sockport;
            eval { await $pub->client('KILL', 'ADDR', $sub_addr) };
            # Give reconnect a moment to kick off.
            await Future::IO->sleep(0.3);
        }

        # After N cycles, the subscription should still be tracking the
        # channel and not be closed.
        is [$sub->channels], [$ch],
            "still tracking channel after $CYCLES reconnect cycles";
        ok !$sub->is_closed, 'subscription not closed after reconnect cycles';

        eval { $pub->disconnect };
        eval { $sub_redis->disconnect };
    })->()->get;
};

done_testing;
