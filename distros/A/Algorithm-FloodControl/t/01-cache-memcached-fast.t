#! perl
use warnings;
use strict;

our $be = "Algorithm::FloodControl::Backend::Cache::Memcached::Fast";
use Test::More;
BEGIN {
    eval { require Cache::Memcached::Fast };
    if ( $@ ) {
        plan skip_all => 'Cache::Memcached::Fast is required for this test';
    }
    require Algorithm::FloodControl::Backend::Cache::Memcached::Fast;
}
if ( !$ENV{MEMCACHED_SERVER} ) {
    plan skip_all => '$ENV{MEMCACHED_SERVER} is not set';
}
plan tests => 6;

require 't/tlib.pm';

tlib::test_backend( 'Cache::Memcached::Fast', { servers => [ $ENV{MEMCACHED_SERVER} ] } );

