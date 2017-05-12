#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Cisco::IronPort' ) || print "Bail out!\n";
}

diag( "Testing Cisco::IronPort $Cisco::IronPort::VERSION, Perl $], $^X" );
