package CHI::Driver::Memcached::t::CHIDriverTests::libmemcached;
$CHI::Driver::Memcached::t::CHIDriverTests::libmemcached::VERSION = '0.16';
use Test::More;
use strict;
use warnings;
use base qw(CHI::Driver::Memcached::t::CHIDriverTests::Base);

sub testing_driver_class { 'CHI::Driver::Memcached::libmemcached' }
sub test_driver_class { 'CHI::Driver::Memcached::Test::Driver::libmemcached' }
sub memcached_class   { 'Cache::Memcached::libmemcached' }

sub right_memcached_loaded : Test(shutdown => 2) {
    ok(
        exists( $INC{'Cache/Memcached/libmemcached.pm'} ),
        "Cache::Memcached::libmemcached loaded"
    );
    ok( !exists( $INC{'Cache/Memcached.pm'} ), "Cache::Memcached not loaded" );
}

1;
