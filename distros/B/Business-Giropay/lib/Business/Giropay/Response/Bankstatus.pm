package Business::Giropay::Response::Bankstatus;

=head1 NAME

Business::Giropay::Response::Bankstatus - response object for L<Business::Giropay::Request::Bankstatus>

=cut

use Business::Giropay::Types qw/Bool Int Map Maybe Str/;
use Moo;
with 'Business::Giropay::Role::Response';
use namespace::clean;

=head1 ATTRIBUTES

See L<Business::Giropay::Role::Response/ATTRIBUTES> for attributes common to
all request classes.

=head2 bankcode

Numeric bank code.

=cut

has bankcode => (
    is       => 'lazy',
    isa      => Maybe [Int],
    init_arg => undef,
);

sub _build_bankcode {
    shift->data->{bankcode};
}

=head2 bic

Bank's BIC code

=cut

has bic => (
    is       => 'lazy',
    isa      => Maybe [Str],
    init_arg => undef,
);

sub _build_bic {
    shift->data->{bic};
}

=head2 bankname

Bank name.

=cut

has bankname => (
    is       => 'lazy',
    isa      => Maybe [Str],
    init_arg => undef,
);

sub _build_bankname {
    shift->data->{bankname};
}

=head2 supported

1 = payment via this bank/issuer is supported
0 = payment via this bank/issuer is not supported 

=cut

has supported => (
    is       => 'lazy',
    isa      => Maybe [Bool],
    init_arg => undef,
);

sub _build_supported {
    my $self = shift;
    return $self->data->{ $self->network };
}

=head2 giropayid

Only applicable for giropay (not eps, etc).

1 = giropay-ID and giropay-ID + giropay is supported 
0 = giropay-ID and giropay-ID + giropay is not supported 

=cut

has giropayid => (
    is       => 'lazy',
    isa      => Maybe [Bool],
    init_arg => undef,
);

sub _build_giropayid {
    shift->data->{giropayid};
}

=head1 METHODS

See L<Business::Giropay::Role::Response/METHODS>.

=cut

1;
