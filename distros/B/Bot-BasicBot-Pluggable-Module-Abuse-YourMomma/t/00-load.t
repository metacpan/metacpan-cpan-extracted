#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Bot::BasicBot::Pluggable::Module::Abuse::YourMomma' ) || print "Bail out!
";
}

diag( "Testing Bot::BasicBot::Pluggable::Module::Abuse::YourMomma $Bot::BasicBot::Pluggable::Module::Abuse::YourMomma::VERSION, Perl $], $^X" );
