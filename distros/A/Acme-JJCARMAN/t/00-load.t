#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::JJCARMAN' ) || print "Bail out!\n";
}

diag( "Testing Acme::JJCARMAN $Acme::JJCARMAN::VERSION, Perl $], $^X" );
