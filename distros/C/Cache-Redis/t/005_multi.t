use strict;
use utf8;
use Test::More;

use Time::HiRes qw/sleep/;
use Test::RedisServer;
use Cache::Redis;

# test case taken from Cache::Memcached::Fast

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

    subtest 'basic' => sub {
        my $keys_count = 100;
        my @keys = map { "commands-$_" } ( 1 .. $keys_count );

        {
            my $res = $cache->get_multi(@keys);
            isa_ok $res, 'HASH';
            is keys %$res, 0;
        }

        {
            $cache->set_multi( map { [$_ => $_] } @keys );
            my $res = $cache->get_multi(@keys);
            is keys %$res, $keys_count;
        }

        {

            my @extra_keys = @keys;
            for (1..$keys_count) {
                splice(@extra_keys, int(rand(@extra_keys + 1)), 0, "no_such_key-$_");
            }
            my $res = $cache->get_multi(@keys);
            is keys %$res, $keys_count;
        }
    };

    subtest 'get_multi with not exist key' => sub {
        $cache->set_multi([ 'foo', 1], [ 'bar', 2 ]);
        is_deeply $cache->get_multi(qw(foo bar)), { foo => 1, bar => 2 };
        $cache->remove('foo');
        is_deeply $cache->get_multi(qw(foo bar)), { bar => 2 };
    };

    subtest object => sub {
        $cache->set_multi([ 'hoge', { data => 'あ' } ]);
        is_deeply $cache->get_multi('hoge'), { hoge => { data => 'あ' } };
    };
}

done_testing;

