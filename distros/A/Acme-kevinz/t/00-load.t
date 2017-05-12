#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::kevinz' ) || print "Bail out!\n";
}

diag( "Testing Acme::kevinz $Acme::kevinz::VERSION, Perl $], $^X" );
