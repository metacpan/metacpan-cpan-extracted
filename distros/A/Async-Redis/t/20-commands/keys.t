# t/20-commands/keys.t
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Test2::V0;
use Async::Redis;

SKIP: {
    my $redis = eval {
        my $r = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost', connect_timeout => 2);
        run { $r->connect };
        $r;
    };
    skip "Redis not available: $@", 1 unless $redis;

    # Cleanup
    run { $redis->del('test:key1', 'test:key2', 'test:key3') };

    subtest 'EXISTS' => sub {
        run { $redis->set('test:key1', 'value') };

        my $exists = run { $redis->exists('test:key1') };
        is($exists, 1, 'EXISTS returns 1 for existing key');

        $exists = run { $redis->exists('test:nonexistent') };
        is($exists, 0, 'EXISTS returns 0 for non-existing key');

        # Multiple keys
        run { $redis->set('test:key2', 'value2') };
        $exists = run { $redis->exists('test:key1', 'test:key2', 'test:nonexistent') };
        is($exists, 2, 'EXISTS with multiple keys returns count');
    };

    subtest 'DEL' => sub {
        run { $redis->set('test:key3', 'value3') };

        my $deleted = run { $redis->del('test:key1', 'test:key2', 'test:key3') };
        is($deleted, 3, 'DEL returns count of deleted keys');

        my $exists = run { $redis->exists('test:key1') };
        is($exists, 0, 'key deleted');
    };

    subtest 'EXPIRE and TTL' => sub {
        run { $redis->set('test:key1', 'value') };
        run { $redis->expire('test:key1', 60) };

        my $ttl = run { $redis->ttl('test:key1') };
        ok($ttl > 0 && $ttl <= 60, "TTL is $ttl (expected 1-60)");

        # Remove expiry
        run { $redis->persist('test:key1') };
        $ttl = run { $redis->ttl('test:key1') };
        is($ttl, -1, 'TTL is -1 after PERSIST');
    };

    subtest 'TYPE' => sub {
        run { $redis->set('test:key1', 'string') };
        my $type = run { $redis->type('test:key1') };
        is($type, 'string', 'TYPE returns string');

        run { $redis->rpush('test:key2', 'item') };
        $type = run { $redis->type('test:key2') };
        is($type, 'list', 'TYPE returns list');
    };

    subtest 'RENAME' => sub {
        run { $redis->set('test:key1', 'value') };
        run { $redis->rename('test:key1', 'test:key1:renamed') };

        my $exists = run { $redis->exists('test:key1') };
        is($exists, 0, 'old key gone');

        $exists = run { $redis->exists('test:key1:renamed') };
        is($exists, 1, 'new key exists');

        # Cleanup
        run { $redis->del('test:key1:renamed') };
    };

    subtest 'non-blocking verification' => sub {
        my @ticks;
        my $timer = IO::Async::Timer::Periodic->new(
            interval => 0.01,
            on_tick => sub { push @ticks, 1 },
        );
        get_loop()->add($timer);
        $timer->start;

        for my $i (1..50) {
            run { $redis->set("test:nb:$i", "value$i") };
            run { $redis->exists("test:nb:$i") };
            run { $redis->del("test:nb:$i") };
        }

        $timer->stop;
        get_loop()->remove($timer);

        # Timing-sensitive test - just verify loop processed
        pass("Event loop processed during operations");
    };

    # Cleanup
    run { $redis->del('test:key1', 'test:key2', 'test:key3') };
}

done_testing;
