use strict;
use lib 't/lib';
use libmemcached_test;
use Test::More;

my $cache = libmemcached_test_create();

plan(tests => 6);

isa_ok($cache, "Cache::Memcached::libmemcached");

{
    $cache->set("foo", "bar");
    my $val = $cache->get("foo");
    is($val, "bar", "simple value");

    # add() shouldn't update
    $cache->add("foo", "baz");
    is( $cache->get("foo"), "bar", "simple value shouldn't have changed via add()");

    # replace() should update
    $cache->replace("foo", "baz");
    is( $cache->get("foo"), "baz", "simple value should have changed via replace()");

    $cache->delete("foo");

    # add() should update
    $cache->add("foo", "bar", 300);
    is( $cache->get("foo"), "bar", "simple value should have changed via add()");

    $cache->delete("foo");

    # replace() shouldn't update
    $cache->replace("foo", "baz");
    is( $cache->get("foo"), undef, "keys that don't exist on the server shouldn't have changed via replace()");
}