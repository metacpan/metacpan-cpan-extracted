package Business::GoCardless::Payment;

=head1 NAME

Business::GoCardless::Payment

=head1 DESCRIPTION

A class for a gocardless payment, extends L<Business::GoCardless::Resource>

=cut

use strict;
use warnings;

use Moo;

extends 'Business::GoCardless::Resource';

use Business::GoCardless::Exception;
use Business::GoCardless::Refund;

=head1 ATTRIBUTES

    amount
    amount_refunded
    charge_date
    created_at
    currency
    description
    faster_ach
    fx
    id
    links
    metadata
    reference
    retry_if_possible
    scheme
    status

=cut

has [ qw/
    amount
    amount_refunded
    charge_date
    created_at
    currency
    description
    faster_ach
    fx
    id
    links
    metadata
    reference
    retry_if_possible
    scheme
    status
/ ] => (
    is => 'rw',
);

=head1 Operations on a payment

    retry
    cancel
    update
    refund

    $Payment->retry if $Payment->failed;

retry and cancel optionally take metadata:

    $Payment->cancel( metadata => { ... } );

=head2 update

Update the payment's metadata and/or retry_if_possible, returns the updated
Payment object:

    $Payment->update( metadata => { ... },retry_if_possible => 1 );

=head2 refund

Create a refund against the payment, returns a L<Business::GoCardless::Refund>
object. Note that refunds are restricted by default on GoCardless accounts and
must be enabled by GoCardless support before this will work.

    my $Refund = $Payment->refund(
        amount                    => 100,           # required
        total_amount_confirmation => 100,           # defaults to amount_refunded + amount
        reference                 => 'REFUND001',   # optional
        metadata                  => { ... },       # optional
    );

total_amount_confirmation is a safety check used by GoCardless to prevent
accidental duplicate refunds - it is the total amount refunded on the payment
once this refund is applied. If the payment object is stale (i.e. another refund
has since been made) then GoCardless will reject the refund.

=cut

sub retry  { shift->_action( 'retry',@_ ); }
sub cancel { shift->_action( 'cancel',@_ ); }
sub update { shift->_update( @_ ); }

sub refund {
    my ( $self,%params ) = @_;

    # no default for the amount, we don't want to refund anything by accident
    Business::GoCardless::Exception->throw({
        message => "amount is required for ->refund",
    }) if ! defined( $params{amount} );

    my $already_refunded = $self->amount_refunded // 0;
    my $amount = $params{amount};

    my $data = $self->client->api_post(
        '/refunds',
        {
            refunds => {
                %params,
                amount                    => $amount,
                total_amount_confirmation => $params{total_amount_confirmation}
                    // ( $already_refunded + $amount ),
                links                     => {
                    %{ $params{links} // {} },
                    payment => $self->id,
                },
            },
        },
    );

    return Business::GoCardless::Refund->new(
        client => $self->client,
        %{ $data->{refunds} },
    );
}

=head1 Status checks on a payment

    pending
    paid
    failed
    chargedback
    cancelled
    withdrawn
    refunded
    submitted
    confirmed

    if ( $Payment->failed ) {
        ...
    }

=cut

sub pending     { return shift->status =~ /pending/ }
sub paid        { return shift->status eq 'paid_out' }
sub failed      { return shift->status eq 'failed' }
sub chargedback { return shift->status eq 'charged_back' }
sub cancelled   { return shift->status eq 'cancelled' }
sub withdrawn   { return shift->status eq 'customer_approval_denied' }
sub refunded    { return shift->status eq 'refunded' }
sub submitted   { return shift->status eq 'submitted' }
sub confirmed   { return shift->status eq 'confirmed' }

=head1 Links

Accessors for details found in the C<links> section

=head2 payout_id

The ID of the payout the payment was paid out in

=head2 mandate_id

The ID of the mandate the payment was collected against

=head2 creditor_id

The ID of the creditor receiving the payment

=cut

sub payout_id   { return shift->_link_content( 'payout' ) }
sub mandate_id  { return shift->_link_content( 'mandate' ) }
sub creditor_id { return shift->_link_content( 'creditor' ) }

sub _link_content {
    my ( $self,$attr ) = @_;
    my $links = $self->links || {};
    return $links->{$attr};
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
