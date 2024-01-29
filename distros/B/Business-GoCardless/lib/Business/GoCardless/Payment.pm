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

=head1 ATTRIBUTES

    amount
    amount_refunded
    charge_date
    created_at
    currency
    description
    fx
    id
    links
    metadata
    reference
    retry_if_possible
    status

=cut

has [ qw/
    amount
    amount_refunded
    charge_date
    created_at
    currency
    description
    fx
    id
    links
    metadata
    reference
    retry_if_possible
    status
/ ] => (
    is => 'rw',
);

=head1 Operations on a payment

    retry
    cancel
    refund

    $Payment->retry if $Payment->failed;

=cut

sub retry  { shift->_operation( undef,'api_post',undef,'actions/retry' ); }
sub cancel { shift->_operation( undef,'api_post',undef,'actions/cancel' ); }
sub refund {
    # apparently this endpoint is restricted by default, so nuts to it for now
    return 0;
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
sub withdrawn   { return shift->status eq 'customer_appoval_denied' }
sub refunded    { return shift->status eq 'refunded' }
sub submitted   { return shift->status eq 'submitted' }
sub confirmed   { return shift->status eq 'confirmed' }

=head1 payout_id

=head1 mandate_id

=head1 creditor_id

Accessors for details found in the C<links> section

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

Lee Johnson - C<leejo@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
