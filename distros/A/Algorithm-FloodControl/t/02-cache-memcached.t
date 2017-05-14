#! perl
use warnings;
use strict;
use Test::More;

BEGIN {
    eval { require Cache::Memcached };
    if ( $@ ) {
        plan skip_all => 'Cache::Memcached is required for this test';
    }
    require Algorithm::FloodControl::Backend::Cache::Memcached;
}
our $be = "Algorithm::FloodControl::Backend::Cache::Memcached";
if (! $ENV{ MEMCACHED_SERVER } ) {
    plan skip_all => '$ENV{ MEMCACHED_SERVER } is not set';
}
plan tests => 6;
require 't/tlib.pm';
$tlib::skip_concurrency = $tlib::skip_concurrency = 1;
tlib::test_backend( 'Cache::Memcached', { servers => [ $ENV{MEMCACHED_SERVER} ], debug => 0 })
