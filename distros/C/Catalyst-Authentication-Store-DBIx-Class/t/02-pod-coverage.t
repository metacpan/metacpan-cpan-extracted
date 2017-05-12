#!perl

use Test::More;

plan skip_all => 'Set TEST_POD to enable pod tests' unless $ENV{TEST_POD};

eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

all_pod_coverage_ok({ coverage_class => 'Pod::Coverage::CountParents' });
