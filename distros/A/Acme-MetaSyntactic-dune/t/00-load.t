#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::MetaSyntactic::dune' ) || print "Bail out!\n";
}

diag( "Testing Acme::MetaSyntactic::dune $Acme::MetaSyntactic::dune::VERSION, Perl $], $^X" );
