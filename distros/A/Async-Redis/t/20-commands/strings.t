# t/20-commands/strings.t
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

    # Cleanup test keys
    run { $redis->del('test:str1', 'test:str2', 'test:counter') };

    subtest 'GET and SET' => sub {
        my $result = run { $redis->set('test:str1', 'hello') };
        is($result, 'OK', 'SET returns OK');

        my $value = run { $redis->get('test:str1') };
        is($value, 'hello', 'GET returns value');
    };

    subtest 'SET with options' => sub {
        my $result = run { $redis->set('test:str2', 'world', ex => 60) };
        is($result, 'OK', 'SET with EX returns OK');

        my $ttl = run { $redis->ttl('test:str2') };
        ok($ttl > 0 && $ttl <= 60, 'TTL set correctly');
    };

    subtest 'INCR and DECR' => sub {
        run { $redis->set('test:counter', '10') };

        my $result = run { $redis->incr('test:counter') };
        is($result, 11, 'INCR returns new value');

        $result = run { $redis->decr('test:counter') };
        is($result, 10, 'DECR returns new value');

        $result = run { $redis->incrby('test:counter', 5) };
        is($result, 15, 'INCRBY returns new value');
    };

    subtest 'APPEND and STRLEN' => sub {
        run { $redis->set('test:str1', 'hello') };

        my $len = run { $redis->append('test:str1', ' world') };
        is($len, 11, 'APPEND returns new length');

        my $value = run { $redis->get('test:str1') };
        is($value, 'hello world', 'APPEND concatenated correctly');

        $len = run { $redis->strlen('test:str1') };
        is($len, 11, 'STRLEN returns length');
    };

    subtest 'non-blocking verification' => sub {
        my @ticks;
        my $timer = IO::Async::Timer::Periodic->new(
            interval => 0.01,
            on_tick => sub { push @ticks, 1 },
        );
        get_loop()->add($timer);
        $timer->start;

        # Run 100 SET/GET pairs
        for my $i (1..100) {
            run { $redis->set("test:nb:$i", "value$i") };
            run { $redis->get("test:nb:$i") };
        }

        $timer->stop;
        get_loop()->remove($timer);

        ok(@ticks >= 5, "Event loop ticked " . scalar(@ticks) . " times during 200 commands");

        # Cleanup
        run { $redis->del(map { "test:nb:$_" } 1..100) };
    };

    # Cleanup
    run { $redis->del('test:str1', 'test:str2', 'test:counter') };
}

done_testing;
