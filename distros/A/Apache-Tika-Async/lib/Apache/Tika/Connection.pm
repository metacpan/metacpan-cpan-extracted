package Apache::Tika::Connection;
use strict;
use Moo::Role;
use JSON::XS;
use vars qw($VERSION);
$VERSION = '0.07';

sub decode_response {
    my( $self, $body ) = @_;
    
    return decode_json( $body );
}

sub process_response {
    my ( $self, $params, $code, $msg, $body, $headers ) = @_;
    
    my $mime_type = $headers->{"content-type"};

    my $is_encoded = $mime_type && $mime_type !~ m!^text/plain\b!;

    # Request is successful

    if ( $code >= 200 and $code <= 209 ) {
        if ( defined $body and length $body ) {
            # Let's hope it's JSON
            $body = $self->decode_response($body)
                if $is_encoded;
            return $code, $body;
        }
        return ( $code, 1 ) if $params->{method} eq 'HEAD';
        return ( $code, '' );
    }

    # Check if the error should be ignored
    return ($code, $body);
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
L<https://rt.cpan.org/Public/Dist/Display.html?Name=CORION-Apache-Tika>
or via mail to L<corion-apache-tika-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2014-2016 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut