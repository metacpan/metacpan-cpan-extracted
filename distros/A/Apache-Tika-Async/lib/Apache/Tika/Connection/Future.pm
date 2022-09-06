package Apache::Tika::Connection::Future;
use 5.020;
use Future::HTTP;
use Moo;
with 'Apache::Tika::Connection';

use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.09';

has ua => (
    is => 'ro',
    default => sub {
        return Future::HTTP->new()
    },
);

sub request( $self, $method, $url, $content, @headers ) {
    # Should initialize

    $method = uc $method;

    my $content_size = length $content;

    # 'text/plain' for the language
    my %headers= (
                  "Content-Length" => $content_size,
                  "Accept"         => 'application/json,text/plain',
                  'Content-Type'   => 'application/octet-stream',
                  @headers
                 );

    $self->ua->http_request(
        $method => $url,
        persistent => 1,
        headers => \%headers,
        body => $content,
    )->then(sub( $body, $headers ) {
        # The headers might be invalid!
        my ( $code, $response ) = $self->process_response(
            undef,                        # request
            delete $headers->{Status},    # code
            delete $headers->{Reason},    # msg
            $body,                        # body
            $headers                      # headers
        );
        Future->done( $code, $response )
    });
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
