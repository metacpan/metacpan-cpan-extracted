#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::CPANAuthors::Spanish' );
}

diag( "Testing Acme::CPANAuthors::Spanish $Acme::CPANAuthors::Spanish::VERSION, Perl $], $^X" );
