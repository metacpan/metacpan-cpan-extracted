#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::WallisdsFirstModule' ) || print "Bail out!\n";
}

diag( "Testing Acme::WallisdsFirstModule $Acme::WallisdsFirstModule::VERSION, Perl $], $^X" );
