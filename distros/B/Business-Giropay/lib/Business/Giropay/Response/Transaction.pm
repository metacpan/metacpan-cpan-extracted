package Business::Giropay::Response::Transaction;

=head1 NAME

Business::Giropay::Response::Transaction - response object for L<Business::Giropay::Request::Transaction>

=cut

use Business::Giropay::Types qw/Map Maybe Str/;
use Moo;
with 'Business::Giropay::Role::Response';
use namespace::clean;

=head1 ATTRIBUTES

See L<Business::Giropay::Role::Response/ATTRIBUTES> for attributes common to
all request classes.

=head2 reference

Unique transaction ID from GiroCheckout.

=cut

has reference => (
    is       => 'lazy',
    isa      => Maybe [Str],
    init_arg => undef,
);

sub _build_reference {
    shift->data->{reference};
}

=head2 redirect

Redirect URL to redirect the client to complete Online Banking transaction.

=cut

has redirect => (
    is       => 'lazy',
    isa      => Maybe [Str],
    init_arg => undef,
);

sub _build_redirect {
    shift->data->{redirect};
}

=head1 METHODS

See L<Business::Giropay::Role::Response/METHODS>.

=cut

1;
