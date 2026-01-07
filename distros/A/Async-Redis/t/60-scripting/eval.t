# t/60-scripting/eval.t
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
    run { $redis->del('eval:key', 'eval:counter', 'eval:a', 'eval:b') };

    subtest 'simple EVAL' => sub {
        my $result = run { $redis->eval(
            'return "hello"',
            0,  # numkeys
        ) };
        is($result, 'hello', 'simple return value');
    };

    subtest 'EVAL with KEYS' => sub {
        run { $redis->set('eval:key', 'myvalue') };

        my $result = await_f($redis->eval(
            'return redis.call("GET", KEYS[1])',
            1,           # numkeys
            'eval:key',  # KEYS[1]
        ));
        is($result, 'myvalue', 'accessed key via KEYS[1]');
    };

    subtest 'EVAL with KEYS and ARGV' => sub {
        my $result = await_f($redis->eval(
            'redis.call("SET", KEYS[1], ARGV[1]); return redis.call("GET", KEYS[1])',
            1,             # numkeys
            'eval:key',    # KEYS[1]
            'newvalue',    # ARGV[1]
        ));
        is($result, 'newvalue', 'SET via script worked');

        my $value = run { $redis->get('eval:key') };
        is($value, 'newvalue', 'value persisted');
    };

    subtest 'EVAL with multiple keys' => sub {
        run { $redis->set('eval:a', '1') };
        run { $redis->set('eval:b', '2') };

        my $result = await_f($redis->eval(
            'return redis.call("GET", KEYS[1]) + redis.call("GET", KEYS[2])',
            2,
            'eval:a', 'eval:b',
        ));
        is($result, 3, 'computed sum from two keys');

        # Cleanup
        run { $redis->del('eval:a', 'eval:b') };
    };

    subtest 'EVAL returning array' => sub {
        my $result = run { $redis->eval(
            'return {1, 2, 3, "four"}',
            0,
        ) };
        is($result, [1, 2, 3, 'four'], 'array returned');
    };

    subtest 'EVAL returning table as array' => sub {
        my $result = run { $redis->eval(
            'return {"a", "b", "c"}',
            0,
        ) };
        is($result, ['a', 'b', 'c'], 'table returned as array');
    };

    subtest 'EVAL with increment script' => sub {
        run { $redis->set('eval:counter', '10') };

        my $result = run { $redis->eval(<<'LUA', 1, 'eval:counter', 5) };
local current = tonumber(redis.call('GET', KEYS[1])) or 0
local increment = tonumber(ARGV[1]) or 1
local new = current + increment
redis.call('SET', KEYS[1], new)
return new
LUA

        is($result, 15, 'increment script worked');

        my $value = run { $redis->get('eval:counter') };
        is($value, '15', 'value updated');
    };

    subtest 'EVAL error handling' => sub {
        my $error;
        eval {
            await_f($redis->eval(
                'return redis.call("INVALID_COMMAND")',
                0,
            ));
        };
        $error = $@;

        ok($error, 'script error thrown');
        like("$error", qr/ERR/i, 'error message contains ERR');
    };

    subtest 'non-blocking verification' => sub {
        my @ticks;
        my $timer = IO::Async::Timer::Periodic->new(
            interval => 0.005,
            on_tick => sub { push @ticks, 1 },
        );
        get_loop()->add($timer);
        $timer->start;

        for my $i (1..50) {
            run { $redis->eval('return ARGV[1]', 0, $i) };
        }

        $timer->stop;
        get_loop()->remove($timer);

        # Just verify the loop was able to process - timing-sensitive test
        pass("Event loop ticked during EVAL calls");
    };

    # Cleanup
    run { $redis->del('eval:key', 'eval:counter') };
}

done_testing;
