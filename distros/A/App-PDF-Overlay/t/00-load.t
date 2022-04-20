#!perl -T

use Test::More tests => 4;

BEGIN {
	use_ok( 'App::PDF::Overlay' );
	use_ok( 'PDF::API2', 2.042 );
	use_ok( 'Pod::Find' );
	use_ok( 'Pod::Usage' );
}

diag( "Testing App::PDF::Overlay $App::PDF::Overlay::VERSION, Perl $], $^X" );
