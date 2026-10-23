package Business::GoCardless::Webhook::Event;

=head1 NAME

Business::GoCardless::Webhook::Event

=head1 DESCRIPTION

A class for gocardless webhook events, extends L<Business::GoCardless::Resource>.
For more details see the gocardless API documentation specific to webhooks:
https://developer.gocardless.com/api-reference/#appendix-webhooks

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';
with 'Business::GoCardless::Utils';

use Business::GoCardless::Exception;
use Business::GoCardless::Payment;
use Business::GoCardless::Subscription;
use Business::GoCardless::Mandate;
use Business::GoCardless::Payout;
use Business::GoCardless::Refund;
use Business::GoCardless::Customer;
use Business::GoCardless::BillingRequest;
use Business::GoCardless::Creditor;
use Business::GoCardless::InstalmentSchedule;
use Business::GoCardless::OutboundPayment;
use Business::GoCardless::SchemeIdentifier;
use Business::GoCardless::PaymentAccountTransaction;

=head1 ATTRIBUTES

    id
    created_at
    action
    resource_type
    links
    details
    metadata
    resource_metadata
    customer_notifications
    source

This class is used for events in webhooks, and for events from the events API
endpoints (see L<Business::GoCardless::Pro/events>).

=cut

has [ qw/
    id
    created_at
    action
    resource_type
    links
/ ] => (
    is       => 'ro',
	required => 1,
);

has [ qw/
    details
    metadata
    resource_metadata
    customer_notifications
    source
/ ] => (
    is       => 'rw',
	required => 0,
);

=head2 resources

Returns an array of resource objects (Payment, Subscription, etc) that are present
in the event allowing you to do things with them or update your own data:

    if ( $Event->is_payment ) {

        foreach my $Payment ( $Event->resources ) {

            if ( $Event->action eq 'paid_out' ) {
                ...
            }
        }
    }

=cut

sub resources {
	my ( $self ) = @_;

	return if ! $self->resource_type;

	my $mapping = {
		payments      => 'payment',
		payouts       => 'payout',
		subscriptions => 'subscription',
		mandates      => 'mandate',
		refunds       => 'refund',
		customers     => 'customer',
		billing_requests             => 'billing_request',
		creditors                    => 'creditor',
		instalment_schedules         => 'instalment_schedule',
		outbound_payments            => 'outbound_payment',
		scheme_identifiers           => 'scheme_identifier',
		payment_account_transactions => 'payment_account_transaction',
	};

	my $resource = $mapping->{ $self->resource_type };

	$resource || Business::GoCardless::Exception->throw({
		message => "Unknown resource_type (@{[$self->resource_type]}) in ->resources",
	});

	my $class_suffix = ucfirst( $resource );
	$class_suffix    =~ s/_([A-z])/uc($1)/ge;
	my $class = "Business::GoCardless::$class_suffix";

	return $class->new(
		client => $self->client,
		id     => $self->links->{ $resource },
        links  => $self->links,
	);
}

=pod

Shortcut methods to get the type of data in the event, and thus the type of
objects that will be returned by the call to ->resources

=head2 is_payment

True if the event is for payments

=head2 is_subscription

True if the event is for subscriptions

=head2 is_payout

True if the event is for payouts

=head2 is_mandate

True if the event is for mandates

=head2 is_refund

True if the event is for refunds

=head2 is_customer

True if the event is for customers

=head2 is_billing_request

True if the event is for billing requests

=head2 is_instalment_schedule

True if the event is for instalment schedules

=head2 is_creditor

True if the event is for creditors

=head2 is_outbound_payment

True if the event is for outbound payments

=cut

sub is_payment      { return shift->resource_type eq 'payments' }
sub is_subscription { return shift->resource_type eq 'subscriptions' }
sub is_payout       { return shift->resource_type eq 'payouts' }
sub is_mandate      { return shift->resource_type eq 'mandates' }
sub is_refund       { return shift->resource_type eq 'refunds' }
sub is_customer     { return shift->resource_type eq 'customers' }

sub is_billing_request     { return shift->resource_type eq 'billing_requests' }
sub is_instalment_schedule { return shift->resource_type eq 'instalment_schedules' }
sub is_creditor            { return shift->resource_type eq 'creditors' }
sub is_outbound_payment    { return shift->resource_type eq 'outbound_payments' }

# BACK COMPATIBILITY
sub is_pre_authorization { return shift->is_mandate }
sub is_bill              { return shift->is_payment }

1;

# vim: ts=4:sw=4:et
