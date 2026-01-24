use v5.42;
use feature 'class';
use experimental 'try';
no warnings 'experimental::class';

class At::Protocol::Firehose 1.0 {
    use At::Error;
    field $at       : param;
    field $url      : param : reader //= 'wss://bsky.network/xrpc/com.atproto.sync.subscribeRepos';
    field $callback : param;
    ADJUST {
        try {
            require CBOR::Free;

            # Ensure we have some way to decode sequences
            my $has_seq = CBOR::Free->can('decode_sequence') || do {
                my $ok = 0;
                try { require CBOR::Free::SequenceDecoder; $ok = 1; }
                catch ($e) { }
                $ok;
            };
            die "CBOR::Free is too old (SequenceDecoder missing)" unless $has_seq;
        }
        catch ($e) {
            die "CBOR::Free (with SequenceDecoder support) is required for the firehose. $e";
        }
    }

    method start() {
        $at->http->websocket(
            $url => sub ( $msg, $err ) {
                if ($err) {
                    $callback->( undef, undef, $err );
                    return;
                }
                try {
                    my @objects;
                    {
                        local $SIG{__WARN__} = sub {
                            return if $_[0] =~ /Ignoring unrecognized CBOR tag #42/;
                            warn $_[0];
                        };

                        # Try functional interface first (CBOR::Free 0.32+)
                        try {
                            @objects = CBOR::Free::decode_sequence($msg);
                        }
                        catch ($e) {

                            # Fallback to SequenceDecoder
                            my $decoder = CBOR::Free::SequenceDecoder->new();
                            if ( my $sr = $decoder->give($msg) ) {
                                push @objects, $$sr;
                            }
                            while ( my $sr = $decoder->get() ) {
                                push @objects, $$sr;
                            }
                        }
                    }
                    if ( @objects >= 2 ) {
                        $callback->( $objects[0], $objects[1], undef );
                    }
                    elsif ( @objects == 1 ) {
                        $callback->( $objects[0], undef, At::Error->new( message => 'Incomplete firehose message', fatal => 0 ) );
                    }
                }
                catch ($e) {
                    $callback->( undef, undef, At::Error->new( message => "Firehose decode failed: $e", fatal => 0 ) );
                }
            }
        );
    }
}
1;
__END__

=pod

=encoding utf-8

=head1 NAME

At::Protocol::Firehose - AT Protocol Firehose Client

=head1 SYNOPSIS

    my $fh = $at->firehose(sub ( $header, $body, $err ) {
        return warn $err if $err;
        say "Event type: " . $header->{t};
    });

    $fh->start();

=head1 DESCRIPTION

C<At::Protocol::Firehose> handles the real-time streaming of events from an AT Protocol relay or PDS. It decodes the
binary DAG-CBOR messages into Perl data structures.

Each message from the firehose consists of two parts:

=over

=item 1. B<Header>: A map containing the message type (C<t>) and optional operation (C<op>).

=item 2. B<Body>: The actual event data, which varies by message type.

=back

=head1 Methods

=head2 C<new( at => $at, callback => $cb, [ url => $url ] )>

Constructor. C<url> defaults to the global Bluesky relay firehose.

=head2 C<start()>

Starts the WebSocket connection. This is non-blocking and requires an event loop (like L<Mojo::IOLoop>) to be running.

=head1 SEE ALSO

L<At>, L<https://docs.bsky.app/docs/advanced-guides/firehose>

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2026 Sanko Robinson. License: Artistic License 2.0.

=cut

