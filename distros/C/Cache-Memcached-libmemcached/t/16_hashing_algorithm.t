use strict;
use lib 't/lib';
use libmemcached_test;
use Test::More;

libmemcached_test_create();
plan(tests => 8);

{
    my $cache = libmemcached_test_create();
    isa_ok($cache, "Cache::Memcached::libmemcached");

    is( $cache->get_hashing_algorithm,
        Memcached::libmemcached::MEMCACHED_HASH_DEFAULT );

    $cache->set_hashing_algorithm(Memcached::libmemcached::MEMCACHED_HASH_MD5);
    is( $cache->get_hashing_algorithm,
        Memcached::libmemcached::MEMCACHED_HASH_MD5 );

    my $value = "non-block via accessor";
    $cache->remove(__FILE__);
    $cache->set(__FILE__, $value);

    is($cache->get(__FILE__), $value);
}

{
    my $cache = libmemcached_test_create( {
        hashing_algorithm => Memcached::libmemcached::MEMCACHED_HASH_MD5(),
    } );
    isa_ok($cache, "Cache::Memcached::libmemcached");

    is( $cache->get_hashing_algorithm,
        Memcached::libmemcached::MEMCACHED_HASH_MD5 );

    $cache->set_hashing_algorithm(Memcached::libmemcached::MEMCACHED_HASH_DEFAULT);
    is( $cache->get_hashing_algorithm,
        Memcached::libmemcached::MEMCACHED_HASH_DEFAULT );

    my $value = "non-block via constructor";
    $cache->remove(__FILE__);
    $cache->set(__FILE__, $value);

    is($cache->get(__FILE__), $value);
}

