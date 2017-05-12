use strict;
use warnings;

use Test::Most;
use Test::MockModule;

my $store = Test::MockModule->new('Bot::IRC::Store');
$store->mock( LoadFile => sub {} );
$store->mock( DumpFile => sub {} );

use constant MODULE => 'Bot::IRC::Infobot';

BEGIN { use_ok(MODULE); }
BEGIN { use_ok('Bot::IRC'); }

ok( MODULE->can('init'), 'init() method exists' );

my $plugin;
my $bot = Bot::IRC->new( connect => { server => 'irc.perl.org' } );

lives_ok( sub { Bot::IRC::Infobot::init($bot) }, 'init()' );

done_testing;
