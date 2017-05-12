#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Bot::BasicBot::Pluggable::Module::WoWPVP' );
}

diag( "Testing Bot::BasicBot::Pluggable::Module::WoWPVP $Bot::BasicBot::Pluggable::Module::WoWPVP::VERSION, Perl $], $^X" );
