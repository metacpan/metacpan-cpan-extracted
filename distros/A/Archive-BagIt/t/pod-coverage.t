use strict;
use warnings;
use Test::More;

plan skip_all => "These tests are for authors only!" unless  $ENV{AUTHOR_TESTING} or $ENV{RELEASE_TESTING};
# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;
plan tests => 2;
pod_coverage_ok("Archive::BagIt", { also_private =>[ qw( BUILD BUILDARGS has_forced_fixity_algorithm) ]});
pod_coverage_ok("Archive::BagIt::Base");
