#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
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

# the sneck check needs Monitoring::Sneck::Checks, which is optional, to load at all
my @modules = grep { $_ ne 'Monitoring::Sneck::Checks::supervisorctl' } all_modules();
my $have_sneck = eval { require Monitoring::Sneck::Checks::base; 1 };
plan tests => scalar(@modules) + ( $have_sneck ? 1 : 0 );

foreach my $module (@modules) {
    pod_coverage_ok($module);
}

# option_spec and defaults are documented in Monitoring::Sneck::Checks::base
if ($have_sneck) {
    pod_coverage_ok( 'Monitoring::Sneck::Checks::supervisorctl',
        { also_private => [qr/\A(?:option_spec|defaults|OK|WARNING|CRITICAL|UNKNOWN)\z/] } );
}
