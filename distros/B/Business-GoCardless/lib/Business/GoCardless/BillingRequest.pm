package Business::GoCardless::BillingRequest;

=head1 NAME

Business::GoCardless::BillingRequest

=head1 DESCRIPTION

A class for a gocardless billing request, extends L<Business::GoCardless::Resource>

Billing Requests are the recommended way to collect payments and/or set up
mandates, replacing Redirect Flows. See
L<https://developer.gocardless.com/api-reference/#billing-requests-billing-requests>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

use Business::GoCardless::BillingRequestFlow;
use Business::GoCardless::Institution;

=head1 ATTRIBUTES

    actions
    auto_fulfil
    created_at
    creditor_address
    creditor_identifier
    creditor_name
    creditor_scheme_identifier
    experimentation
    fallback_enabled
    fallback_occurred
    id
    instalment_schedule_request
    links
    mandate_request
    metadata
    payment_context_code
    payment_purpose_code
    payment_request
    purpose_code
    resources
    sign_flow_url
    status
    subscription_request

=cut

has [ qw/
    actions
    auto_fulfil
    created_at
    creditor_address
    creditor_identifier
    creditor_name
    creditor_scheme_identifier
    experimentation
    fallback_enabled
    fallback_occurred
    id
    instalment_schedule_request
    links
    mandate_request
    metadata
    payment_context_code
    payment_purpose_code
    payment_request
    purpose_code
    resources
    sign_flow_url
    status
    subscription_request
/ ] => (
    is => 'rw',
);

=head1 Operations on a billing request

=head2 collect_customer_details

Collect the customer details (if not already known), takes C<customer> and
C<customer_billing_detail> hashrefs:

    $BillingRequest->collect_customer_details(
        customer => {
            email       => 'lee@example.com',
            given_name  => 'Lee',
            family_name => 'Johnson',
        },
        customer_billing_detail => {
            address_line1 => '1 Test Street',
            city          => 'London',
            postal_code   => 'E1 1AA',
            country_code  => 'GB',
        },
    );

=head2 collect_bank_account

Collect the customer's bank account details:

    $BillingRequest->collect_bank_account(
        account_holder_name => 'Lee Johnson',
        account_number      => '55779911',
        branch_code         => '200000',
        country_code        => 'GB',
    );

=head2 confirm_payer_details

Confirm the payer details have been collected (required for mandate requests):

    $BillingRequest->confirm_payer_details;

=head2 fulfil

Fulfil the billing request once it is C<ready_to_fulfil>, creating the payment
and/or mandate:

    $BillingRequest->fulfil;

=head2 cancel

Cancel the billing request, causing any billing request flows to expire:

    $BillingRequest->cancel;

=head2 notify

Notify the customer about the billing request:

    $BillingRequest->notify( notification_type => 'email' );

=head2 fallback

Trigger a fallback from Pay by Bank to direct debit (when C<fallback_enabled>):

    $BillingRequest->fallback;

=head2 choose_currency

Choose the currency of the billing request (when it supports multiple):

    $BillingRequest->choose_currency( currency => 'EUR' );

=head2 select_institution

Select the customer's bank (for Pay by Bank):

    $BillingRequest->select_institution(
        institution  => 'monzo',
        country_code => 'GB',
    );

=cut

sub collect_customer_details { shift->_action( 'collect_customer_details',@_ ); }
sub collect_bank_account     { shift->_action( 'collect_bank_account',@_ ); }
sub confirm_payer_details    { shift->_action( 'confirm_payer_details',@_ ); }
sub fulfil                   { shift->_action( 'fulfil',@_ ); }
sub cancel                   { shift->_action( 'cancel',@_ ); }
sub notify                   { shift->_action( 'notify',@_ ); }
sub fallback                 { shift->_action( 'fallback',@_ ); }
sub choose_currency          { shift->_action( 'choose_currency',@_ ); }
sub select_institution       { shift->_action( 'select_institution',@_ ); }

=head1 Status checks on a billing request

    pending
    ready_to_fulfil
    fulfilling
    fulfilled
    cancelled

    if ( $BillingRequest->pending ) {
        ...
    }

=cut

sub pending         { return ( shift->status // '' ) eq 'pending' }
sub ready_to_fulfil { return ( shift->status // '' ) eq 'ready_to_fulfil' }
sub fulfilling      { return ( shift->status // '' ) eq 'fulfilling' }
sub fulfilled       { return ( shift->status // '' ) eq 'fulfilled' }
sub cancelled       { return ( shift->status // '' ) eq 'cancelled' }

=head1 Flows and institutions

=head2 create_flow

Create a L<Business::GoCardless::BillingRequestFlow> for the billing request,
which provides the C<authorisation_url> to send the customer to:

    my $Flow = $BillingRequest->create_flow(
        redirect_uri => 'https://example.com/complete',
        exit_uri     => 'https://example.com/exit',
    );

    my $url = $Flow->authorisation_url;

=head2 institutions

Get a list of L<Business::GoCardless::Institution> objects for the billing
request, for use with L</select_institution>:

    my @institutions = $BillingRequest->institutions( country_code => 'GB' );

=head1 Links

Shortcut methods to get the IDs of the resources created by the billing request:

    customer_id
    mandate_id
    payment_id
    subscription_id
    instalment_schedule_id

=cut

sub create_flow {
    my ( $self,%params ) = @_;

    my $data = $self->client->api_post(
        '/billing_request_flows',
        { billing_request_flows => {
            %params,
            links => {
                %{ $params{links} // {} },
                billing_request => $self->id,
            },
        } },
    );

    return Business::GoCardless::BillingRequestFlow->new(
        client => $self->client,
        %{ $data->{billing_request_flows} },
    );
}

sub institutions {
    my ( $self,%filters ) = @_;

    my $uri = sprintf( $self->endpoint,$self->id ) . '/institutions';
    $uri .= '?' . $self->client->normalize_params( \%filters ) if keys %filters;

    my $data = $self->client->api_get( $uri );

    return map {
        Business::GoCardless::Institution->new( client => $self->client,%{ $_ } )
    } @{ $data->{institutions} // [] };
}

sub customer_id            { return shift->_link( 'customer' ) }
sub mandate_id             { return shift->_link( 'mandate_request_mandate' ) }
sub payment_id             { return shift->_link( 'payment_request_payment' ) }
sub subscription_id        { return shift->_link( 'subscription_request_subscription' ) }
sub instalment_schedule_id { return shift->_link( 'instalment_schedule_request_instalment_schedule' ) }

sub _link {
    my ( $self,$link ) = @_;
    return ( $self->links // {} )->{$link};
}

=head1 AUTHOR

Lee Johnson - C<lee@payprop.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/payprop/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
