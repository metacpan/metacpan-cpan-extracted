#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::CPANAuthors::Catalonian' );
}

diag( "Testing Acme::CPANAuthors::Catalonian $Acme::CPANAuthors::Catalonian::VERSION, Perl $], $^X" );
