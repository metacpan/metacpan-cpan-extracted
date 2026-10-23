package Business::GoCardless::Refund;

=head1 NAME

Business::GoCardless::Refund

=head1 DESCRIPTION

A class for a gocardless refund, extends L<Business::GoCardless::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

=head1 ATTRIBUTES

    amount
    created_at
    currency
    fx
    id
    links
    metadata
    reference
    status

=cut

has [ qw/
    amount
    created_at
    currency
    fx
    id
    links
    metadata
    reference
    status
/ ] => (
    is => 'rw',
);

=head1 Operations on a refund

=head2 update

Update the refund's metadata, returns the updated Refund object:

    $Refund->update( metadata => { ... } );

=cut

sub update { shift->_update( @_ ); }

=head1 Status checks on a refund

    created
    pending_submission
    submitted
    paid
    cancelled
    bounced
    funds_returned

    if ( $Refund->paid ) {
        ...
    }

=cut

sub created            { return shift->status eq 'created' }
sub pending_submission { return shift->status eq 'pending_submission' }
sub submitted          { return shift->status eq 'submitted' }
sub paid               { return shift->status eq 'paid' }
sub cancelled          { return shift->status eq 'cancelled' }
sub bounced            { return shift->status eq 'bounced' }
sub funds_returned     { return shift->status eq 'funds_returned' }

=head1 Links

    payment_id
    mandate_id

Shortcut methods to get the IDs of the linked resources

=cut

sub payment_id { return ( shift->links // {} )->{payment} }
sub mandate_id { return ( shift->links // {} )->{mandate} }

=head1 AUTHOR

Lee Johnson - C<lee@payprop.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/payprop/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
