use strict;
use lib 't/lib';
use libmemcached_test;
use Test::More;

my $cache = libmemcached_test_create( {
    namespace => join('_', 'Cache::Memcached::libmemcached', 'test', rand(), $$)
} );

plan(tests => 5);

isa_ok($cache, "Cache::Memcached::libmemcached");

{
    my $key = 'foo';

    {
        $cache->set($key, 0);
        is( $cache->get($key), 0, "value is 0 initially");
    }

    {
        my $rv = $cache->incr($key);
        is( $rv, 1, "return value is $rv");
    }

    {
        my $rv = $cache->incr($key);
        is( $rv, 2, "return value is $rv");
    }

    {
        my $rv = $cache->decr($key);
        is( $rv, 1, "return value is $rv");
    }
}
