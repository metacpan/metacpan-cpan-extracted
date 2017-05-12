#!perl -I../lib

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::CPANAuthors::Acme::CPANAuthors::Authors' );
}

diag( "Testing Acme::CPANAuthors::Acme::CPANAuthors::Authors $Acme::CPANAuthors::Acme::CPANAuthors::Authors::VERSION, Perl $], $^X" );
