use strict;
use warnings;
use Test::More;

eval "use Test::Pod::Coverage 1.04";
plan skip_all => 'Test::Pod::Coverage 1.04 required' if $@;
eval "use Pod::Coverage::Moose";
plan skip_all => 'Pod::Coverage::Moose required' if $@;
plan skip_all => 'set TEST_POD to enable this test' unless $ENV{TEST_POD};

all_pod_coverage_ok({ coverage_class => 'Pod::Coverage::Moose' });

