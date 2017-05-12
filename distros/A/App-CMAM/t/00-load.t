#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::CMAM' );
}

diag( "Testing App::CMAM $App::CMAM::VERSION, Perl $], $^X" );
