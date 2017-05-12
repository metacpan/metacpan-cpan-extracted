use strict;
use lib 't/lib';
use libmemcached_test;
use Test::More;

my $cache = libmemcached_test_create({ min_version => '1.2.4' });

plan tests => 1;

$cache->set("foo", "abc");
$cache->append("foo", "0123");
is($cache->get("foo"), "abc0123");
