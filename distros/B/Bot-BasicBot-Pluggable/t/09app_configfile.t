use strict;
use warnings;
use Test::More tests => 9;
use App::Bot::BasicBot::Pluggable;

our @ARGV = (
    qw(
      --configfile t/configfiles/bot-basicbot-pluggable.yaml
      )
);

my $app = App::Bot::BasicBot::Pluggable->new_with_options();

is( $app->server,   'irc.example.com', 'setting server via configfile' );
is( $app->loglevel, 'fatal',           'setting loglevel via configfile' );
is( $app->port,     6668,              'setting port via configfile' );
is( $app->nick,     'botbot',          'setting basicbot via configfile' );
is( $app->charset,  'ascii',           'setting charset via configfile' );
isa_ok(
    $app->store,
    'Bot::BasicBot::Pluggable::Store::Memory',
    'store via configfile'
);

is_deeply(
    $app->module,
    [ 'Loader', 'Karma', 'Auth' ],
    'setting modules via configfile and implcit loading of modules via settings'
);

is_deeply(
    $app->channel,
    [ '#baz', '#quux' ],
    'setting channel via configfile'
);

isa_ok( $app->bot(), 'Bot::BasicBot::Pluggable', 'checking bot' );
