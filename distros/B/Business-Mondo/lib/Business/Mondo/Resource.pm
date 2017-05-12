package Business::Mondo::Resource;

=head1 NAME

Business::Mondo::Resource

=head1 DESCRIPTION

This is a base class for Mondo resource classes, it implements common
behaviour. You shouldn't use this class directly, but extend it instead.

=cut

use strict;
use warnings;

use Moo;
use Carp qw/ confess carp /;
use Mojo::JSON qw/ encode_json /;
use Scalar::Util qw/ blessed /;
use Try::Tiny;

=head1 ATTRIBUTES

The Resource class has the following attributes (with their type).

    client (Business::Mondo::Client) - REQUIRED
    url (Str)
    url_no_id (Str)

=cut

has client => (
    is       => 'ro',
    isa      => sub {
        confess( "$_[0] is not a Business::Mondo::Client" )
            if ref $_[0] ne 'Business::Mondo::Client';

        $Business::Mondo::Resource::client = $_[0];
    },
    required => 1,
);

has [ qw/ url / ] => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my ( $self ) = @_;
        join( '/',$self->url_no_id,$self->id )
    },
);

has [ qw/ url_no_id / ] => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my ( $self ) = @_;
        return join(
            '/',
            $self->client->api_url,
            lc( ( split( ':',ref( $self ) ) )[-1] ) . 's',
        );
    },
);

=head1 METHODS

=head2 to_hash

Returns a hash representation of the object.

    my %data = $transaction->to_hash;

=cut

sub to_hash {
    my ( $self ) = @_;

    my %hash = %{ $self };

    delete( $hash{client} );

    foreach my $currency_key ( qw/ currency local_currency / ) {
        if ( blessed( $hash{$currency_key} ) ) {
            $hash{$currency_key} = $hash{$currency_key}->code;
        }
    }

    foreach my $k ( keys %hash ) {
        if ( ref( $hash{$k} ) eq 'DateTime' ) {
            $hash{$k} = $hash{$k}->iso8601;
        } elsif ( my $blessed = blessed( $hash{$k} ) ) {
            next if $blessed =~ /Boolean/;
            $hash{$k} = { $hash{$k}->to_hash };
        }
    }

    return %hash;
}

=head2 as_json

Returns a json string representation of the object.

    my $json = $transaction->as_json;

=cut

sub as_json {
    my ( $self ) = @_;

    return encode_json( { $self->to_hash } );
}

# for JSON encoding modules (convert_blessed)
sub TO_JSON { shift->to_hash; }

=head2 get

Returns a new instance of the object populated with the attributes having called
the API

    my $populated_object = $object->get;

This is for when you have instantiated an object with the id, so calling the API
will retrieve the full details for the entity.

=cut

sub get {
    my ( $self,$sub_key ) = @_;

    my $data = $self->client->api_get( $self->url );
    $data = $data->{$sub_key} if $sub_key;

    return $self->new(
        client => $self->client,
        %{ $data },
    );
}

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/leejo/business-mondo

=cut

1;

# vim: ts=4:sw=4:et
