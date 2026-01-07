#!/usr/bin/env perl
# Test: High throughput pipeline operations
use strict;
use warnings;
use Test2::V0;
use Test::Lib;
use Test::Async::Redis qw(init_loop skip_without_redis await_f cleanup_keys run);
use Time::HiRes qw(time);

my $loop = init_loop();

SKIP: {
    my $redis = skip_without_redis();

    subtest 'pipeline throughput SET' => sub {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $r->connect };

        my $commands = 10_000;

        my $start = time();
        my $pipeline = $r->pipeline;
        for my $i (1..$commands) {
            $pipeline->set("throughput:key:$i", $i);
        }
        my $results = run { $pipeline->execute };
        my $elapsed = time() - $start;

        is(scalar(@$results), $commands, 'all pipeline commands returned');

        my $ops_per_sec = $commands / $elapsed;
        note("$commands pipelined SETs in ${elapsed}s = " . int($ops_per_sec) . " ops/sec");

        ok($ops_per_sec >= 10_000, "pipeline at least 10000 ops/sec (got " . int($ops_per_sec) . ")");

        run { cleanup_keys($r, 'throughput:*') };
        $r->disconnect;
    };

    subtest 'pipeline throughput GET' => sub {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $r->connect };

        # Set up keys first
        my $setup_pipe = $r->pipeline;
        for my $i (1..1000) {
            $setup_pipe->set("pget:$i", "value$i");
        }
        run { $setup_pipe->execute };

        # Now GET them all
        my $commands = 10_000;
        my $start = time();

        my $pipeline = $r->pipeline;
        for my $i (1..$commands) {
            $pipeline->get("pget:" . (($i % 1000) + 1));
        }
        my $results = run { $pipeline->execute };
        my $elapsed = time() - $start;

        is(scalar(@$results), $commands, 'all GETs returned');

        my $ops_per_sec = $commands / $elapsed;
        note("$commands pipelined GETs in ${elapsed}s = " . int($ops_per_sec) . " ops/sec");

        ok($ops_per_sec >= 10_000, "pipeline GET at least 10000 ops/sec");

        run { cleanup_keys($r, 'pget:*') };
        $r->disconnect;
    };

    subtest 'mixed pipeline operations' => sub {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $r->connect };

        my $batches = 100;
        my $ops_per_batch = 100;
        my $total_ops = $batches * $ops_per_batch * 3;  # set + get + incr

        my $start = time();

        for my $batch (1..$batches) {
            my $pipeline = $r->pipeline;
            for my $i (1..$ops_per_batch) {
                my $key = "mix:$batch:$i";
                $pipeline->set($key, $i);
                $pipeline->get($key);
                $pipeline->incr("mix:counter");
            }
            run { $pipeline->execute };
        }

        my $elapsed = time() - $start;
        my $ops_per_sec = $total_ops / $elapsed;

        note("$total_ops mixed ops in ${elapsed}s = " . int($ops_per_sec) . " ops/sec");
        ok($ops_per_sec >= 5000, "mixed pipeline at least 5000 ops/sec");

        my $counter = run { $r->get("mix:counter") };
        is($counter, $batches * $ops_per_batch, "counter correct");

        run { cleanup_keys($r, 'mix:*') };
        $r->disconnect;
    };

    $redis->disconnect;
}

done_testing;
