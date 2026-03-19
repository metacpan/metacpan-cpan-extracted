# t/70-blocking/brpop.t
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
    run { $redis->del('brpop:queue') };

    subtest 'BRPOP returns from right side' => sub {
        run { $redis->rpush('brpop:queue', 'first', 'second', 'third') };

        my $result = run { $redis->brpop('brpop:queue', 5) };
        is($result, ['brpop:queue', 'third'], 'got rightmost item');

        $result = run { $redis->brpop('brpop:queue', 5) };
        is($result, ['brpop:queue', 'second'], 'got next rightmost');

        # Cleanup
        run { $redis->del('brpop:queue') };
    };

    subtest 'BRPOP waits for data' => sub {
        run { $redis->del('brpop:queue') };

        # Schedule push after 0.3s
        my $pusher = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
        run { $pusher->connect };

        my $push_f = Future::IO->sleep(0.3)->then(async sub {
            await $pusher->lpush('brpop:queue', 'delayed');
        });

        my $start = time();
        my $result = run { $redis->brpop('brpop:queue', 5) };
        my $elapsed = time() - $start;

        is($result, ['brpop:queue', 'delayed'], 'got delayed item');
        ok($elapsed >= 0.2 && $elapsed < 1.0, "waited for item (${elapsed}s)");

        # Ensure push completed
        run { $push_f };
    };

    subtest 'BRPOP returns undef on timeout' => sub {
        run { $redis->del('brpop:empty') };

        my $start = time();
        my $result = run { $redis->brpop('brpop:empty', 1) };
        my $elapsed = time() - $start;

        is($result, undef, 'returned undef on timeout');
        ok($elapsed >= 0.9 && $elapsed < 2.0, "waited ~1s (${elapsed}s)");
    };

    subtest 'non-blocking verification (CRITICAL)' => sub {
        my $redis2 = skip_without_redis();
        run { $redis->del('nb:brpop:list') };

        my $push_f = Future::IO->sleep(0.3)->then(async sub {
            await $redis2->rpush('nb:brpop:list', 'delayed');
        });

        my $start = Time::HiRes::time();
        my $result = run { $redis->command('BRPOP', 'nb:brpop:list', 2) };
        my $elapsed = Time::HiRes::time() - $start;

        ok($elapsed < 1.5, "BRPOP resolved via delayed push (${elapsed}s)");
        is($result->[1], 'delayed', 'got the delayed value');

        run { $redis->del('nb:brpop:list') };
    };

    # Cleanup
    run { $redis->del('brpop:queue') };
}

done_testing;
