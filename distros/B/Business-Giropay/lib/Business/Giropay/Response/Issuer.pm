package Business::Giropay::Response::Issuer;

=head1 NAME

Business::Giropay::Response::Issuer - response object for L<Business::Giropay::Request::Issuer>

=cut

use Business::Giropay::Types qw/Map Maybe Str/;
use Moo;
with 'Business::Giropay::Role::Response';
use namespace::clean;

=head1 ATTRIBUTES

See L<Business::Giropay::Role::Response/ATTRIBUTES> for attributes common to
all request classes.

=head2 issuers

A hash reference of issuer banks with BIC as key and name as value.

=cut

has issuers => (
    is  => 'lazy',
    isa => Maybe [ Map [ Str, Str ] ],
    init_arg => undef,
);

sub _build_issuers {
    shift->data->{issuer};
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
