use strict;
use warnings;

use Test::Most;
use Test::MockModule;

package MockDBI;

sub new {
    return bless( {}, shift );
}
sub do {}
sub prepare {
    return shift;
}
sub execute {}
sub fetchrow_array {
    return '{"value":"things"}';
}

package main;

my $store = Test::MockModule->new('DBI');
$store->mock( connect => sub { return MockDBI->new } );

use constant MODULE => 'Bot::IRC::Store::SQLite';

BEGIN { use_ok(MODULE); }
BEGIN { use_ok('Bot::IRC'); }

ok( MODULE->can('init'), 'init() method exists' );

my $plugin;
my $bot = Bot::IRC->new( connect => { server => 'irc.perl.org' } );

lives_ok( sub { $plugin = MODULE->new($bot) }, 'new()' );
lives_ok( sub { Bot::IRC::Store::SQLite::init($bot) }, 'init()' );

ok( $bot->can('store'), 'store() method exists' );
ok( $bot->store->can('set'), 'set() method exists' );
ok( $bot->store->can('get'), 'get() method exists' );

lives_ok( sub { $bot->store->set( stuff => 'things' ) }, 'set()' );
lives_ok( sub { $bot->store->get('stuff') }, 'get()' );

done_testing;
