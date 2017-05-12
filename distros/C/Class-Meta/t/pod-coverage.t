#!perl -w

use strict;
use Test::More;
use File::Spec;
eval "use Test::Pod::Coverage 0.08";
plan skip_all => "Test::Pod::Coverage required for testing POD coverage" if $@;

all_pod_coverage_ok();
