#!perl
use strict;
use warnings;
use Test::More;

plan( skip_all => "Require a version of Test::PPPort that takes arguments to ppport_ok" );
#if ( eval "use Test::PPPort; 1" ) {
#    ppport_ok( '--compat-version=5.006' );
#}
#else {
#    plan( skip_all => "Test::PPPort required for testing ppport.h" );
#}
