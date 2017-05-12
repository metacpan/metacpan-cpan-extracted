use strict;
use warnings;
use utf8;
use Test::More;

eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage is not installed." if $@;

all_pod_coverage_ok();
