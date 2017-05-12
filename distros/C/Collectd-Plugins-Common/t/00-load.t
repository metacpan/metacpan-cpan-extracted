#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Collectd::Plugins::Common' ) || print "Bail out!\n";
}

diag( "Testing Collectd::Plugins::Common $Collectd::Plugins::Common::VERSION, Perl $], $^X" );
