#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::ctreptow' ) || print "Bail out!\n";
}

diag( "Testing Acme::ctreptow $Acme::ctreptow::VERSION, Perl $], $^X" );
