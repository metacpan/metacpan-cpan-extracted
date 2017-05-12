#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Bot::BasicBot::Pluggable::Module::XKCD' ) || print "Bail out!
";
}

diag( "Testing Bot::BasicBot::Pluggable::Module::XKCD $Bot::BasicBot::Pluggable::Module::XKCD::VERSION, Perl $], $^X" );
