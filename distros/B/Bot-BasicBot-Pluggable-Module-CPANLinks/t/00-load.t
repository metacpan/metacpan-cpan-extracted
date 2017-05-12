#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Bot::BasicBot::Pluggable::Module::CPANLinks' ) || print "Bail out!
";
}

diag( "Testing Bot::BasicBot::Pluggable::Module::CPANLinks $Bot::BasicBot::Pluggable::Module::CPANLinks::VERSION, Perl $], $^X" );
