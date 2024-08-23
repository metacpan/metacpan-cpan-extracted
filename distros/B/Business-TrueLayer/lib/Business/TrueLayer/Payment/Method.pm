package Business::TrueLayer::Payment::Method;

=head1 NAME

Business::TrueLayer::Payment::Method - class representing a payment_method
as used in the TrueLayer v3 API.

=head1 SYNOPSIS

    my $PaymentMethod = Business::TrueLayer::Payment::Method->new(
        name => ...
    );

=cut

use strict;
use warnings;
use feature qw/ signatures postderef /;

use Moose;
use MooseX::Aliases;
use Moose::Util::TypeConstraints;
no warnings qw/ experimental::signatures experimental::postderef /;

with 'Business::TrueLayer::Types::Beneficiary';
use Business::TrueLayer::Provider;

use namespace::autoclean;

=head1 ATTRIBUTES

=over

=item type (Str)

=item beneficiary

A L<Business::TrueLayer::Beneficiary> object. Hash refs will be coerced.

=item provider

A L<Business::TrueLayer::Provider> object. Hash refs will be coerced.

=back

=cut

has [ qw/ type / ] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has [ qw/ mandate_id / ] => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
);

coerce 'Business::TrueLayer::Provider'
    => from 'HashRef'
    => via {
        Business::TrueLayer::Provider->new( %{ $_ } );
    }
;

has provider => (
    is       => 'ro',
    isa      => 'Business::TrueLayer::Provider',
    coerce   => 1,
    required => 0,
    alias    => 'provider_selection',
);

has beneficiary => (
    is       => 'ro',
    isa      => 'Business::TrueLayer::Beneficiary',
    coerce   => 1,
    required => 0,
);

sub BUILD {
	my ( $self ) = @_;

	# the type defines the requirement for some of the
	# attributes of this object
	if ( $self->is_bank_transfer ) {
		$self->beneficiary || die "payment_method of type 'bank_transfer'"
			. " requires a beneficiary";

		$self->provider || die "payment_method of type 'bank_transfer'"
			. " requires a provider / provider_selection";

	} elsif ( $self->is_mandate ) {
		$self->mandate_id || die "payment_method of type 'mandate'"
			. " requires a mandate_id";
	}
}

=head1 METHODS

=head2 is_bank_transfer

=head2 is_mandate

Check if the payment method is a particular type

    if ( $PaymentMethod->is_bank_transfer ) {
        ...
    }

=cut

sub is_bank_transfer { shift->_is_type( 'bank_transfer' ); }
sub is_mandate       { shift->_is_type( 'mandate' ); }

sub _is_type ( $self,$type ) {
    return ( $self->type // '' ) eq $type ? 1 : 0;
}


=head1 SEE ALSO

L<Business::TrueLayer::Beneficiary>

L<Business::TrueLayer::Provider>

=cut

1;
