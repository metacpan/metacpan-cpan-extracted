use strict;
use utf8;
use Test::More;
use Test::Requires 'Data::MessagePack';

use Test::RedisServer;
use Cache::Redis;

my $redis = eval { Test::RedisServer->new }
    or plan skip_all => 'redis-server is required in PATH to run this test';
my $socket = $redis->conf->{unixsocket};

my $cache = Cache::Redis->new(
    sock       => $socket,
    serializer => 'MessagePack',
);
isa_ok $cache, 'Cache::Redis';

subtest serialize => sub {
    my $org = 'hoge';
    my $packed   = Cache::Redis::_mp_serialize($org);
    my $unpacked = Cache::Redis::_mp_deserialize($packed);
    is $unpacked, $org;
};

subtest basic => sub {
    ok !$cache->get('hoge');
    $cache->set('hoge',  'fuga');
    is $cache->get('hoge'), 'fuga';

    ok $cache->remove('hoge');
    ok !$cache->get('hoge');
};

subtest multi_byte => sub {
    ok !$cache->get('hoge');
    $cache->set('hoge',  'あ');
    is $cache->get('hoge'), 'あ';

    ok $cache->remove('hoge');
    ok !$cache->get('hoge');
};

subtest object => sub {
    ok !$cache->get('hoge');
    $cache->set('hoge', {data => 'あ'});
    is_deeply $cache->get('hoge'), {data => 'あ'};

    ok $cache->remove('hoge');
    ok !$cache->get('hoge');
};

subtest blessed => sub {
    local $@;
    my $obj = bless {}, 'Blah';
    eval {
        $cache->set('hoge', $obj);
    };
    ok $@;
};

subtest get_or_set => sub {
    my $key = 'kkk';

    ok !$cache->get($key);
    is $cache->get_or_set($key => sub {10}), 10;
    is $cache->get($key), 10;
};

done_testing;
