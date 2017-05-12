use strict;
use warnings;
use Test::More;
use Data::Dumper;

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

plan tests => 13;

my @modules = all_modules('lib');

# exclude private modules, which call define_api_method or such.

my @exclude = (qw/Amazon::MWS::FulfillmentInventory
                  Amazon::MWS::Routines
                  Amazon::MWS::TypeMap
                  Amazon::MWS::Products
                  Amazon::MWS::InboundShipments
                  Amazon::MWS::Enumeration
                  Amazon::MWS::FulfillmentOutbound
                  Amazon::MWS::Feeds
                  Amazon::MWS::Orders
                  Amazon::MWS::Sellers
                  Amazon::MWS::Exception
                  Amazon::MWS::Reports
                  Amazon::MWS::Enumeration::ReportType
                  Amazon::MWS::Enumeration::FeedProcessingStatus
                  Amazon::MWS::Enumeration::FeedType
                  Amazon::MWS::Enumeration::Schedule
                  Amazon::MWS::Enumeration::ReportProcessingStatus
                 /);

my %exclusions = map { $_ => 1 } @exclude;

foreach my $module (@modules) {
    next if $exclusions{$module};
    # diag "Checking $module POD coverage";
    pod_coverage_ok($module);
}

# all_pod_coverage_ok({ also_private => [qw/BUILDARGS/] });
