#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::KJAM' ) || print "Bail out!\n";
}

diag( "Testing Acme::KJAM $Acme::KJAM::VERSION, Perl $], $^X" );
