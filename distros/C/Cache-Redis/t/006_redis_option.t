use strict;
use utf8;
use Test::More;

use Test::RedisServer;
use Cache::Redis;
use Redis;

my $redis = eval { Test::RedisServer->new }
    or plan skip_all => 'redis-server is required in PATH to run this test';

my $socket = $redis->conf->{unixsocket};

subtest 'redis' => sub {
    my $r = Redis->new( sock => $socket );
    my $cache = Cache::Redis->new( redis => $r );
    ok ! $r->exists('foo');
    $cache->set('foo', 'bar');
    ok $r->exists('foo');
};

subtest 'redis_class' => sub {
    my $cache = Cache::Redis->new( sock => $socket );
    is $cache->get('foo'), 'bar';
};

done_testing;
