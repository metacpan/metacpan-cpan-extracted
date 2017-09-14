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

=head1 ATTRIBUTES

    id
    created_at
    action
    resource_type
    links
    details

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
	);
}

=head2 is_payment

=head2 is_subscription

=head2 is_payout

=head2 is_mandate

=head2 is_refund

Shortcut methods to get the type of data in the event, and thus the type of
objects that will be returned by the call to ->resources

=cut

sub is_payment      { return shift->resource_type eq 'payments' }
sub is_subscription { return shift->resource_type eq 'subscriptions' }
sub is_payout       { return shift->resource_type eq 'payouts' }
sub is_mandate      { return shift->resource_type eq 'mandates' }
sub is_refund       { return shift->resource_type eq 'refunds' }

# BACK COMPATIBILITY
sub is_pre_authorization { return shift->is_mandate }
sub is_bill              { return shift->is_payment }

1;

# vim: ts=4:sw=4:et
