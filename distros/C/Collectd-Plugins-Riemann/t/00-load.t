#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Collectd::Plugins::Riemann' ) || print "Bail out!\n";
}

diag( "Testing Collectd::Plugins::Riemann $Collectd::Plugins::Riemann::VERSION, Perl $], $^X" );
