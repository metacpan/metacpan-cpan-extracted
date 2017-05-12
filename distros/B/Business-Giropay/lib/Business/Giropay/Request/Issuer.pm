package Business::Giropay::Request::Issuer;

=head1 NAME

Business::Giropay::Request::Issuer - returns a list containing all banks.

=cut

use Business::Giropay::Types qw/Str/;
use Moo;
with 'Business::Giropay::Role::Request';
use namespace::clean;

=head1 ATTRIBUTES

See L<Business::Giropay::Role::Request/ATTRIBUTES> for attributes common to
all request classes.

=head2 response_class

The response class to use. Defaults to L<Business::Giropay::Response::Issuer>.

=cut

has response_class => (
    is      => 'ro',
    isa     => Str,
    default => "Business::Giropay::Response::Issuer",
);

=head1 METHODS

See L<Business::Giropay::Role::Request/METHODS> in addition to the following:

=head2 parameters

This request type has no additional parameters and so this method returns
an empty array reference.

=cut

sub parameters {
    return [];
}

=head2 uri

Returns the URI to be appended to L<Business::Giropay::Role::Request/base_uri>
to construct the appropriate URL for the request.

=cut

sub uri {
    return shift->network . '/issuer';
}

1;
