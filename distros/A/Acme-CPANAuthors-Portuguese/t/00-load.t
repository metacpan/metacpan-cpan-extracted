#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::CPANAuthors::Portuguese' );
}

diag( "Testing Acme::CPANAuthors::Portuguese $Acme::CPANAuthors::Portuguese::VERSION, Perl $], $^X" );
