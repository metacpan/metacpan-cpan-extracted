
=head1 SYNOPSIS

    # Subscribe to all incoming CPAN uploads
    perl eg/feed.pl

    # Subscribe to CPAN upload feed for a dist (Statocles)
    perl eg/feed.pl http://api.cpantesters.org/v1/upload/dist/Statocles

=head1 DESCRIPTION

This example shows how to subscribe to the WebSocket feed from
L<http://api.cpantesters.org> using L<Mojo::UserAgent>.

=head1 SEE ALSO

L<Mojo::UserAgent>, L<http://api.cpantesters.org>

=cut

use v5.024;
use warnings;
use experimental qw( signatures postderef );
use Mojo::UserAgent;

my $topic = $ARGV[0] || 'http://api.cpantesters.org/v1/upload';

sub open_socket {
    state $ua = Mojo::UserAgent->new(
        inactivity_timeout => 60000,
    );
    $ua->websocket( $topic => sub( $ua, $tx ) {
        say 'WebSocket handshake failed: ' . $tx->error->{message} and return unless $tx->is_websocket;
        say sprintf "[%s] Connected", scalar localtime;
        $tx->on( json => sub( $tx, $upload ) {
            say sprintf qq{[%s] Got upload: %s (%s) by %s},
                scalar localtime, $upload->@{qw( dist version author )};
        } );
        $tx->on( finish => sub( $tx, $code ) {
            say sprintf "[%s] Connection closed: %s",
                scalar localtime, $code;
            Mojo::IOLoop->stop;
        } );
    } );
}

while ( 1 ) {
    open_socket() && Mojo::IOLoop->start;
    sleep 1;
}

