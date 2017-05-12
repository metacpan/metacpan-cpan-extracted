package Business::Giropay::Request::Status;

=head1 NAME

Business::Giropay::Request::Status - transaction data of past transactions

=cut

use Business::Giropay::Types qw/Int Str/;
use Moo;
with 'Business::Giropay::Role::Request';
use namespace::clean;

=head1 ATTRIBUTES

See L<Business::Giropay::Role::Request/ATTRIBUTES> for attributes common to
all request classes.

=head2 reference

Unique GiroCheckout transaction id.

=cut

has reference => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

=head2 response_class

The response class to use. Defaults to L<Business::Giropay::Response::Status>.

=cut

has response_class => (
    is      => 'ro',
    isa     => Str,
    default => "Business::Giropay::Response::Status",
);

=head1 METHODS

See L<Business::Giropay::Role::Request/METHODS> in addition to the following:

=head2 parameters

Returns additional parameters for the request.

=cut

sub parameters {
    return ['reference'];
}

=head2 uri

Returns the URI to be appended to L<Business::Giropay::Role::Request/base_uri>
to construct the appropriate URL for the request.

=cut

sub uri {
    return 'transaction/status';
}

1;
