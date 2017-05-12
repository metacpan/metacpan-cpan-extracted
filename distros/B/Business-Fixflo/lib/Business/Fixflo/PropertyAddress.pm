package Business::Fixflo::PropertyAddress;

=head1 NAME

Business::Fixflo::Property::Address

=head1 DESCRIPTION

A class for a fixflo property address, extends L<Business::Fixflo::Property>

=cut

use strict;
use warnings;

use Moo; 
extends 'Business::Fixflo::Property';

use Try::Tiny;
use Carp qw/ carp /;
use Business::Fixflo::Property;
use Business::Fixflo::Address;
use Business::Fixflo::Exception;

use Carp qw/ confess /;

=head1 Operations on a property address

=head2 get

Gets a property address based on the Id

=head2 merge

merges a property address into a property:

    $PropertyAddress = $PropertyAddress->merge( $Property );

$Property must be a Business::Fixflo::Property object and have its Id set

=head2 split

splits a property address from a property

=head2 property

gets the L<Business::Fixflo::Property> object associated with the property
address:

    my $Property = $PropertyAddress->property;

=cut

sub get {
    my ( $self ) = @_;

    my $data = $self->client->api_get(
        'PropertyAddress/' . $self->Id
    );

    foreach my $attr ( keys( %{ $data } ) ) {
        try { $self->$attr( $data->{$attr} ); }
        catch {
            carp( "Couldn't set $attr on @{[ ref( $self ) ]}: $_" );
        };
    }

    return $self;
}

sub merge {
    my ( $self,$Property ) = @_;

    Business::Fixflo::Exception->throw({
        message => 'PropertyAddress->merge requires a Business::Fixflo::Property',
    }) if ref( $Property ) ne 'Business::Fixflo::Property';

    Business::Fixflo::Exception->throw({
        message => 'PropertyAddress->Id must be set to merge',
    }) if ! $self->Id;

    Business::Fixflo::Exception->throw({
        message => 'Property->Id must be set to merge',
    }) if ! $Property->Id;

    return $self->_parse_envelope_data(
        $self->client->api_post(
            'PropertyAddress/Merge',
            {
                Id         => $self->Id,
                PropertyId => $Property->Id,
            }
        ),
    );
}

sub split {
    my ( $self ) = @_;

    Business::Fixflo::Exception->throw({
        message => 'PropertyAddress->Id must be set to split',
    }) if ! $self->Id;

    return $self->_parse_envelope_data(
        $self->client->api_post(
            'PropertyAddress/Split',
            {
                Id => $self->Id,
            }
        ),
    );
}

sub property {
    my ( $self ) = @_;

    my $Property = Business::Fixflo::Property->new(
        client => $self->client,
        Id     => $self->PropertyId,
    );

    return $Property->get;
}

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/business-fixflo

=cut

1;

# vim: ts=4:sw=4:et
