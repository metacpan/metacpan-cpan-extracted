package Business::GoCardless::Bill;

=head1 NAME

Business::GoCardless::Bill

=head1 DESCRIPTION

A class for a gocardless bill, extends L<Business::GoCardless::Resource>

=cut

use strict;
use warnings;

use Moo;

extends 'Business::GoCardless::Resource';

=head1 ATTRIBUTES

    amount
    amount_minus_fees
    can_be_cancelled
    can_be_retried
    charge_customer_at
    created_at
    currency
    description
    gocardless_fees
    id
    is_setup_fee
    merchant_id
    name
    paid_at
    partner_fees
    payout_id
    source_id
    source_type
    status
    uri
    user_id

=cut

has [ qw/
    amount
    amount_minus_fees
    can_be_cancelled
    can_be_retried
    charge_customer_at
    created_at
    currency
    description
    gocardless_fees
    id
    is_setup_fee
    merchant_id
    name
    paid_at
    partner_fees
    payout_id
    source_id
    source_type
    status
    uri
    user_id
/ ] => (
    is => 'rw',
);

=head1 Operations on a bill

    retry
    cancel
    refund

    $Bill->retry if $Bill->failed;

=cut

sub retry  { shift->_operation( 'retry' ); }
sub cancel { shift->_operation( 'cancel','api_put' ); }
sub refund { shift->_operation( 'refund' ); }

=head1 Status checks on a bill

    pending
    paid
    failed
    chargedback
    cancelled
    withdrawn
    refunded

    if ( $Bill->failed ) {
        ...
    }

=cut

sub pending     { return shift->status eq 'pending' }
sub paid        { return shift->status eq 'paid' }
sub failed      { return shift->status eq 'failed' }
sub chargedback { return shift->status eq 'chargedback' }
sub cancelled   { return shift->status eq 'cancelled' }
sub withdrawn   { return shift->status eq 'withdrawn' }
sub refunded    { return shift->status eq 'refunded' }

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
