use strict;
use warnings;
use Test::More tests => 11;
use App::Bot::BasicBot::Pluggable;

## Testing defaults

# We need to specify configfile here explicitly in case the user
# has already written a configuration file that would be found by
# Config::Find, unlikely but oh my...
our @ARGV = ( '--configfile', 't/configfiles/empty.yaml' );

my $app = App::Bot::BasicBot::Pluggable->new_with_options();

is( $app->server,   'localhost', 'checking default for server' );
is( $app->port,     6667,        'checking default for port' );
is( $app->nick,     'basicbot',  'checking default for basicbot' );
is( $app->charset,  'utf8',      'checking default for charset' );
is( $app->loglevel, 'warn',      'checking default for loglevel' );
ok( !$app->list_modules, 'checking default for list_modules' );
ok( !$app->list_stores,  'checking default for list_stores' );
is_deeply( $app->settings, {}, 'checking default for settings' );
is_deeply( $app->module, [ 'Auth', 'Loader' ], 'checking default for modules' );
is_deeply( $app->channel, [], 'checking default for channel' );
isa_ok(
    $app->store,
    'Bot::BasicBot::Pluggable::Store::Memory',
    'default store'
);
