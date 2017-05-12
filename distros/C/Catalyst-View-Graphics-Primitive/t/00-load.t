#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::View::Graphics::Primitive' );
}

diag( "Testing Catalyst::View::Graphics::Primitive $Catalyst::View::Graphics::Primitive::VERSION, Perl $], $^X" );
