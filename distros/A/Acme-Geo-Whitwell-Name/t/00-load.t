#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::Geo::Whitwell::Name' );
}

diag( "Testing Acme::Geo::Whitwell::Name $Acme::Geo::Whitwell::Name::VERSION, Perl $], $^X" );
