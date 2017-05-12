package Ambassador::API::V2::Role::Response;

use Moo::Role;
use Carp;
use Types::Standard ":types";
with 'Ambassador::API::V2::Role::HasJSON';

our $VERSION = '0.001';

has http_response => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
);

has response => (
    is       => 'lazy',
    isa      => HashRef,
    required => 1,
);

sub _build_response {
    my $self = shift;

    my $content = eval { $self->json->decode($self->http_response->{content}); };
    croak "Failed to decode @{[ $self->http_response->{content} ]}" if !$content;
    return $content->{response};
}

has code => (
    is       => 'lazy',
    isa      => Int,
    required => 1,
);

sub _build_code {
    my $self = shift;

    return $self->response->{code};
}

has message => (
    is       => 'lazy',
    isa      => Str,
    required => 1
);

sub _build_message {
    my $self = shift;

    return $self->response->{message};
}

sub new_from_response {
    my $class = shift;
    my $res   = shift;

    return $class->new(http_response => $res);
}

sub is_success {
    my $self = shift;

    return $self->code == 200;
}

1;

__END__

=head1 NAME

package Ambassador::API::V2::Role::Response;
Ambassador::API::V2::
# ABSTRACT: A response from the getambassador.com API v2

=head1 DESCRIPTION

Encapsulates the Ambassador Response Format.

See L<https://docs.getambassador.com/docs/response-codes>.

=head1 ATTRIBUTES

=over 4

=item http_response

The original HTTP::Tiny response.

=item response

The Ambassador "response" as a hash ref.

=item code

The Ambassador "code" field.

B<NOT> the HTTP repsonse code.

=item message

The Ambassador "message" field.

=back

=head1 CONSTRUCTORS

=over 4

=item new_from_response($resp)

    my $response = Ambassador::API::V2::Response->new_from_response(
        $http_tiny_response
    );

Returns a new object from an HTTP::Tiny response hash ref.

=back

=head1 METHODS

=over 4

=item $bool = $resp->is_success

Returns whether the repsonse was successful or not.

=back

=head1 SEE ALSO

L<Ambassador::API::V2::Result>
L<Ambassador::API::V2::Error>

=head1 SOURCE

The source code repository for Ambassador-API-V2 can be found at
F<https://github.com/dreamhost/Ambassador-API-V2>.

=head1 COPYRIGHT

Copyright 2016 Dreamhost E<lt>dev-notify@hq.newdream.netE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
