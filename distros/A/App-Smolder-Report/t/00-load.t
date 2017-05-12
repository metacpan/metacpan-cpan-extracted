#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::Smolder::Report' );
}

diag( "Testing App::Smolder::Report $App::Smolder::Report::VERSION, Perl $], $^X" );
