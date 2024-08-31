package Business::TrueLayer;

=head1 NAME

Business::TrueLayer - Perl library for interacting with the TrueLayer v3 API
(https://docs.truelayer.com/)

=head1 VERSION

v0.04

=head1 SYNOPSIS

    my $TrueLayer = Business::TrueLayer->new(

        # required constructor arguments
        client_id     => $truelayer_client_id,
        client_secret => $truelauer_client_secret,
        kid           => $truelayer_kid,
        private_key   => '/path/to/private/key',

        # optional constructor arguments (with defaults)
        host          => 'truelayer.com',
        api_host      => 'api.truelayer.com',
        auth_host     => 'auth.truelayer.com',
    );

    # valid your setup (neither required in live usage):
    $TrueLayer->test_signature;
    my $access_token = $TrueLayer->access_token;

    # create a payment
    my $Payment = $TrueLayer->create_payment( $args );
    my $link    = $Payment->hosted_payment_page_link( $redirect_uri );

    # get status of a payment
    my $Payment = $TrueLayer->get_payment( $payment_id );

    if ( $Payment->settled ) {
        ...
    }

    # create a mandate, then create a payment
    my $Mandate = $TrueLayer->create_mandate( $args );

    if ( $Mandate->authorized ) {
        my $Payment = $TrueLayer->create_payment_from_mandate(
            $Mandate,$amount_in_minor_units
        );
    }

=head1 DESCRIPTION

L<Business::TrueLayer> is a client library for interacting with the
TrueLayer v3 API. It implementes the necesary signing and transport logic
to allow you to just focus on just the endpoints you want to call.

The initial version of this distribution supports just those steps that
described at L<https://docs.truelayer.com/docs/quickstart-make-a-payment>
and others will be added as necessary (pull requests also welcome).

=head1 DEBUGGING

Set C<MOJO_CLIENT_DEBUG=1> for user agent and transport debug output.

=cut

use strict;
use warnings;
use feature qw/ signatures postderef /;

use Moose;
extends 'Business::TrueLayer::Request';
no warnings qw/ experimental::signatures experimental::postderef /;

use namespace::autoclean;

use Business::TrueLayer::Authenticator;
use Business::TrueLayer::MerchantAccount;
use Business::TrueLayer::Mandate;
use Business::TrueLayer::Payment;
use Business::TrueLayer::Signer;
use Business::TrueLayer::Types;
use Business::TrueLayer::User;

$Business::TrueLayer::VERSION = '0.04';

=head1 METHODS

=head2 test_signature

Tests if your signature and signing is valid.

    $TrueLayer->test_signature;

Returns 1 on success, throws an exception otherwise.

=cut

sub test_signature ( $self ) {

    $self->api_post(
        '/test-signature',
        { nonce => "9f952b2e-1675-4be8-bb39-6f4343803c2f" },
        my $expect_json = 0,
    );

    return 1;
}

=head2 access_token

Get an access token.

    my $access_token = $TrueLayer->access_token;

Returns an access token on success, throws an exception otherwise.

=cut

sub access_token ( $self ) {
    return $self->authenticator->access_token;
}

=head2 merchant_accounts

Get a list of merchant accounts, C<$id> is optional to specifiy just one.

    my @merchant_accounts = $TrueLayer->merchant_accounts( $id );

Returns a list of L<Business::TrueLayer::MerchantAccount> objects.

=cut

sub merchant_accounts (
    $self,
    $id = undef
) {
    my $data = $self->api_get(
        "/v3/merchant-accounts" . ( $id ? "/$id" : "" )
    );

    my @merchants_accounts;

    foreach my $item ( $data->{items}->@* ) {
        push(
            @merchants_accounts,
            Business::TrueLayer::MerchantAccount->new( $item->%* ),
        );
    }

    return @merchants_accounts;
}

=head2 create_payment

Instantiates a L<Business::TrueLayer::Payment> object then calls the
API to create it - will return the object to allow you to inspect it
and call methods on it.

    my $Payment = $TrueLayer->create_payment( $args );

C<$args> should be a hash reference of the necessary attributes to
instantiate a L<Business::TrueLayer::Payment> object - see the perldoc
for that class for the attributes required.

Any issues here will result in an exception being thrown.

=cut

sub create_payment (
    $self,
    $payment_constuctor_args,
) {
    # instantiate an object first to perform type checking before
    # we send a request to the API
    Business::TrueLayer::Payment->new(
        $payment_constuctor_args->%*
    );

    # send request to the API
    my $response = $self->api_post(
        '/v3/payments',
        $payment_constuctor_args,
    );

    # return a new instance of the Payment object, with the original
    # args and the details from the response
    return Business::TrueLayer::Payment->new(
        $payment_constuctor_args->%*,

        $response->%{ qw / id status resource_token /},

        host => $self->host,
        payment_host => $self->payment_host,

        user => Business::TrueLayer::User->new(
            $payment_constuctor_args->{user}->%*,
            id => $response->{user}{id},
        ),
    );
}

=head2 get_payment

Calls the API to get the details for a payment for the given id then
instantiates a L<Business::TrueLayer::Payment> object for return to
the caller

    my $Payment = $TrueLayer->get_payment( $payment_id );

Any issues here will result in an exception being thrown.

=cut

sub get_payment (
    $self,
    $payment_id,
) {
    # send request to the API
    my $response = $self->api_get(
        '/v3/payments/' . $payment_id,
    );

    return Business::TrueLayer::Payment->new(
        $response->%*,
        host => $self->host,
        payment_host => $self->payment_host,
    );
}

=head2 create_mandate

Instantiates a L<Business::TrueLayer::Mandate> object then calls the
API to create it - will return the object to allow you to inspect it
and call methods on it.

    my $Mandate = $TrueLayer->create_mandate( $args );

C<$args> should be a hash reference of the necessary attributes to
instantiate a L<Business::TrueLayer::Mandate> object - see the perldoc
for that class for the attributes required.

Any issues here will result in an exception being thrown.

=cut

sub create_mandate (
    $self,
    $mandate_constuctor_args,
) {
    # instantiate an object first to perform type checking before
    # we send a request to the API
    Business::TrueLayer::Mandate->new(
        $mandate_constuctor_args,
    );

    # send request to the API
    my $response = $self->api_post(
        '/v3/mandates',
        $mandate_constuctor_args,
    );

    # return a new instance of the Payment object, with the original
    # args and the details from the response
    return Business::TrueLayer::Mandate->new({
        $mandate_constuctor_args->%*,

        $response->%{ qw / id status / },

        host => $self->host,
        payment_host => $self->payment_host,

        user => Business::TrueLayer::User->new(
            $mandate_constuctor_args->{user}->%*,
            id => $response->{user}{id},
        ),
    });
}

=head2 get_mandate

Calls the API to get the details for a mandate for the given id then
instantiates a L<Business::TrueLayer::Mandate> object for return to
the caller

    my $Mandate = $TrueLayer->get_mandate( $mandate_id );

Any issues here will result in an exception being thrown.

=cut

sub get_mandate (
    $self,
    $mandate_id,
) {
    # send request to the API
    my $response = $self->api_get(
        '/v3/mandates/' . $mandate_id,
    );

    return Business::TrueLayer::Mandate->new({
        $response->%*,
        host => $self->host,
        payment_host => $self->payment_host,
    });
}

=head2 create_payment_from_mandate

Returns a L<Business::TrueLayer::Payment> object after having called
the TrueLayer API for a particular mandate

    my $Payment = $TrueLayer->create_payment_from_mandate(
        $Mandate,
        $amount_in_minor_units,
    );

C<$Mandate> should be a Business::TrueLayer::Mandate object, and
C<$amount_in_minor_units> should be exactly that.

Any issues here will result in an exception being thrown.

=cut

sub create_payment_from_mandate (
    $self,
    $Mandate,
    $amount_in_minor_units,
) {
    my %request = (
        payment_method => {
            type => 'mandate',
            mandate_id   => $Mandate->id,
        },
        amount_in_minor => $amount_in_minor_units,
        currency => $Mandate->currency,
        user => { $Mandate->user->%* },
    );

    my $response = $self->api_post(
        '/v3/payments',
        \%request,
    );

    return Business::TrueLayer::Payment->new(
        $response->%{ qw / id status /},
        %request,

        host => $self->host,
        payment_host => $self->payment_host,
        user => Business::TrueLayer::User->new(
            $request{user}->%*,
            id => $response->{user}{id},
        ),
    );
}

1;

=head1 SEE ALSO

L<Business::TrueLayer::MerchantAccount>

L<Business::TrueLayer::Payment>

=head1 AUTHORS

Lee Johnson - C<leejo@cpan.org>

Nicholas Clark

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/payprop/business-truelayer

=cut

# vim: ts=4:sw=4:et
