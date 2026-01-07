# t/92-concurrency/parallel-commands.t
# Tests for pipelined/concurrent operations
use strict;
use warnings;
use Test2::V0;
use Test::Lib;
use Test::Async::Redis qw(init_loop skip_without_redis await_f cleanup_keys run);

my $loop = init_loop();

SKIP: {
    my $redis = skip_without_redis();

    subtest 'pipelined SET commands' => sub {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $r->connect };

        # Use pipeline for many SET commands
        my $pipe = $r->pipeline;
        for my $i (1..20) {
            $pipe->set("pset:$i", "value$i");
        }

        my $results = run { $pipe->execute };
        is(scalar @$results, 20, 'all SET commands completed');

        # Verify all returned OK
        my @oks = grep { $_ eq 'OK' } @$results;
        is(scalar @oks, 20, 'all SETs returned OK');

        # Verify values were set correctly (sequential GETs)
        for my $i (1..20) {
            my $val = run { $r->get("pset:$i") };
            is($val, "value$i", "key $i correct");
        }

        run { cleanup_keys($r, 'pset:*') };
        $r->disconnect;
    };

    subtest 'pipelined GET commands' => sub {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $r->connect };

        # Set up some keys (sequential)
        for my $i (1..10) {
            run { $r->set("pget:$i", "val$i") };
        }

        # Use pipeline for parallel GETs
        my $pipe = $r->pipeline;
        for my $i (1..10) {
            $pipe->get("pget:$i");
        }

        my $results = run { $pipe->execute };

        is(scalar @$results, 10, 'all GETs completed');

        # Verify results are in order
        for my $i (0..9) {
            is($results->[$i], "val" . ($i + 1), "value " . ($i + 1) . " correct");
        }

        run { cleanup_keys($r, 'pget:*') };
        $r->disconnect;
    };

    subtest 'mixed pipeline operations' => sub {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $r->connect };

        # Use pipeline for mixed commands
        my $pipe = $r->pipeline;
        $pipe->set('pmix:key', 'value');
        $pipe->incr('pmix:counter');
        $pipe->lpush('pmix:list', 'item1', 'item2');
        $pipe->sadd('pmix:set', 'member1', 'member2');

        my $results = run { $pipe->execute };
        is(scalar @$results, 4, 'all commands completed');

        is($results->[0], 'OK', 'SET returned OK');
        is($results->[1], 1, 'INCR returned 1');
        is($results->[2], 2, 'LPUSH returned 2');
        is($results->[3], 2, 'SADD returned 2');

        run { cleanup_keys($r, 'pmix:*') };
        $r->disconnect;
    };

    subtest 'sequential commands work correctly' => sub {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $r->connect };

        # Sequential commands should work
        for my $i (1..5) {
            my $result = run { $r->set("seq:$i", "val$i") };
            is($result, 'OK', "SET $i succeeded");
        }

        for my $i (1..5) {
            my $result = run { $r->get("seq:$i") };
            is($result, "val$i", "GET $i correct");
        }

        run { cleanup_keys($r, 'seq:*') };
        $r->disconnect;
    };

    $redis->disconnect;
}

done_testing;
