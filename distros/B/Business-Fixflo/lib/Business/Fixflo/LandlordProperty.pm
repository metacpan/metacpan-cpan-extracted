package Business::Fixflo::LandlordProperty;

=head1 NAME

Business::Fixflo::LandlordProperty

=head1 DESCRIPTION

A class for a fixflo landlord property, extends L<Business::Fixflo::Resource>

=cut

use strict;
use warnings;

use Moo;
use Business::Fixflo::Exception;

extends 'Business::Fixflo::Resource';

use Business::Fixflo::Property;
use Business::Fixflo::Address;
use Business::Fixflo::Landlord;

=head1 ATTRIBUTES

    Id
    CompanyName
    Title
    FirstName
    Surname
    EmailAddress
    ContactNumber
    ContactNumberAlt
    DisplayName
    WorksAuthorisationLimit
    EmailCC
    IsDeleted
    ExternalRef

=cut

use Carp qw/ confess /;

has [ qw/
    Id
	LandlordId
	PropertyId
	DateFrom
	DateTo
	Address
/ ] => (
    is => 'rw',
);

=head1 Operations on a landlord address

=head2 create

Creates a landlord property in the Fixflo API

=head2 update

Updates a landlord property in the Fixflo API - will throw an exception if the Id
is not set

=head2 property

Returns the property as a L<Business::Fixflo::Property> object

=head2 address

Returns the address as a L<Business::Fixflo::Address> object

=head2 landlord

Returns the landlord as a L<Business::Fixflo::Landlord> object

=cut

sub create {
    my ( $self,$update ) = @_;

    $self->SUPER::_create( $update,'LandlordProperty',sub {
        my ( $self ) = @_;

        $self->Id or $self->Id( undef ); # force Id of null in JSON
        return { $self->to_hash };
    } );
}

sub property {
    my ( $self ) = @_;

    my $Property = Business::Fixflo::Property->new(
        client => $self->client,
        Id     => $self->PropertyId,
    );

    return $Property->get;
}

sub address {
    my ( $self ) = @_;

    return Business::Fixflo::Address->new(
        client => $self->client,
        %{ $self->Address },
    );
}

sub landlord {
    my ( $self ) = @_;

    my $Landlord = Business::Fixflo::Landlord->new(
        client => $self->client,
        Id     => $self->LandlordId,
    );

    return $Landlord->get;
}

1;
    
# vim: ts=4:sw=4:et
