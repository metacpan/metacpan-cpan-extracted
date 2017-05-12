#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::CPANAuthors::Chinese' );
}

diag( "Testing Acme::CPANAuthors::Chinese $Acme::CPANAuthors::Chinese::VERSION, Perl $], $^X" );
