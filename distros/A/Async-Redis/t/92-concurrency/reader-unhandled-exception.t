use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use Future::IO;
use Future;
use Scalar::Util qw(blessed);
use Async::Redis;

plan skip_all => 'REDIS_HOST not set' unless $ENV{REDIS_HOST};

# Regression guard for the structured-concurrency contract: if the reader
# task dies with an unhandled exception (a coding bug that bypasses
# _run_reader's explicit _reader_fatal paths), the failure MUST propagate
# to awaiting callers.
#
# Before the selector adoption: the reader Future failed, _ensure_reader's
# on_ready cleared _reader_future silently, inflight response futures were
# never failed, and await $response hung forever with connected=1.
#
# After: the reader task is owned by $self->{_tasks} (Future::Selector).
# _execute_command awaits responses via $tasks->run_until_ready, which
# propagates any in-scope task failure to the caller. A reader crash
# becomes a caller-visible typed error.

subtest 'reader unhandled exception propagates to awaiting caller' => sub {
    (async sub {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST},
            port => $ENV{REDIS_PORT} // 6379,
        );
        await $r->connect;

        # Baseline: ensure normal command flow works before the trap.
        await $r->set('reader_exc_test', 'before');

        # Monkey-patch _decode_response_result to die unhandled on its next
        # call. Simulates an arbitrary coding bug in the reader's frame
        # processing that escapes _reader_fatal routing.
        my $orig  = \&Async::Redis::_decode_response_result;
        my $armed = 1;
        {
            no warnings 'redefine';
            *Async::Redis::_decode_response_result = sub {
                if ($armed) {
                    $armed = 0;
                    die "INJECTED_READER_BUG\n";
                }
                return $orig->(@_);
            };
        }

        # Issue a command. The reader will try to decode its response,
        # hit the injected die, and the reader task in the selector will
        # fail. run_until_ready inside _execute_command propagates that
        # failure to the awaiting caller.
        my $set_f = $r->set('reader_exc_test', 'after');

        # Callback-based outcome capture (avoid rethrow via await).
        my $outcome = 'unknown';
        my $captured_err;
        my $done = Future->new;

        $set_f->on_done(sub {
            $outcome = 'COMPLETED';
            $done->done unless $done->is_ready;
        });
        $set_f->on_fail(sub {
            $outcome = 'FAILED';
            $captured_err = $_[0];
            $done->done unless $done->is_ready;
        });

        # Hung-detection: 2 second ceiling.
        my $timeout = Future::IO->sleep(2);
        $timeout->on_done(sub {
            if ($outcome eq 'unknown') {
                $outcome = 'HUNG';
                $done->done unless $done->is_ready;
            }
        });

        await $done;

        is $outcome, 'FAILED', 'reader bug surfaced to awaiting caller (not HUNG)';
        ok defined $captured_err, 'caller received an error';

        # Restore and clean up.
        {
            no warnings 'redefine';
            *Async::Redis::_decode_response_result = $orig;
        }
        eval { $r->disconnect };
    })->()->get;
};

done_testing;
