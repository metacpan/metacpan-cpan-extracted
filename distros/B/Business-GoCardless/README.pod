package Business::GoCardless;

=head1 NAME

Business::GoCardless - Top level namespace for the Business::GoCardless
set of modules

=for html
<a href='https://travis-ci.org/Humanstate/business-gocardless?branch=master'><img src='https://travis-ci.org/Humanstate/business-gocardless.svg?branch=master' alt='Build Status' /></a>
<a href='https://coveralls.io/r/Humanstate/business-gocardless?branch=master'><img src='https://coveralls.io/repos/Humanstate/business-gocardless/badge.png?branch=master' alt='Coverage Status' /></a>

=head1 VERSION

0.31

=head1 DESCRIPTION

Business::GoCardless is a set of libraries for easy interface to the gocardless
payment service, they implement most of the functionality currently found
in the service's API documentation: https://developer.gocardless.com

Current missing functionality is partner account handling, but all resource
manipulation (Bill, Merchant, Payout etc) is handled along with webhooks and
the checking/generation of signature, nonce, param normalisation, and other
such lower level interface with the API.

=head1 Do Not Use This Module Directly

Read the below to find out why.

=head1 If You Are New To Business::GoCardless

You should go straight to L<Business::GoCardless::Pro> and start there. Do
B<NOT> use the L<Business::GoCardless::Basic> module for reasons stated below.

=head1 If You Are A Current User Of Business::GoCardless

You should read L<Business::GoCardless::Upgrading> as you will be using the
L<Business::GoCardless::Basic> module (via this module) and the API that
relates to (v1) will be swtiched off by GoCardless sometime in late 2017.

When GoCardless switch off the v1 API this dist will be updated to make this
module refer to the Pro module directly.

=cut

use strict;
use warnings;

use Moo;
use Carp qw/ confess /;

use Business::GoCardless::Client;
use Business::GoCardless::Webhook;

$Business::GoCardless::VERSION = '0.31';

has api_version => (
    is       => 'ro',
    required => 0,
    lazy     => 1,
    default  => sub { $ENV{GOCARDLESS_API_VERSION} // 1 },
);

has token => (
    is       => 'ro',
    required => 1,
);

has client_details => (
    is       => 'ro',
    isa      => sub {
        confess( "$_[0] is not a hashref" )
            if ref( $_[0] ) ne 'HASH';
    },
    required => 0,
    lazy     => 1,
    default  => sub {
        my ( $self ) = @_;
        return {
            api_version => $self->api_version,
        };
    },
);

has client => (
    is       => 'ro',
    isa      => sub {
        confess( "$_[0] is not a Business::GoCardless::Client" )
            if ref $_[0] ne 'Business::GoCardless::Client'
    },
    required => 0,
    lazy     => 1,
    default  => sub {
        my ( $self ) = @_;

        return Business::GoCardless::Client->new(
            %{ $self->client_details },
            token => $self->token,
            api_version => $self->api_version,
        );
    },
);


sub confirm_resource {
    my ( $self,%params ) = @_;
    return $self->client->_confirm_resource( \%params );
}

sub new_bill_url {
    my ( $self,%params ) = @_;
    return $self->client->_new_bill_url( \%params );
}

sub bill {
    my ( $self,$id ) = @_;

    if ( $self->client->api_version > 1 ) {
        return $self->payment( $id );
    } else {
        return $self->_generic_find_obj( $id,'Bill' );
    }
}

sub bills {
    my ( $self,%filters ) = @_;

    if ( $self->client->api_version > 1 ) {
        return $self->payments( %filters );
    } else {
        return $self->merchant( $self->client->merchant_id )
            ->bills( \%filters );
    }
}

sub merchant {
    my ( $self,$merchant_id ) = @_;

    $merchant_id //= $self->client->merchant_id;
    return Business::GoCardless::Merchant->new(
        client => $self->client,
        id     => $merchant_id
    );
}

sub payouts {
    my ( $self,%filters ) = @_;
    return $self->merchant( $self->client->merchant_id )
        ->payouts( \%filters );
}

sub payout {
    my ( $self,$id ) = @_;
    return $self->_generic_find_obj( $id,'Payout' );
}

sub new_pre_authorization_url {
    my ( $self,%params ) = @_;
    return $self->client->_new_pre_authorization_url( \%params );
}

sub pre_authorization {
    my ( $self,$id ) = @_;
    return $self->_generic_find_obj( $id,'PreAuthorization' );
}

sub pre_authorizations {
    my ( $self,%filters ) = @_;
    return $self->merchant( $self->client->merchant_id )
        ->pre_authorizations( \%filters );
}

sub new_subscription_url {
    my ( $self,%params ) = @_;
    return $self->client->_new_subscription_url( \%params );
}

sub subscription {
    my ( $self,$id ) = @_;
    return $self->_generic_find_obj( $id,'Subscription' );
}

sub subscriptions {
    my ( $self,%filters ) = @_;
    return $self->merchant( $self->client->merchant_id )
        ->subscriptions( \%filters );
}

sub users {
    my ( $self,%filters ) = @_;
    return $self->merchant( $self->client->merchant_id )
        ->users( \%filters );
}

sub webhook {
    my ( $self,$data ) = @_;

    return Business::GoCardless::Webhook->new(
        client => $self->client,
        json   => $data,
    );
}

sub _generic_find_obj {
    my ( $self,$id,$class,$sub_key ) = @_;
    $class = "Business::GoCardless::$class";
    my $obj = $class->new(
        id     => $id,
        client => $self->client
    );
    return $obj->find_with_client( $sub_key );
}

=head1 SEE ALSO

L<Business::GoCardless::Basic>

L<Business::GoCardless::Pro>

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

=head1 CONTRIBUTORS

grifferz - C<andy-github.com@strugglers.net>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
