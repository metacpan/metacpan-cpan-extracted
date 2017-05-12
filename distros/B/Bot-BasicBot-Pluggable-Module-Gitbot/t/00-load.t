#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Bot::BasicBot::Pluggable::Module::Gitbot' );
}

diag( "Testing Bot::BasicBot::Pluggable::Module::Gitbot $Bot::BasicBot::Pluggable::Module::Gitbot::VERSION, Perl $], $^X" );
