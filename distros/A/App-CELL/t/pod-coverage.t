#!perl -T
use 5.012;
use strict;
use warnings;
use Test::More;

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

#all_pod_coverage_ok();
pod_coverage_ok( "App::CELL" );
pod_coverage_ok( "App::CELL::Config" );
pod_coverage_ok( "App::CELL::Guide" );
pod_coverage_ok( "App::CELL::Load" );
pod_coverage_ok( "App::CELL::Log" );
pod_coverage_ok( "App::CELL::Message" );
pod_coverage_ok( "App::CELL::Status" );
pod_coverage_ok( "App::CELL::Test" );
#pod_coverage_ok( "App::CELL::Test::LogToFile" );
pod_coverage_ok( "App::CELL::Util" );

done_testing;
