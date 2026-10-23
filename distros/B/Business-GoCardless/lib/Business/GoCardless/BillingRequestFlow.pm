package Business::GoCardless::BillingRequestFlow;

=head1 NAME

Business::GoCardless::BillingRequestFlow

=head1 DESCRIPTION

A class for a gocardless billing request flow, extends L<Business::GoCardless::Resource>

A Billing Request Flow is a hosted flow that the customer is sent to (the
C<authorisation_url>) to complete a L<Business::GoCardless::BillingRequest>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

=head1 ATTRIBUTES

    authorisation_url
    auto_fulfil
    created_at
    customer_details_captured
    exit_uri
    expires_at
    id
    language
    links
    lock_bank_account
    lock_currency
    lock_customer_details
    prefilled_bank_account
    prefilled_customer
    redirect_uri
    session_token
    show_redirect_buttons
    show_success_redirect_button
    skip_success_screen

=cut

has [ qw/
    authorisation_url
    auto_fulfil
    created_at
    customer_details_captured
    exit_uri
    expires_at
    id
    language
    links
    lock_bank_account
    lock_currency
    lock_customer_details
    prefilled_bank_account
    prefilled_customer
    redirect_uri
    session_token
    show_redirect_buttons
    show_success_redirect_button
    skip_success_screen
/ ] => (
    is => 'rw',
);

=head1 Operations on a billing request flow

=head2 initialise

Initialise the flow, returning it with a new C<session_token>:

    $Flow->initialise;

=cut

sub initialise { shift->_action( 'initialise',@_ ); }

=head1 AUTHOR

Lee Johnson - C<lee@payprop.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/payprop/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
