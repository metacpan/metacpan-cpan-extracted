use strict;
use lib 't/lib';
use libmemcached_test;
use Test::More;

libmemcached_test_create();
plan(tests => 8);

{
    my $cache = libmemcached_test_create();
    isa_ok($cache, "Cache::Memcached::libmemcached");

    is( $cache->get_distribution_method,
        Memcached::libmemcached::MEMCACHED_DISTRIBUTION_MODULA );

    $cache->set_distribution_method(Memcached::libmemcached::MEMCACHED_DISTRIBUTION_CONSISTENT);
    is( $cache->get_distribution_method,
        Memcached::libmemcached::MEMCACHED_DISTRIBUTION_CONSISTENT );

    my $value = "non-block via accessor";
    $cache->remove(__FILE__);
    $cache->set(__FILE__, $value);

    is($cache->get(__FILE__), $value);
}

{
    my $cache = libmemcached_test_create( {
        distribution_method => Memcached::libmemcached::MEMCACHED_DISTRIBUTION_CONSISTENT(),
    } );
    isa_ok($cache, "Cache::Memcached::libmemcached");

    is( $cache->get_distribution_method,
        Memcached::libmemcached::MEMCACHED_DISTRIBUTION_CONSISTENT );

    $cache->set_distribution_method(Memcached::libmemcached::MEMCACHED_DISTRIBUTION_MODULA);
    is( $cache->get_distribution_method,
        Memcached::libmemcached::MEMCACHED_DISTRIBUTION_MODULA );

    my $value = "non-block via constructor";
    $cache->remove(__FILE__);
    $cache->set(__FILE__, $value);

    is($cache->get(__FILE__), $value);
}

