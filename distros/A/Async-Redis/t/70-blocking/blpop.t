# t/70-blocking/blpop.t
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Test2::V0;
use Async::Redis;
use Future::AsyncAwait;
use Future::IO;
use Time::HiRes qw(time);

SKIP: {
    my $redis = eval {
        my $r = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost', connect_timeout => 2);
        run { $r->connect };
        $r;
    };
    skip "Redis not available: $@", 1 unless $redis;

    # Cleanup
    run { $redis->del('blpop:queue', 'blpop:queue2', 'blpop:high', 'blpop:low') };

    subtest 'BLPOP returns immediately when data exists' => sub {
        # Push some data first
        run { $redis->rpush('blpop:queue', 'item1', 'item2') };

        my $start = time();
        my $result = run { $redis->blpop('blpop:queue', 5) };
        my $elapsed = time() - $start;

        is($result, ['blpop:queue', 'item1'], 'got first item');
        ok($elapsed < 0.5, "returned immediately (${elapsed}s)");

        # Cleanup
        run { $redis->del('blpop:queue') };
    };

    subtest 'BLPOP waits for data' => sub {
        # Empty the queue
        run { $redis->del('blpop:queue') };

        # Schedule push after 0.3s using a separate connection
        my $pusher = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
        run { $pusher->connect };

        my $push_f = Future::IO->sleep(0.3)->then(async sub {
            await $pusher->rpush('blpop:queue', 'delayed_item');
        });

        my $start = time();
        my $result = run { $redis->blpop('blpop:queue', 5) };
        my $elapsed = time() - $start;

        is($result, ['blpop:queue', 'delayed_item'], 'got delayed item');
        ok($elapsed >= 0.2 && $elapsed < 1.0, "waited for item (${elapsed}s)");

        # Ensure push completed
        run { $push_f };

        # Cleanup
        run { $redis->del('blpop:queue') };
    };

    subtest 'BLPOP returns undef on timeout' => sub {
        run { $redis->del('blpop:empty') };

        my $start = time();
        my $result = run { $redis->blpop('blpop:empty', 1) };
        my $elapsed = time() - $start;

        is($result, undef, 'returned undef on timeout');
        ok($elapsed >= 0.9 && $elapsed < 2.0, "waited ~1s (${elapsed}s)");
    };

    subtest 'BLPOP with multiple queues (priority order)' => sub {
        run { $redis->del('blpop:high', 'blpop:low') };
        run { $redis->rpush('blpop:low', 'low_item') };
        run { $redis->rpush('blpop:high', 'high_item') };

        my $result = run { $redis->blpop('blpop:high', 'blpop:low', 5) };
        is($result, ['blpop:high', 'high_item'], 'got from first queue with data');

        $result = run { $redis->blpop('blpop:high', 'blpop:low', 5) };
        is($result, ['blpop:low', 'low_item'], 'got from second queue');

        # Cleanup
        run { $redis->del('blpop:high', 'blpop:low') };
    };

    subtest 'non-blocking verification (CRITICAL)' => sub {
        my $redis2 = skip_without_redis();
        run { $redis->del('nb:blpop:list') };

        my $push_f = Future::IO->sleep(0.3)->then(async sub {
            await $redis2->rpush('nb:blpop:list', 'delayed');
        });

        my $start = Time::HiRes::time();
        my $result = run { $redis->command('BLPOP', 'nb:blpop:list', 2) };
        my $elapsed = Time::HiRes::time() - $start;

        ok($elapsed < 1.5, "BLPOP resolved via delayed push (${elapsed}s)");
        is($result->[1], 'delayed', 'got the delayed value');

        run { $redis->del('nb:blpop:list') };
    };

    # Cleanup
    run { $redis->del('blpop:queue', 'blpop:queue2') };
}

done_testing;
