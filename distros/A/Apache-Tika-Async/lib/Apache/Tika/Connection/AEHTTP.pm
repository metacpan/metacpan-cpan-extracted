package Apache::Tika::Connection::AEHTTP;
use AnyEvent::HTTP qw(http_request);
use Promises qw(deferred);
use Try::Tiny;
use Moo;
with 'Apache::Tika::Connection';

use vars '$VERSION';
$VERSION = '0.07';

sub request {
    my( $self, $method, $url, $content, @headers ) = @_;
    # Should initialize
    
    $method = uc $method;
    
    my $content_size = length $content;
    
    # 'text/plain' for the language
    my %headers= (
                  "Content-Length" => $content_size,
                  "Accept" => 'application/json,text/plain',
                  @headers
                 );

    my $p = deferred;
    http_request(
        $method => $url,
        persistent => 1,
        headers => \%headers,
        body => $content,
        sub {
            my ( $body, $headers ) = @_;
            # The headers might be invalid!
            try {
                my ( $code, $response ) = $self->process_response(
                    undef,                        # request
                    delete $headers->{Status},    # code
                    delete $headers->{Reason},    # msg
                    $body,                        # body
                    $headers                      # headers
                );
                
                $p->resolve( $code, $response );
            }
            catch {
                warn "Internal error: $_";
                $p->reject($_);
            }
        },
    );
    $p->promise
}

1;

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/apache-tika>.

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

Copyright 2014-2016 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
