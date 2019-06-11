package Apache::Tika::Connection::LWP;
use LWP::UserAgent;
use LWP::ConnCache;
use Promises qw(deferred);
use Try::Tiny;
use Moo 2;
with 'Apache::Tika::Connection';

our $VERSION = '0.08';

has ua => (
    is => 'ro',
    default => sub {
        my $ua = LWP::UserAgent->new();
        $ua->conn_cache( LWP::ConnCache->new );

        $ua
    },
);

sub request {
    my( $self, $method, $url, $content, @headers ) = @_;

    my $content_size = length $content;
    my @content = $content ? (Content => $content) : ();

    # 'text/plain' for the language
    my %headers= (
                  "Content-Length" => $content_size,
                  "Accept"         => 'application/json,text/plain',
                  'Content-Type'   => 'application/octet-stream',
                  @headers,
                  @content,
                 );
    my $res = $self->ua->$method( $url, %headers);

    my $p = deferred;
    my ( $code, $response ) = $self->process_response(
        $res->request,                     # request
        $res->code,                        # code
        $res->message,                     # msg
        $res->decoded_content,             # body
        $res->headers                      # headers
    );
    $p->resolve( $code, $response );

    $p->promise
}

1;

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/Apache-Tika-Async>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Apache-Tika-Async>
or via mail to L<apache-tika-async-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2014-2019 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut