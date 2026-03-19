# t/30-pipeline/basic.t
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Test2::V0;
use Async::Redis;
use Time::HiRes qw(time);
use Future;

SKIP: {
    my $redis = eval {
        my $r = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost', connect_timeout => 2);
        run { $r->connect };
        $r;
    };
    skip "Redis not available: $@", 1 unless $redis;

    # Cleanup
    run { $redis->del('pipe:key1', 'pipe:key2', 'pipe:counter') };

    subtest 'basic pipeline execution' => sub {
        my $pipe = $redis->pipeline;
        ok($pipe, 'pipeline created');

        $pipe->set('pipe:key1', 'value1');
        $pipe->set('pipe:key2', 'value2');
        $pipe->get('pipe:key1');
        $pipe->incr('pipe:counter');

        my $results = run { $pipe->execute };

        is(ref $results, 'ARRAY', 'results is array');
        is(scalar @$results, 4, 'four results');
        is($results->[0], 'OK', 'SET 1 returned OK');
        is($results->[1], 'OK', 'SET 2 returned OK');
        is($results->[2], 'value1', 'GET returned value');
        is($results->[3], 1, 'INCR returned 1');
    };

    subtest 'pipeline is faster than individual commands' => sub {
        # Warm up
        run { $redis->set('pipe:warmup', 'value') };

        # Individual commands
        my $start = time();
        for my $i (1..100) {
            run { $redis->set("pipe:ind:$i", $i) };
        }
        my $individual_time = time() - $start;

        # Pipeline
        $start = time();
        my $pipe = $redis->pipeline;
        for my $i (1..100) {
            $pipe->set("pipe:batch:$i", $i);
        }
        run { $pipe->execute };
        my $pipeline_time = time() - $start;

        ok($pipeline_time < $individual_time,
            "Pipeline (${pipeline_time}s) faster than individual (${individual_time}s)");

        # Cleanup
        await_f($redis->del(map { ("pipe:ind:$_", "pipe:batch:$_") } 1..100));
    };

    subtest 'empty pipeline returns empty array' => sub {
        my $pipe = $redis->pipeline;
        my $results = run { $pipe->execute };

        is($results, [], 'empty pipeline returns []');
    };

    subtest 'pipeline is single-use' => sub {
        my $pipe = $redis->pipeline;
        $pipe->ping;

        my $results = run { $pipe->execute };
        is($results->[0], 'PONG', 'first execute works');

        # Second execute should fail or return empty
        my $results2 = eval { run { $pipe->execute } };
        ok(!$results2 || @$results2 == 0 || $@,
            'second execute fails or returns empty');
    };

    subtest 'non-blocking verification' => sub {
        my @futures = map { $redis->set("nb:pipe:$_", $_) } (1..50);
        my $start = Time::HiRes::time();
        run { Future->needs_all(@futures) };
        my $elapsed = Time::HiRes::time() - $start;

        ok($elapsed < 5, "50 concurrent ops completed in ${elapsed}s");

        run { $redis->del(map { "nb:pipe:$_" } 1..50) };
    };

    # Cleanup
    run { $redis->del('pipe:key1', 'pipe:key2', 'pipe:counter') };
}

done_testing;
