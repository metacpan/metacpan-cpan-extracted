#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::TAINT' ) || print "Bail out!\n";
}

diag( "Testing Acme::TAINT $Acme::TAINT::VERSION, Perl $], $^X" );
