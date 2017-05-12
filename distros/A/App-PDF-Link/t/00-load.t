#! perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::PDF::Link' );
}

diag( "Testing App::PDF::Link $App::PDF::Link::VERSION, Perl $], $^X" );
