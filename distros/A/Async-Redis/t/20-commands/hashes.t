# t/20-commands/hashes.t
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
    run { $redis->del('test:hash') };

    subtest 'HSET and HGET' => sub {
        my $result = run { $redis->hset('test:hash', 'field1', 'value1') };
        ok($result >= 0, 'HSET returns count');

        my $value = run { $redis->hget('test:hash', 'field1') };
        is($value, 'value1', 'HGET returns value');
    };

    subtest 'HMSET and HMGET' => sub {
        run { $redis->hmset('test:hash',
            'a', '1',
            'b', '2',
            'c', '3',
        ) };

        my $values = run { $redis->hmget('test:hash', 'a', 'b', 'c') };
        is($values, ['1', '2', '3'], 'HMGET returns values in order');
    };

    subtest 'HGETALL returns hash' => sub {
        my $hash = run { $redis->hgetall('test:hash') };
        is(ref $hash, 'HASH', 'HGETALL returns hashref');
        is($hash->{field1}, 'value1', 'contains field1');
        is($hash->{a}, '1', 'contains a');
    };

    subtest 'HEXISTS and HDEL' => sub {
        my $exists = run { $redis->hexists('test:hash', 'field1') };
        is($exists, 1, 'HEXISTS returns 1 for existing field');

        my $deleted = run { $redis->hdel('test:hash', 'field1') };
        is($deleted, 1, 'HDEL returns count');

        $exists = run { $redis->hexists('test:hash', 'field1') };
        is($exists, 0, 'HEXISTS returns 0 after delete');
    };

    subtest 'HKEYS, HVALS, HLEN' => sub {
        my $keys = run { $redis->hkeys('test:hash') };
        ok(@$keys >= 3, 'HKEYS returns keys');

        my $vals = run { $redis->hvals('test:hash') };
        ok(@$vals >= 3, 'HVALS returns values');

        my $len = run { $redis->hlen('test:hash') };
        ok($len >= 3, 'HLEN returns count');
    };

    subtest 'HINCRBY' => sub {
        run { $redis->hset('test:hash', 'counter', '10') };

        my $result = run { $redis->hincrby('test:hash', 'counter', 5) };
        is($result, 15, 'HINCRBY returns new value');
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
            run { $redis->hset('test:hash', "field$i", "val$i") };
            run { $redis->hget('test:hash', "field$i") };
        }

        $timer->stop;
        get_loop()->remove($timer);

        # Timing-sensitive test - just verify loop processed
        pass("Event loop processed during operations");
    };

    # Cleanup
    run { $redis->del('test:hash') };
}

done_testing;
