package Business::TrueLayer::Webhook;

=head1 NAME

Business::TrueLayer::Webhook

=head1 SYNOPSIS

    my $Webhook = Business::TrueLayer::Webhook->new({
        jwt  => $jwt,
        jwks => $jwkset, # optional
    });


=head1 DESCRIPTION

A class for TrueLayer webhooks

For more details see the TreuLayer API documentation specific to webhooks:
https://docs.truelayer.com/docs/mandate-webhooks

=cut

use strict;
use warnings;
use feature qw/ signatures postderef /;

use Moose;
extends 'Business::TrueLayer::Request';
no warnings qw/ experimental::signatures experimental::postderef /;

use Business::TrueLayer::Webhook::Mandate;

use namespace::autoclean;

use JSON;
use Mojo::JWT;
use Mojo::UserAgent;
use Carp qw/ croak /;

=head1 ATTRIBUTES

=head2 jwt

The JWT as sent in the webhook by TrueLayer - this is required in the object
constructor as its signature will be validated and the payload will be used
to populate more data on the object.

=head2 jwkset

A JWKS used to validate the signature of the JWT. This can be provided as an
array reference of keys, however if not provide the jku in the JWT will be used
to download the JWKS.

=head2 jku_accept_list

A hashref of acceptable URLs that can provide the JWKS. Keyed by URL:

    {
        $url => 1,
        $alternative_url => 1,
    }

If the jku in the JWT is not amongst the keys of the jku_accept_list then an
exception will be thrown.

=cut

has jku_accept_list => (
    is => 'ro',
    isa => 'HashRef',
    required => 0,
    default => sub {
        return {
            'https://webhooks.truelayer-sandbox.com/.well-known/jwks' => 1,
            'https://webhooks.truelayer.com/.well-known/jwks' => 1,
        };
    },
);

has jwks => (
    is  => 'ro',
    isa => 'ArrayRef',
);

has jwt => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    trigger => sub {
        my ( $self,$jwt ) = @_;

        # we need to peek into the JWT to get the jku to:
        #    a) check it is limited to those on our accept list
        #    b) use it to get the JWKS
        #    c) which is then use by Mojo::JWT to check the signature
        my $peek = sub {
            my ( $jwt_instance,$claims ) = @_;

            if ( my $jku = $jwt_instance->header->{jku} ) {
                $self->jku_accept_list->{ $jku }
                    || croak( "$jku is not in the jku_accept_list" );

                # we're going to GET the jwks for every webhook?
                # this feels all sorts of wrong...
                my $jwkset = Mojo::UserAgent->new->get( $jku )
                    ->result->json;

                # add the jkws to the instance to allow it to check the signature
                $jwt_instance->add_jwkset( $jwkset );

                # we need to recall _try_jwks to set the public key from the jwkset
                # (internally Mojo::JWT calls peek after the call to _try_jwks)
                $jwt_instance->_try_jwks(
                    $jwt_instance->algorithm,
                    $jwt_instance->header
                );
            }
        };

        $self->_payload(
            Mojo::JWT->new( ( $self->jwks
                ? ( jwks => $self->jwks )
                : ()
            ) )->decode(
                $jwt,
                # if jwks is set we can bypass the peek that grabs it
                ( $self->jwks ? () : ( $peek ) )
            )
        );

        return $jwt;
    },
);

has _payload => (
    is  => 'rw',
    isa => 'HashRef',
);

=head1 Operations on a webhook

=head2 resource

Returns an object (Business::TrueLayer::Webhook::Payment, ...::Mandate, etc) that
the webhook is referring to allowing you to do things with it or update your own
data:

    if ( $Webhook->is_payment ) {
        my $Payment = $Webhook->resource;
        ...
    } elsif ( $Webhook->is_mandate ) {
        my $Mandate = $Webhook->resource;
        ...
    }

=cut

sub resource {
    my ( $self ) = @_;

    my $payload = $self->_payload;

    if ( $self->is_mandate ) {

        my $status = $payload->{type} =~ s/mandate_//r;

        return Business::TrueLayer::Webhook::Mandate->new({
            id => $payload->{mandate_id},
            status => $status,
        });
    }
}

=head2 is_payment

=head2 is_mandate

Shortcut methods to get the type of data in the webhook, and thus the type of
objects that will be returned by the call to ->resources

=cut

sub is_payment { shift->_is_type( 'payment' ) }
sub is_mandate { shift->_is_type( 'mandate' ) }

sub _is_type ( $self,$expected_type ) {

    my $type = $self->_payload->{type};
    return $type =~ /^${expected_type}_/ ? 1 : 0;
}

=head1 SEE ALSO

L<Business::TrueLayer::Webhook::Payment>

L<Business::TrueLayer::Webhook::Mandate>

=cut

1;

# vim: ts=4:sw=4:et
