#!perl -T

# Just make sure they compile, at least.

use Test::More tests => 3;

BEGIN {
    use_ok( 'Bot::BasicBot::Pluggable::Module::GitHub');;
    use_ok( 'Bot::BasicBot::Pluggable::Module::GitHub::EasyLinks');
    use_ok( 'Bot::BasicBot::Pluggable::Module::GitHub::PullRequests');

}

diag( "Testing Bot::BasicBot::Pluggable::Module::GitHub $Bot::BasicBot::Pluggable::Module::GitHub::VERSION, Perl $], $^X" );
