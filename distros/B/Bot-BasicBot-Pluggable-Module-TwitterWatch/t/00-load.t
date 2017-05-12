#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Bot::BasicBot::Pluggable::Module::TwitterWatch' ) || print "Bail out!
";
}

diag( "Testing Bot::BasicBot::Pluggable::Module::TwitterWatch $Bot::BasicBot::Pluggable::Module::TwitterWatch::VERSION, Perl $], $^X" );
