#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::VW' );
}

diag( "Testing App::VW $App::VW::VERSION, Perl $], $^X" );
