#!perl

use strict;
use warnings;

use Test::More;


# Load Test::Pod::Coverage.
my $min_tpc_version = '1.08';
eval "use Test::Pod::Coverage $min_tpc_version";
plan( skip_all => "Test::Pod::Coverage $min_tpc_version required for testing POD coverage." )
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc_version = '0.18';
eval "use Pod::Coverage $min_pc_version";
plan skip_all => "Pod::Coverage $min_pc_version required for testing POD coverage."
    if $@;

# Test POD coverage.
all_pod_coverage_ok();
