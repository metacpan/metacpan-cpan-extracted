#!perl -T

use Test::More tests => 5;

BEGIN {
	use_ok( 'Chess::GameClock::GameClock' );
	use_ok( 'Chess::GameClock::GclkCounter' );
	use_ok( 'Chess::GameClock::GclkData' );
	use_ok( 'Chess::GameClock::GclkDisplay' );
	use_ok( 'Chess::GameClock::GclkSettings' );
}

diag( "Testing Chess::GameClock::GameClock $Chess::GameClock::GameClock::VERSION, Perl $], $^X" );
