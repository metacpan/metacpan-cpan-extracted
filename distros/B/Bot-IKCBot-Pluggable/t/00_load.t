#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Bot::IKCBot::Pluggable' );
}

diag( "Testing Bot::IKCBot::Pluggable $Bot::IKCBot::Pluggable::VERSION, Perl $], $^X" );
