use strict;
use lib 't/lib';
use libmemcached_test;
use Test::More;

my $cache = libmemcached_test_create();

plan(tests => 9);

isa_ok($cache, "Cache::Memcached::libmemcached");

{
    my @keys = ('a' .. 'z');
    foreach my $key (@keys) {
        $cache->set($key, $key);
    }

    my $h = $cache->get_multi(@keys);
    ok($h);
    isa_ok($h, 'HASH');

    my %expected = map { ($_ => $_) } @keys;
    is_deeply( $h, \%expected, "got all the expected values");
}

{
    my $key = 'complex-get_multi';
    my %data = (foo => [ qw(1 2 3) ]);

    $cache->set($key, \%data);

    my $h = $cache->get_multi($key);

    is_deeply($h->{$key}, \%data);
}

{
    my $cache2 = libmemcached_test_create( {
        namespace => "t$$"
    } );
    isa_ok($cache, "Cache::Memcached::libmemcached");
    
    my @keys = ('A' .. 'Z');
    foreach my $key (@keys) {
        $cache2->set($key, $key);
    }

    my $h = $cache2->get_multi(@keys);
    ok($h);
    isa_ok($h, 'HASH');

    my %expected = map { ($_ => $_) } @keys;
    is_deeply( $h, \%expected, "got all the expected values");
}
