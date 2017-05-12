#!perl -T

use strict;
use Test::More tests => 1;

BEGIN {
	use_ok( 'Bot::BasicBot::Pluggable::Module::Eliza' );
}

diag( "Testing Bot::BasicBot::Pluggable::Module::Eliza $Bot::BasicBot::Pluggable::Module::Eliza::VERSION, Perl $], $^X" );
