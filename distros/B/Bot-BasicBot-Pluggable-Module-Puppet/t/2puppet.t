use Test::More tests => 3;

use_ok('Test::Bot::BasicBot::Pluggable');

my $bot = new Test::Bot::BasicBot::Pluggable;

isa_ok($bot, 'Bot::BasicBot::Pluggable', 'basic bot');
ok($bot->load('Puppet'), 'load Puppet module');

