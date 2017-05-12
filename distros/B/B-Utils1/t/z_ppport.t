#!perl
use strict;
use warnings;
use Test::More;

#plan skip_all => "Require a version of Test::PPPort that takes arguments to ppport_ok";
plan skip_all => 'This test is only run for the module author'
    unless -d '.git' || $ENV{IS_MAINTAINER};

if ( eval "use Test::PPPort; 1" ) {
    ppport_ok( '--compat-version=5.006' );
}
else {
    plan( skip_all => "Test::PPPort with ppport_ok required for testing ppport.h" );
}
