# t/92-concurrency/response-ordering.t
# Tests for concurrent command response ordering
# This test demonstrates the response mismatch bug when multiple async commands
# fire concurrently on a single connection WITHOUT explicit pipelining.

use strict;
use warnings;
use Test2::V0;
use Test::Lib;
use Test::Async::Redis qw(init_loop skip_without_redis await_f cleanup_keys run);
use Async::Redis;
use Future;

my $loop = init_loop();

SKIP: {
    my $redis = skip_without_redis();

    subtest 'concurrent SET commands - response ordering' => sub {
        # Create connection with auto_pipeline disabled to expose the bug
        my $r = Async::Redis->new(
            host         => $ENV{REDIS_HOST} // 'localhost',
            auto_pipeline => 0,
        );
        run { $r->connect };

        # Fire 20 SET commands concurrently (not pipelined)
        my @futures;
        for my $i (1..20) {
            push @futures, $r->set("order:$i", "value:$i");
        }

        # Wait for all to complete
        await_f(Future->needs_all(@futures));

        # Verify each key has the correct value
        # If responses got mismatched, values would be wrong
        for my $i (1..20) {
            my $val = run { $r->get("order:$i") };
            is($val, "value:$i", "key order:$i has correct value");
        }

        run { cleanup_keys($r, 'order:*') };
        $r->disconnect;
    };

    subtest 'concurrent GET commands - response ordering' => sub {
        my $r = Async::Redis->new(
            host         => $ENV{REDIS_HOST} // 'localhost',
            auto_pipeline => 0,
        );
        run { $r->connect };

        # Pre-populate keys
        for my $i (1..20) {
            run { $r->set("getorder:$i", "value:$i") };
        }

        # Fire 20 concurrent GETs
        my @futures;
        my @expected;
        for my $i (1..20) {
            push @futures, $r->get("getorder:$i");
            push @expected, "value:$i";
        }

        # Wait for all
        await_f(Future->needs_all(@futures));

        # Check that each future got the RIGHT response
        for my $i (0..$#futures) {
            my $result = $futures[$i]->get;
            is($result, $expected[$i], "GET " . ($i+1) . " got correct response");
        }

        run { cleanup_keys($r, 'getorder:*') };
        $r->disconnect;
    };

    subtest 'mixed command types - response type matching' => sub {
        my $r = Async::Redis->new(
            host         => $ENV{REDIS_HOST} // 'localhost',
            auto_pipeline => 0,
        );
        run { $r->connect };

        # Fire different command types concurrently
        # SET returns 'OK' (string)
        # INCR returns integer
        # GET returns string or nil
        # LPUSH returns integer (list length)

        my @pairs = (
            [$r->set("mixed:str", "hello"),     'OK',    'SET returns OK'],
            [$r->incr("mixed:counter"),         1,       'INCR returns 1'],
            [$r->set("mixed:str2", "world"),    'OK',    'SET returns OK'],
            [$r->incr("mixed:counter"),         2,       'INCR returns 2'],
            [$r->lpush("mixed:list", "a"),      1,       'LPUSH returns 1'],
            [$r->incr("mixed:counter"),         3,       'INCR returns 3'],
            [$r->lpush("mixed:list", "b", "c"), 3,       'LPUSH returns 3'],
            [$r->get("mixed:str"),              'hello', 'GET returns value'],
        );

        # Extract futures
        my @futures = map { $_->[0] } @pairs;

        # Wait for all
        await_f(Future->needs_all(@futures));

        # Verify each got the correct type/value
        for my $i (0..$#pairs) {
            my ($future, $expected, $desc) = @{$pairs[$i]};
            my $result = $future->get;
            is($result, $expected, $desc);
        }

        run { cleanup_keys($r, 'mixed:*') };
        $r->disconnect;
    };

    subtest 'stress test - 100 concurrent commands' => sub {
        my $r = Async::Redis->new(
            host         => $ENV{REDIS_HOST} // 'localhost',
            auto_pipeline => 0,
        );
        run { $r->connect };

        # Fire 100 SET commands concurrently
        my @futures;
        for my $i (1..100) {
            push @futures, $r->set("stress:$i", "v$i");
        }

        await_f(Future->needs_all(@futures));

        # All should have returned OK
        my $all_ok = 1;
        for my $i (0..$#futures) {
            my $result = $futures[$i]->get;
            if ($result ne 'OK') {
                $all_ok = 0;
                fail("stress SET " . ($i+1) . " returned '$result' instead of 'OK'");
            }
        }
        ok($all_ok, "all 100 SET commands returned OK");

        # Verify all values
        for my $i (1..100) {
            my $val = run { $r->get("stress:$i") };
            is($val, "v$i", "stress key $i has correct value") or last;
        }

        run { cleanup_keys($r, 'stress:*') };
        $r->disconnect;
    };

    subtest 'inflight tracking during concurrent operations' => sub {
        my $r = Async::Redis->new(
            host         => $ENV{REDIS_HOST} // 'localhost',
            auto_pipeline => 0,
        );
        run { $r->connect };

        # Initially no inflight
        is($r->inflight_count, 0, 'no inflight initially');

        # Start commands but don't await yet
        my @futures;
        for my $i (1..5) {
            push @futures, $r->set("inflight:$i", "val$i");
        }

        # Wait for all to complete
        await_f(Future->needs_all(@futures));

        # After completion, inflight should be 0
        is($r->inflight_count, 0, 'no inflight after completion');

        # Verify all results
        for my $i (0..$#futures) {
            is($futures[$i]->get, 'OK', "command " . ($i+1) . " completed with OK");
        }

        run { cleanup_keys($r, 'inflight:*') };
        $r->disconnect;
    };

    $redis->disconnect;
}

done_testing;
