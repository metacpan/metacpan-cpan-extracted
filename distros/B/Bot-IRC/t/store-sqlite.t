use Test2::V0;
use Bot::IRC::Store::SQLite;
use Bot::IRC;

package MockDBI;

sub new { return bless( {}, shift ) }
sub do {}
sub prepare { return shift }
sub prepare_cached { return shift }
sub execute {}
sub errstr {}
sub fetchrow_array { return '{"value":"things"}' }

package main;

my $mock = mock 'DBI' => ( override => [ connect => sub { return MockDBI->new } ] );

ok( Bot::IRC::Store::SQLite->can('init'), 'init() method exists' );

my $plugin;
my $bot = Bot::IRC->new( connect => { server => 'irc.perl.org' } );

ok( lives { $plugin = Bot::IRC::Store::SQLite->new($bot) }, 'new()' ) or note $@;
ok( lives { Bot::IRC::Store::SQLite::init($bot) }, 'init()' ) or note $@;

ok( $bot->can('store'), 'store() method exists' );
ok( $bot->store->can('set'), 'set() method exists' );
ok( $bot->store->can('get'), 'get() method exists' );

done_testing;
