package Business::GoCardless::Payout;

=head1 NAME

Business::GoCardless::Payout

=head1 DESCRIPTION

A class for a gocardless payout, extends L<Business::GoCardless::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

=head1 ATTRIBUTES

    amount
    arrival_date
    created_at
    currency
    deducted_fees
    fx
    id
    links
    metadata
    payout_type
    reference
    status
    tax_currency

=cut

# app_ids, bank_reference, paid_at, and transaction_fees relate to the
# legacy (v1) basic API

has [ qw/
    app_ids
    bank_reference
    paid_at
    transaction_fees

    amount
    arrival_date
    created_at
    currency
    deducted_fees
    fx
    id
    links
    metadata
    payout_type
    reference
    status
    tax_currency
/ ] => (
    is => 'rw',
);

=head1 Status checks on a payout

    pending
    paid
    bounced

    if ( $Payout->paid ) {
        ...
    }

=cut

sub pending     { return shift->status eq 'pending' }
sub paid        { return shift->status eq 'paid' }
sub bounced     { return shift->status eq 'bounced' }

=head1 Operations on a payout

=head2 update

Update the payout's metadata (Pro API only), returns the updated Payout object:

    $Payout->update( metadata => { ... } );

=cut

sub update { shift->_update( @_ ); }

=head1 AUTHOR

Lee Johnson - C<lee@payprop.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/payprop/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
