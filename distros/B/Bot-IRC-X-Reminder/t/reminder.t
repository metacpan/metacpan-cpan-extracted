use Test2::V0;
use Bot::IRC;
use Bot::IRC::Store;
use Bot::IRC::X::Reminder;

my ( $hook, @replies );
my $mock_store = mock 'Bot::IRC::Store' => ( override => [ qw( new get set ) ] );
my $mock_bot   = mock 'Bot::IRC' => (
    override => [
        hook     => sub { $hook = $_[2] },
        reply    => sub { shift; push( @replies, [@_] ) },
        reply_to => sub { shift; push( @replies, [@_] ) },
    ],
);
my $bot = Bot::IRC->new( connect => { server => 'irc.perl.org' } );

ok( Bot::IRC::X::Reminder->can('init'), 'init() method exists' );
ok( lives { Bot::IRC::X::Reminder::init($bot) }, 'init()' ) or note $@;

done_testing;
