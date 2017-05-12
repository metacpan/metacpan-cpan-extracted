use strict;
use warnings;
use Test::More;

eval 'use Test::Pod::Coverage';
plan skip_all => 'Test::Pod::Coverage required' if $@;

all_pod_coverage_ok();
