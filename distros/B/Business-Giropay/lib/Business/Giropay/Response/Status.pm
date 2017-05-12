package Business::Giropay::Response::Status;

=head1 NAME

Business::Giropay::Response::Status - response object for L<Business::Giropay::Request::Status>

=cut

use Business::Giropay::Types qw/Int Maybe Str/;
use Moo;
with 'Business::Giropay::Role::Response';
use namespace::clean;

=head1 ATTRIBUTES

See L<Business::Giropay::Role::Response/ATTRIBUTES> for attributes common to
all request classes.

=head2 reference

Unique GiroCheckout transaction ID.

=cut

has reference => (
    is       => 'lazy',
    isa      => Maybe [Str],
    init_arg => undef,
);

sub _build_reference {
    shift->data->{reference};
}

=head2 backendTxId

Payment processor transaction id

=cut

has backendTxId => (
    is       => 'lazy',
    isa      => Maybe [Str],
    init_arg => undef,
);

sub _build_backendTxId {
    shift->data->{backendTxId};
}

=head2 amount

If a decimal currency is used, the amount is in the smallest unit of value,
eg. Cent, Penny.

=cut

has amount => (
    is       => 'lazy',
    isa      => Maybe [Str],
    init_arg => undef,
);

sub _build_amount {
    shift->data->{amount};
}

=head2 currency

currency

=cut

has currency => (
    is       => 'lazy',
    isa      => Maybe [Str],
    init_arg => undef,
);

sub _build_currency {
    shift->data->{currency};
}

=head2 resultPayment

Payment result code.

=cut

has resultPayment => (
    is       => 'lazy',
    isa      => Maybe [Str],
    init_arg => undef,
);

sub _build_resultPayment {
    shift->data->{resultPayment};
}

=head2 resultAVS

Result of the age verification (in case of a giropay-ID transaction).

=cut

has resultAVS => (
    is       => 'lazy',
    isa      => Maybe [Int],
    init_arg => undef,
);

sub _build_resultAVS {
    shift->data->{resultAVS};
}

=head2 obvName

Optional adjustable field, which includes the name of the person who has to be verified (in case of a giropay-ID transaction).


=cut

has obvName => (
    is       => 'lazy',
    isa      => Maybe [Str],
    init_arg => undef,
);

sub _build_obvName {
    shift->data->{obvName};
}

=head1 METHODS

See L<Business::Giropay::Role::Response/METHODS> for methods in addition to
the following:

=head2 has_bic $bic_code

Returns true if C<$bic_code> exists as a key in L</issuers>.

=cut

sub has_bic {
    my ( $self, $bic ) = @_;
    exists $self->issuers->{$bic} ? 1 : 0;
}

1;
