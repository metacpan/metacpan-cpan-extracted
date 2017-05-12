#!/usr/bin/perl
# $Id: pod_coverage.t 1895 2006-09-16 08:14:06Z comdog $

use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;
all_pod_coverage_ok();  