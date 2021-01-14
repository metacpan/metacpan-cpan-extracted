use Test2::V0 -srand => 20201025;
use Bot::IRC;
use Bot::IRC::Store;
use Bot::IRC::X::ManagementSpeak;

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

ok( Bot::IRC::X::ManagementSpeak->can('init'), 'init() method exists' );
ok( lives { Bot::IRC::X::ManagementSpeak::init($bot) }, 'init()' ) or note $@;

ok( lives { $hook->( $bot, undef, undef ) }, 'speak' ) or note $@;
is(
    $replies[0][0],
    'They would exploit your web-enabled paradigm where our revolutionary ' .
        'architecture shall facilitate its B2B functionality. Consequently, as if ' .
        'they promoted your architecture, my plug-and-play convergence researched ' .
        'its global channel. Our e-market incentivizes value-added schema. While ' .
        'we prepared its robust niche, our frictionless web-readiness helped your ' .
        'model, although my paradigm is persuaded.',
    'generated text',
);

done_testing;
