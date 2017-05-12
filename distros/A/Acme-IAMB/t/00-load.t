#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::IAMB' ) || print "Bail out!\n";
}

diag( "Testing Acme::IAMB $Acme::IAMB::VERSION, Perl $], $^X" );
