use v5.42;
use Test2::V0;
use At;
use At::Protocol::Firehose;
skip_all 'Codec::CBOR required for firehose'     unless eval { require Codec::CBOR;     1 };
skip_all 'Mojo::UserAgent required for firehose' unless eval { require Mojo::UserAgent; 1 };
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
    require Codec::CBOR;
    my $codec       = Codec::CBOR->new();
    my $header_data = { t    => '#commit',     op  => 1 };
    my $body_data   = { repo => 'did:plc:123', ops => [] };
    my $msg         = $codec->encode($header_data) . $codec->encode($body_data);
    my $called      = 0;
    my $cb          = sub ( $header, $body, $err ) {
        $called++;
        is $header->{t},  '#commit',     'header decoded';
        is $body->{repo}, 'did:plc:123', 'body decoded';
        ok !defined $err, 'no error';
    };

    # Mock the http object to capture the callback passed to websocket
    my $ws_cb;
    my $mock = mock 'At::UserAgent::Mojo' => (
        override => [
            websocket => sub {
                my ( $self, $url, $callback ) = @_;
                $ws_cb = $callback;
            }
        ]
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
