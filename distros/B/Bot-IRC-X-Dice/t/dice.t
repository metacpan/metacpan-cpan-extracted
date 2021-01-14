use Test2::V0;
use Bot::IRC;
use Bot::IRC::Store;
use Bot::IRC::X::Dice;

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

ok( Bot::IRC::X::Dice->can('init'), 'init() method exists' );
ok( lives { Bot::IRC::X::Dice::init($bot) }, 'init()' ) or note $@;

ok( lives { $hook->( $bot, undef, { expr => '2d6+2' } ) }, '2d6+2' ) or note $@;
is( scalar( grep { $replies[0][0] == $_ } 4 .. 14 ), 1, 'dice roll result expected' );

done_testing;
