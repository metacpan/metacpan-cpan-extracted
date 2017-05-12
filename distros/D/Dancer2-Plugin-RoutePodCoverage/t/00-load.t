use strict;
use warnings;
use Test::More tests => 2;
use Test::NoWarnings;
BEGIN {
    use_ok( 'Dancer2::Plugin::RoutePodCoverage' ) || print "Bail out!";
}
diag( "Testing Dancer2::Plugin::RoutePodCoverage $Dancer2::Plugin::RoutePodCoverage::VERSION, Perl $], $^X" );
