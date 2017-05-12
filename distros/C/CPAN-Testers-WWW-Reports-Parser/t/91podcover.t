#!/usr/bin/perl -w
use strict;

use Test::More;

# Skip if doing a regular install
plan skip_all => "Author tests not required for installation"
    unless( $ENV{AUTOMATED_TESTING} );

my $fail = 0;
eval "use JSON::XS";
$fail++ if($@);
eval "use YAML::XS";
$fail++ if($@);

plan skip_all => "Need JSON::XS & YAML::XS installed to run Pod::Coverage tests"
    if( $fail );

eval "use Test::Pod::Coverage 0.08";
plan skip_all => "Test::Pod::Coverage 0.08 required for testing POD coverage" if $@;
all_pod_coverage_ok();
