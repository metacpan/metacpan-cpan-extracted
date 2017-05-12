use strict;
use warnings;

use Test::Most;
use Test::MockModule;

my $store = Test::MockModule->new('Bot::IRC::Store');
$store->mock( LoadFile => sub { return { stuff => 'things' } } );
$store->mock( DumpFile => sub {} );

use constant MODULE => 'Bot::IRC::Store';

BEGIN { use_ok(MODULE); }
BEGIN { use_ok('Bot::IRC'); }

ok( MODULE->can('init'), 'init() method exists' );

my $plugin;
my $bot = Bot::IRC->new( connect => { server => 'irc.perl.org' } );

lives_ok( sub { $plugin = MODULE->new($bot) }, 'new()' );
lives_ok( sub { Bot::IRC::Store::init($bot) }, 'init()' );

ok( $bot->can('store'), 'store() method exists' );
ok( $bot->store->can('set'), 'set() method exists' );
ok( $bot->store->can('get'), 'get() method exists' );

lives_ok( sub { $bot->store->set( stuff => 'things' ) }, 'set()' );
lives_ok( sub { $bot->store->get('stuff') }, 'get()' );

done_testing;
