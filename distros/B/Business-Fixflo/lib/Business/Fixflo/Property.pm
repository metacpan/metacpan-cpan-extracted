package Business::Fixflo::Property;

=head1 NAME

Business::Fixflo::Property

=head1 DESCRIPTION

A class for a fixflo property, extends L<Business::Fixflo::Resource>

=cut

use strict;
use warnings;

use Moo;
use Try::Tiny;
use Carp qw/ carp /;
use Business::Fixflo::Exception;
use Business::Fixflo::Address;

extends 'Business::Fixflo::Resource';

=head1 ATTRIBUTES

    Id
    BlockId
    BlockName
    Created
    ExternalPropertyRef
    PropertyAddressId
    KeyReference
    Address
    Addresses
    Issues
    UpdateDate

=cut

use Carp qw/ confess /;

has [ qw/
    Id
    BlockId
    BlockName
    Created
    ExternalPropertyRef
    PropertyAddressId
    KeyReference
    UpdateDate
/ ] => (
    is => 'rw',
);

has 'PropertyId' => (
    is      => 'rw',
    lazy    => 1,
    default => sub { shift->Id || 0 },
);

has 'Address' => (
    is   => 'rw',
    isa  => sub {
        confess( "$_[0] is not a Business::Fixflo::Address" )
            if ref $_[0] ne 'Business::Fixflo::Address';
    },
    lazy   => 1,
    coerce => sub {
        $_[0] = Business::Fixflo::Address->new( $_[0] )
            if ref( $_[0] ) ne 'Business::Fixflo::Address';
        return $_[0];
    },
);

has 'Addresses' => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        shift->_paginated_items( 'Property','Addresses','PropertyAddress' );
    },
);

has 'Issues' => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        shift->_paginated_items( 'Property','Issues','Issue' );
    },
);

=head1 Operations on a property

=head2 get

Gets a property based on either the ExternalPropertyRef or the PropertyId
(ExternalPropertyRef is favoured if this is set)

=head2 create

Creates a property in the Fixflo API

=head2 update

Updates a property in the Fixflo API - will throw an exception if the PropertyId
is not set

=cut

sub create {
    my ( $self,$update ) = @_;

    $self->SUPER::_create( $update,'Property',sub {
        my ( $self ) = @_;

        $self->PropertyId or $self->PropertyId( 0 );

        my $post_data = { $self->to_hash };
        $post_data->{Address} = { $post_data->{Address}->to_hash }
            if $post_data->{Address};
        return $post_data;
    } );
}

sub get {
    my ( $self ) = @_;

    my $data = $self->client->api_get( $self->ExternalPropertyRef
        ? ( 'Property',$self->_params )
        : ( "Property/".$self->Id )
    );

    foreach my $attr ( keys( %{ $data } ) ) {
        try { $self->$attr( $data->{$attr} ); }
        catch {
            carp( "Couldn't set $attr on @{[ ref( $self ) ]}: $_" );
        };
    }

    return $self;
}

sub _params {
    my ( $self ) = @_;

    return $self->ExternalPropertyRef
        ? { 'ExternalPropertyRef' => $self->ExternalPropertyRef }
        : { 'PropertyId'          => $self->Id };
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
