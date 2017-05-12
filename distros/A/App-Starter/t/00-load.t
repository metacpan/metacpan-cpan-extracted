#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::Starter' );
}

diag( "Testing App::Starter $App::Starter::VERSION, Perl $], $^X" );
