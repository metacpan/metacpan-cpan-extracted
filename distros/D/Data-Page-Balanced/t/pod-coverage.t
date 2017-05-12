#!perl -T
# $Id: pod-coverage.t 2 2007-10-27 22:08:58Z kim $

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
all_pod_coverage_ok();
