#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::SweeperBot' );
}

diag( "Testing App::SweeperBot $App::SweeperBot::VERSION, Perl $], $^X" );
