# t/30-pipeline/large.t
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

    my $count = 1000;

    subtest "pipeline with $count commands" => sub {
        my $pipe = $redis->pipeline;

        for my $i (1..$count) {
            $pipe->set("large:$i", "value$i");
        }

        is($pipe->count, $count, "pipeline has $count commands queued");

        my $start = time();
        my $results = run { $pipe->execute };
        my $elapsed = time() - $start;

        is(scalar @$results, $count, "got $count results");
        ok($elapsed < 5, "completed in ${elapsed}s (should be fast)");

        # All should be OK
        my @ok = grep { $_ eq 'OK' } @$results;
        is(scalar @ok, $count, 'all commands returned OK');
    };

    subtest "read back $count keys" => sub {
        my $pipe = $redis->pipeline;

        for my $i (1..$count) {
            $pipe->get("large:$i");
        }

        my $results = run { $pipe->execute };

        is(scalar @$results, $count, "got $count results");
        is($results->[0], 'value1', 'first value correct');
        is($results->[$count-1], "value$count", 'last value correct');
    };

    subtest 'non-blocking during large pipeline' => sub {
        my @futures = map { $redis->set("nb:largepipe:$_", $_) } (1..50);
        my $start = Time::HiRes::time();
        run { Future->needs_all(@futures) };
        my $elapsed = Time::HiRes::time() - $start;

        ok($elapsed < 5, "50 concurrent ops completed in ${elapsed}s");

        run { $redis->del(map { "nb:largepipe:$_" } 1..50) };
    };

    # Cleanup
    subtest 'cleanup' => sub {
        my $pipe = $redis->pipeline;
        for my $i (1..$count) {
            $pipe->del("large:$i");
        }
        run { $pipe->execute };
        pass("cleaned up $count keys");
    };
}

done_testing;
