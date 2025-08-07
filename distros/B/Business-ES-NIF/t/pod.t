#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
  plan( skip_all => 'No test POD: set RELEASE_TESTING=1 to run this test' );
}

eval "use Test::Pod 1.52";
plan skip_all => "Test::Pod 1.52 required for testing POD" if $@;

eval "use Test::Pod::Coverage 1.10";
plan skip_all => "Test::Pod::Coverage 1.10 required for testing POD coverage" if $@;

eval "use Pod::Coverage 0.23";
plan skip_all => "Pod::Coverage 0.23 required for testing POD coverage" if $@;

all_pod_coverage_ok();
