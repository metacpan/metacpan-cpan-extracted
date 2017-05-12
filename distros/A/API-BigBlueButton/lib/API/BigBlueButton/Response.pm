package API::BigBlueButton::Response;

=head1 NAME

API::BigBlueButton::Response - processing of API responses

=cut

use 5.008008;
use strict;
use warnings;

use XML::Fast;

our $VERSION = "0.013";

=head1 VERSION
 
version 0.013

=cut

=head1 METHODS

=over

=item B<new($class,$res)>

Constructor.

$res

    HTTP::Response object.

=cut

sub new {
    my ( $class, $res ) = @_;

    my $success   = $res->is_success;
    my $xml       = $success ? $res->decoded_content : '';
    my $error     = $success ? '' : $res->decoded_content;
    my $status    = $res->status_line;

    my $parsed_response = $xml ? xml2hash( $xml, attr => '' ) : {};

    return bless(
        {
            success  => $success,
            xml      => $xml,
            error    => $error,
            response => $parsed_response->{response} ? $parsed_response->{response} : $parsed_response,
            status   => $status,
        }, $class
    );
}

=item B<xml($self)>

Returns original XML answer.

=cut

sub xml {
    my ( $self ) = @_;

    return $self->{xml};
}

=item B<success($self)>

Returns 1 if request succeeded, 0 otherwise.

=cut

sub success {
    my ( $self ) = @_;

    return $self->{success};
}

=item B<response($self)>

Returns munged response from service. According to method, it can be scalar, hashref of arrayref.

=cut

sub response {
    my ( $self ) = @_;

    return $self->{response};
}

=item B<error($self)>

Returns munged error text.

=cut

sub error {
    my ( $self ) = @_;

    return $self->{error};
}

=item B<status($self)>

Returns response status line.

=cut

sub status {
    my ( $self ) = @_;

    return $self->{status};
}

1;

__END__

=back

=head1 SEE ALSO

L<API::BigBlueButton>

L<API::BigBlueButton::Requests>

L<BigBlueButton API|https://code.google.com/p/bigbluebutton/wiki/API>

=head1 AUTHOR

Alexander Ruzhnikov E<lt>a.ruzhnikov@reg.ruE<gt>

=cut