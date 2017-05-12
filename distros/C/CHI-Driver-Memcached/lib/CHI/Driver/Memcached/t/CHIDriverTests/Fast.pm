package CHI::Driver::Memcached::t::CHIDriverTests::Fast;
$CHI::Driver::Memcached::t::CHIDriverTests::Fast::VERSION = '0.16';
use Test::More;
use strict;
use warnings;
use base qw(CHI::Driver::Memcached::t::CHIDriverTests::Base);

sub testing_driver_class { 'CHI::Driver::Memcached::Fast' }
sub test_driver_class    { 'CHI::Driver::Memcached::Test::Driver::Fast' }
sub memcached_class      { 'Cache::Memcached::Fast' }

sub right_memcached_loaded : Test(shutdown => 2) {
    ok( exists( $INC{'Cache/Memcached/Fast.pm'} ),
        "Cache::Memcached::Fast loaded" );
    ok( !exists( $INC{'Cache/Memcached.pm'} ), "Cache::Memcached not loaded" );
}

1;
