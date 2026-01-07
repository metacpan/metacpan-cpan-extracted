# t/30-pipeline/depth-limit.t
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Test2::V0;
use Async::Redis;

SKIP: {
    my $redis = eval {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
            connect_timeout => 2,
            pipeline_depth => 100,  # Low limit for testing
        );
        run { $r->connect };
        $r;
    };
    skip "Redis not available: $@", 1 unless $redis;

    subtest 'pipeline respects depth limit' => sub {
        my $pipe = $redis->pipeline(max_depth => 50);

        # Queue 50 commands (at limit)
        for my $i (1..50) {
            $pipe->set("depth:$i", $i);
        }

        is($pipe->count, 50, '50 commands queued');

        # 51st should fail
        my $error;
        eval {
            $pipe->set("depth:51", 51);
        };
        $error = $@;

        ok($error, 'exceeded depth limit threw error');
        like($error, qr/depth.*limit.*exceeded/i, 'error mentions depth limit');
    };

    subtest 'default depth limit from constructor' => sub {
        # Redis client has pipeline_depth => 100
        my $pipe = $redis->pipeline;

        for my $i (1..100) {
            $pipe->ping;
        }

        my $error;
        eval {
            $pipe->ping;  # 101st should fail
        };
        $error = $@;

        ok($error, 'default depth limit enforced');
    };

    subtest 'pipeline with custom high limit' => sub {
        my $pipe = $redis->pipeline(max_depth => 5000);

        for my $i (1..1000) {
            $pipe->ping;
        }

        is($pipe->count, 1000, '1000 commands queued with custom limit');

        # Execute but don't care about results
        run { $pipe->execute };
        pass('executed 1000 command pipeline');
    };
}

done_testing;
