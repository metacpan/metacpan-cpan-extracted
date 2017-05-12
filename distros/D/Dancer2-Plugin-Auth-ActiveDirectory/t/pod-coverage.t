#!perl -T
use 5.10.0;
use strict;
use warnings;
use Test::More;

unless ( $ENV{POD_COVERAGE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

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

# sry but these comes from Dancer2

plan tests => 1;
my $trustme = { trustme => [qr/^(ClassHooks|PluginKeyword|dancer_app|execute_plugin_hook|hook|keywords|on_plugin_import|plugin_args|plugin_setting|register|register_hook|register_plugin|var)$/] };
pod_coverage_ok( "Dancer2::Plugin::Auth::ActiveDirectory", $trustme );