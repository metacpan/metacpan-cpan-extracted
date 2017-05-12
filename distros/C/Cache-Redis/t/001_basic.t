use strict;
use utf8;
use Test::More;

use Time::HiRes qw/sleep/;
use Test::RedisServer;
use Cache::Redis;

for my $redis_class (qw/Redis Redis::Fast/) {
    eval "use $redis_class";
    if ($@) {
        diag "$redis_class is not installed. skipping...";
        next;
    }

    my $redis = eval { Test::RedisServer->new }
        or plan skip_all => 'redis-server is required in PATH to run this test';
    my $socket = $redis->conf->{unixsocket};

    my $cache = Cache::Redis->new(
        sock        => $socket,
        redis_class => $redis_class,
    );
    isa_ok $cache, 'Cache::Redis';

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
        $cache->set('hoge', bless({}, 'Blah'));

        my $obj = $cache->get('hoge');
        isa_ok $obj, 'Blah';

        ok $cache->remove('hoge');
        ok !$cache->get('hoge');
    };

    subtest get_or_set => sub {
        my $key = 'kkk';

        ok !$cache->get($key);
        is $cache->get_or_set($key => sub {10}), 10;
        is $cache->get($key), 10;
    };

    subtest expire => sub {
        ok !$cache->get('hoge');
        $cache->set('hoge',  'fuga', 1);
        is $cache->get('hoge'), 'fuga';

        sleep 1.01;
        ok !$cache->get('hoge');
    };
}

done_testing;
