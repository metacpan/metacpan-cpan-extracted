use strict;
use lib 't/lib';
use libmemcached_test;
use Test::More;

my $cache = libmemcached_test_create();
plan(tests => 7);

isa_ok($cache, "Cache::Memcached::libmemcached");

my @keys = ('a' .. 'z');
foreach my $key (@keys) {
    $cache->set($key, $key);
}

my $h = $cache->get_multi(@keys);
ok($h);
isa_ok($h, 'HASH');

my %expected = map { ($_ => $_) } @keys;
is_deeply( $h, \%expected, "got all the expected values");

$cache->flush_all;
$h = $cache->get_multi(@keys);
ok($h);
isa_ok($h, 'HASH');

is(scalar keys %$h, 0);
