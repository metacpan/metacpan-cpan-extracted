#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

my $VERSION = '0.03';

BEGIN {
    use_ok( 'Android::ElectricSheep::Automator::ADB::Device' ) || print "Bail out!\n";
    use_ok( 'Android::ElectricSheep::Automator::ADB' ) || print "Bail out!\n";
    use_ok( 'Android::ElectricSheep::Automator::XMLParsers' ) || print "Bail out!\n";
    use_ok( 'Android::ElectricSheep::Automator::ScreenLayout' ) || print "Bail out!\n";
    use_ok( 'Android::ElectricSheep::Automator::DeviceProperties' ) || print "Bail out!\n";
    use_ok( 'Android::ElectricSheep::Automator::AppProperties' ) || print "Bail out!\n";
    use_ok( 'Android::ElectricSheep::Automator' ) || print "Bail out!\n";
    # our own plugins
    use_ok( 'Android::ElectricSheep::Automator::Plugins::Base' ) || print "Bail out!\n";
    use_ok( 'Android::ElectricSheep::Automator::Plugins::Viber' ) || print "Bail out!\n";
}

diag( "Testing Android::ElectricSheep::Automator $Android::ElectricSheep::Automator::VERSION, Perl $], $^X" );

done_testing;
