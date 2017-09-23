package Business::GoCardless::Resource;

=head1 NAME

Business::GoCardless::Resource

=head1 DESCRIPTION

This is a base class for gocardless resource classes, it implements common
behaviour. You shouldn't use this class directly, but extend it instead.

=cut

use strict;
use warnings;

use Moo;
use Carp qw/ carp confess /;
use JSON ();

=head1 ATTRIBUTES

=head2 endpoint

The gocardless API endpoint that corresponds to the resource, for example a
L<Business::GoCardless::Bill> object will have an endpoint of "bills". This
is handled automatically, you do not need to pass this unless the name of the
resource differs significantly from the endpoint.

=head2 client

The client object, defaults to L<Business::GoCardless::Client>.

=cut

has endpoint => (
    is       => 'ro',
    default  => sub {
        my ( $self ) = @_;
        my ( $class ) = ( split( ':',ref( $self ) ) )[-1];

        confess( "You must subclass Business::GoCardless::Resource" )
            if $class eq 'Resource';

        $class =~ s/([a-z])([A-Z])/$1 . '_' . lc( $2 )/eg;
        $class = lc( $class );
        return "/${class}s/%s";
    },
);

has client => (
    is       => 'ro',
    isa      => sub {
        confess( "$_[0] is not a Business::GoCardless::Client" )
            if ref $_[0] ne 'Business::GoCardless::Client'
    },
    required => 1,
);

=head1 METHODS

=head2 find_with_client

Calls the gocardless API and populates the resource object with the data.

    my $Bill = Business::GoCardless::Bill->new( client => $self->client );
    $Bill->find_with_client;

=cut

sub find_with_client {
    my ( $self,$sub_key ) = @_;

    my $path = sprintf( $self->endpoint,$self->id );
    my $data = $self->client->api_get( $path );

    $data = $data->{$sub_key} if $sub_key;

    foreach my $attr ( keys( %{ $data } ) ) {
        # as per https://developer.gocardless.com/api-reference/#overview-backwards-compatibility
        #
        #     The following changes are considered backwards compatible
        #     "Adding new properties to the responses from existing API endpoints"
        #
        # so we need to be able to handle attributes we don't know about yet, hence the eval
        eval { $self->$attr( $data->{$attr} ); };
        $@ && do {
            carp( "Couldn't set $attr on @{[ ref( $self ) ]}: $_" );
        };
    }

    return $self;
}

sub _operation {
    my ( $self,$operation,$method,$params,$suffix ) = @_;

    $method //= 'api_post',

    my $uri = $operation
        ? sprintf( $self->endpoint,$self->id ) . "/$operation"
        : sprintf( $self->endpoint,$self->id );

    $uri .= "/$suffix" if $suffix;

    my $data = $self->client->$method( $uri,$params );

    if ( $self->client->api_version > 1 ) {

        $data = $data->{payments}
            if ref( $self ) eq 'Business::GoCardless::Payment';
        $data = $data->{subscriptions}
            if ref( $self ) eq 'Business::GoCardless::Subscription';
    }

    foreach my $attr ( keys( %{ $data } ) ) {
        eval { $self->$attr( $data->{$attr} ); };
        $@ && do {
            carp( "Couldn't set $attr on @{[ ref( $self ) ]}: $_" );
        };
    }

    return $self;
}

=head2 to_hash

Returns a hash representation of the object.

    my %data = $Bill->to_hash;

=head2 to_json

Returns a json string representation of the object.

    my $json = $Bill->to_json;

=cut

sub to_hash {
    my ( $self ) = @_;

    my %hash = %{ $self };
    delete( $hash{client} );
    return %hash;
}

sub to_json {
    my ( $self ) = @_;
    return JSON->new->canonical->encode( { $self->to_hash } );
}

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
