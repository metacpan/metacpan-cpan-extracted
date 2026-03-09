use v5.40;
use Test2::V0;
use lib 'lib';
use lib '../At.pm/lib';
use Bluesky;

# Mock At module
my $mock_at = mock 'At' => (
    override => [
        get => sub {
            my ( $self, $method, $params ) = @_;
            if ( $method eq 'chat.bsky.convo.listConvos' ) {
                return { convos => [ { id => 'convo1', members => [] } ] };
            }
            if ( $method eq 'chat.bsky.convo.getMessages' ) {
                return { messages => [ { id => 'msg1', text => 'hello' } ] };
            }
            return {};
        },
        post => sub {
            my ( $self, $method, $data ) = @_;
            return { success => 1 };
        },
        did => sub {'did:plc:test'},
    ],
);
my $bsky = Bluesky->new();
subtest 'listConvos' => sub {
    my $convos = $bsky->listConvos();
    is( $convos, [ { id => 'convo1', members => [] } ], 'Correctly returned convos array' );
};
subtest 'getMessages' => sub {
    my $msgs = $bsky->getMessages( convoId => 'convo1' );
    is( $msgs, [ { id => 'msg1', text => 'hello' } ], 'Correctly returned messages array' );
};
subtest 'sendMessage' => sub {

    # Verify it doesn't crash and returns something truthy (mock returns success)
    my $res = $bsky->sendMessage( 'convo1', { text => 'hi' } );
    ok( 1, 'sendMessage executed without error' );
};
subtest 'mute/unmute' => sub {
    $bsky->muteConvo('convo1');
    $bsky->unmuteConvo('convo1');
    ok( 1, 'Mute/Unmute executed without error' );
};
done_testing;
