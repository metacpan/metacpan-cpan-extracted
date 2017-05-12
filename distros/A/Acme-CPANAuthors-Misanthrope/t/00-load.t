#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::CPANAuthors::Misanthrope' );
}

diag( "Testing Acme::CPANAuthors::Misanthrope $Acme::CPANAuthors::Misanthrope::VERSION, Perl $], $^X" );
