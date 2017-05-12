package Business::Fixflo::Landlord;

=head1 NAME

Business::Fixflo::Landlord

=head1 DESCRIPTION

A class for a fixflo landlord, extends L<Business::Fixflo::Resource>

=cut

use strict;
use warnings;

use Moo;
use Business::Fixflo::Exception;

extends 'Business::Fixflo::Resource';

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
    UpdateDate

=cut

use Carp qw/ confess /;

has [ qw/
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
    UpdateDate
/ ] => (
    is => 'rw',
);

has 'Properties' => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        shift->_paginated_items( 'Landlord','LandlordProperties','Property' );
    },
);

sub create {
    my ( $self,$update ) = @_;

    $self->SUPER::_create( $update,'Landlord',sub {
        my ( $self ) = @_;

        $self->Id or $self->Id( undef ); # force Id of null in JSON
        return { $self->to_hash };
    } );
}

1;
    
# vim: ts=4:sw=4:et
