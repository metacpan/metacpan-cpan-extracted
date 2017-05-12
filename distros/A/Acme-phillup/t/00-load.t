#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::phillup' ) || print "Bail out!\n";
}

diag( "Testing Acme::phillup $Acme::phillup::VERSION, Perl $], $^X" );
