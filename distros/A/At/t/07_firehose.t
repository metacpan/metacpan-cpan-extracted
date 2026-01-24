use Test2::V0;
use At;
use At::Protocol::Firehose;
use v5.42;
skip_all 'CBOR::Free required for firehose' unless eval { require CBOR::Free; 1 };
plan 3;
my $at = At->new( host => 'bsky.social' );
subtest 'firehose instantiation' => sub {
    my $fh = $at->firehose( sub { } );
    isa_ok $fh, 'At::Protocol::Firehose';
    is $fh->url, 'wss://bsky.network/xrpc/com.atproto.sync.subscribeRepos', 'default url';
};
subtest 'custom url' => sub {
    my $fh = $at->firehose( sub { }, 'wss://example.com/firehose' );
    is $fh->url, 'wss://example.com/firehose', 'custom url';
};
subtest 'decoding logic' => sub {
    skip_all 'CBOR::Free required for this test' unless eval { require CBOR::Free; 1 };
    my $header_data = { t    => '#commit',     op  => 1 };
    my $body_data   = { repo => 'did:plc:123', ops => [] };
    my $msg         = CBOR::Free::encode($header_data) . CBOR::Free::encode($body_data);
    my $called      = 0;
    my $cb          = sub ( $header, $body, $err ) {
        $called++;
        is $header->{t},  '#commit',     'header decoded';
        is $body->{repo}, 'did:plc:123', 'body decoded';
        is $err,          undef,         'no error';
    };

    # Mock the http object to capture the callback passed to websocket
    my $ws_cb;
    my $mock = mock 'At::UserAgent::Mojo' => (
        override => [
            websocket => sub {
                my ( $self, $url, $callback ) = @_;
                $ws_cb = $callback;
            },
        ],
    );

    # Force Mojo UA for testing if not present, or just mock the current one
    my $at = At->new();
    my $fh = $at->firehose($cb);
    $fh->start();
    ok $ws_cb, 'captured websocket callback';
    $ws_cb->( $msg, undef );
    is $called, 1, 'callback was triggered by mocked websocket';
};
done_testing;
