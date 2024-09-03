#!perl -T
use strict;
use warnings;
use Test::More;

plan skip_all => "DBIx::Fast No test POD" unless $ENV{'DBIX_FAST_TEST'};

eval "use Test::Pod 1.52";
plan skip_all => "Test::Pod 1.52 required for testing POD" if $@;

eval "use Test::Pod::Coverage 1.10";
plan skip_all => "Test::Pod::Coverage 1.10 required for testing POD coverage" if $@;

eval "use Pod::Coverage 0.23";
plan skip_all => "Pod::Coverage 0.23 required for testing POD coverage" if $@;

all_pod_coverage_ok();
