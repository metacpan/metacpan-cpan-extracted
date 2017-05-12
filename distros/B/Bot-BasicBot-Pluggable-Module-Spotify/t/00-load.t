#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Bot::BasicBot::Pluggable::Module::Spotify' );
}

diag( "Testing Bot::BasicBot::Pluggable::Module::Spotify $Bot::BasicBot::Pluggable::Module::Spotify::VERSION, Perl $], $^X" );
