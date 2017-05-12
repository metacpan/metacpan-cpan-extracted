#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Bot::BasicBot::Pluggable::Module::Shutdown' ) || print "Bail out!\n";
}

diag( "Testing Bot::BasicBot::Pluggable::Module::Shutdown $Bot::BasicBot::Pluggable::Module::Shutdown::VERSION, Perl $], $^X" );
