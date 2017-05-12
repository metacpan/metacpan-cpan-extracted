#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Bot::BasicBot::Pluggable::Module::Log' );
}

diag( "Testing Bot::BasicBot::Pluggable::Module::Log $Bot::BasicBot::Pluggable::Module::Log::VERSION, Perl $], $^X" );
