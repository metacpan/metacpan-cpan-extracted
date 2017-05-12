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

pod_coverage_ok( 'Cisco::UCS' );
pod_coverage_ok( 'Cisco::UCS::Blade',	 		{ also_private => [ 'new' ] } );
pod_coverage_ok( 'Cisco::UCS::Blade::CPU',		{ also_private => [ 'new' ] } );
pod_coverage_ok( 'Cisco::UCS::Blade::PowerBudget',	{ also_private => [ 'new' ] } );
pod_coverage_ok( 'Cisco::UCS::Chassis',	 		{ also_private => [ 'new' ] } );
pod_coverage_ok( 'Cisco::UCS::Chassis::Stats',		{ also_private => [ 'new' ] } );
pod_coverage_ok( 'Cisco::UCS::Fault', 			{ also_private => [ 'new' ] } );
pod_coverage_ok( 'Cisco::UCS::FEX',	 		{ also_private => [ 'new' ] } );
pod_coverage_ok( 'Cisco::UCS::Interconnect', 		{ also_private => [ 'new' ] } );
pod_coverage_ok( 'Cisco::UCS::Interconnect::Stats',	{ also_private => [ 'new' ] } );
pod_coverage_ok( 'Cisco::UCS::MgmtEntity', 		{ also_private => [ 'new' ] } );
pod_coverage_ok( 'Cisco::UCS::ServiceProfile', 		{ also_private => [ 'new' ] } );
pod_coverage_ok( 'Cisco::UCS::Common::EthernetPort', 	{ also_private => [ 'new' ] } );
pod_coverage_ok( 'Cisco::UCS::Common::EnvironmentalStats', 	{ also_private => [ 'new' ] } );
pod_coverage_ok( 'Cisco::UCS::Common::Fan', 		{ also_private => [ 'new' ] } );
pod_coverage_ok( 'Cisco::UCS::Common::FanModule', 	{ also_private => [ 'new' ] } );
pod_coverage_ok( 'Cisco::UCS::Common::PowerStats',	{ also_private => [ 'new' ] } );
pod_coverage_ok( 'Cisco::UCS::Common::PSU', 		{ also_private => [ 'new' ] } );
pod_coverage_ok( 'Cisco::UCS::Common::SwitchCard', 	{ also_private => [ 'new' ] } );
done_testing();
