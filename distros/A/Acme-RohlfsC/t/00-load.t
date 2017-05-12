#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::RohlfsC' ) || print "Bail out!\n";
}

diag( "Testing Acme::RohlfsC $Acme::RohlfsC::VERSION, Perl $], $^X" );
