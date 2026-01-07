#!/usr/bin/env perl

use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Test2::V0;

use lib 'lib';
use Async::Redis;

# Test helper provides: run {}, skip_without_redis
# :redis tag auto-skips if Redis unavailable
# run {} awaits any Future returned from the block

my $redis = skip_without_redis();

subtest 'PING' => sub {
    my $pong = run { $redis->ping };
    is $pong, 'PONG', 'PING returns PONG';
};

subtest 'SET and GET' => sub {
    run { $redis->set('test:key', 'hello') };
    my $value = run { $redis->get('test:key') };

    is $value, 'hello', 'GET returns SET value';

    # Cleanup
    run { $redis->del('test:key') };
};

subtest 'SET with expiry' => sub {
    run { $redis->set('test:expiry', 'temp', ex => 10) };
    my $value = run { $redis->get('test:expiry') };

    is $value, 'temp', 'GET returns value before expiry';

    run { $redis->del('test:expiry') };
};

subtest 'INCR' => sub {
    run { $redis->set('test:counter', 0) };
    my $v1 = run { $redis->incr('test:counter') };
    my $v2 = run { $redis->incr('test:counter') };
    my $v3 = run { $redis->incr('test:counter') };

    is $v1, 1, 'first INCR returns 1';
    is $v2, 2, 'second INCR returns 2';
    is $v3, 3, 'third INCR returns 3';

    run { $redis->del('test:counter') };
};

subtest 'list operations' => sub {
    run { $redis->del('test:list') };
    run { $redis->rpush('test:list', 'a', 'b', 'c') };

    my $list = run { $redis->lrange('test:list', 0, -1) };
    is $list, ['a', 'b', 'c'], 'LRANGE returns all elements';

    my $popped = run { $redis->lpop('test:list') };
    is $popped, 'a', 'LPOP returns first element';

    run { $redis->del('test:list') };
};

subtest 'NULL handling' => sub {
    my $value = run { $redis->get('nonexistent:key:12345') };
    is $value, undef, 'GET nonexistent key returns undef';
};

subtest 'disconnect' => sub {
    $redis->disconnect;
    ok !$redis->{connected}, 'disconnected';
};

done_testing;
