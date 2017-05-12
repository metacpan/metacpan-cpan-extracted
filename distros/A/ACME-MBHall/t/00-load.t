#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'ACME::MBHall' ) || print "Bail out!\n";
}

diag( "Testing ACME::MBHall $ACME::MBHall::VERSION, Perl $], $^X" );
