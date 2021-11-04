#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 5;

BEGIN {
    use_ok( 'Acme::FishFarm' ) || print "Bail out!\n";
    use_ok( 'Acme::FishFarm::Feeder' ) || print "Bail out!\n";
    use_ok( 'Acme::FishFarm::WaterFiltration' ) || print "Bail out!\n";
    use_ok( 'Acme::FishFarm::WaterLevelMaintainer' ) || print "Bail out!\n";
    use_ok( 'Acme::FishFarm::WaterConditionMonitor' ) || print "Bail out!\n";
}

diag( "Testing Acme::FishFarm $Acme::FishFarm::VERSION, Perl $], $^X" );
