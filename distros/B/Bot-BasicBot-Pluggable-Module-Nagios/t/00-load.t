#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Bot::BasicBot::Pluggable::Module::Nagios' ) || print "Bail out!
";
}

diag( "Testing Bot::BasicBot::Pluggable::Module::Nagios $Bot::BasicBot::Pluggable::Module::Nagios::VERSION, Perl $], $^X" );
