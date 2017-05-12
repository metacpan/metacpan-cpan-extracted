#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::MTINBERG' ) || print "Bail out!\n";
}

diag( "Testing Acme::MTINBERG $Acme::MTINBERG::VERSION, Perl $], $^X" );
