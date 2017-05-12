use strict;
use lib 't/lib';
use libmemcached_test;
use Test::More;

libmemcached_test_create();
plan(tests => 8);

{
    my $cache = libmemcached_test_create();
    isa_ok($cache, "Cache::Memcached::libmemcached");

    ok( ! $cache->is_no_block );

    $cache->set_no_block(1);
    ok( $cache->is_no_block );

    my $value = "non-block via accessor";
    $cache->remove(__FILE__);
    $cache->set(__FILE__, $value);

    is($cache->get(__FILE__), $value);
}

{
    my $cache = libmemcached_test_create({
        no_block => 1,
    } );
    isa_ok($cache, "Cache::Memcached::libmemcached");

    ok( $cache->is_no_block );

    $cache->set_no_block(0);
    ok( !$cache->is_no_block );

    my $value = "non-block via constructor";
    $cache->remove(__FILE__);
    $cache->set(__FILE__, $value);

    is($cache->get(__FILE__), $value);
}

