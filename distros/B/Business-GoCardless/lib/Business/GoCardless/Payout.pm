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

Note that app_ids, bank_reference, paid_at, and transaction_fees relate to the
legacy (v1) basic API. These will be removed after the legacy API has been
switched off

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
    payout_type
    reference
    status

=cut

# TODO: remove legacy attributes

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
    payout_type
    reference
    status
/ ] => (
    is => 'rw',
);

=head1 Status checks on a payout

    pending
    paid

    if ( $Payout->paid ) {
        ...
    }

=cut

sub pending     { return shift->status eq 'pending' }
sub paid        { return shift->status eq 'paid' }

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
