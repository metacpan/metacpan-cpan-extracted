package Business::GoCardless::OutboundPayment;

=head1 NAME

Business::GoCardless::OutboundPayment

=head1 DESCRIPTION

A class for a gocardless outbound payment, extends L<Business::GoCardless::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

=head1 ATTRIBUTES

    amount
    created_at
    currency
    description
    execution_date
    id
    is_withdrawal
    links
    metadata
    reference
    scheme
    status
    verifications

=cut

has [ qw/
    amount
    created_at
    currency
    description
    execution_date
    id
    is_withdrawal
    links
    metadata
    reference
    scheme
    status
    verifications
/ ] => (
    is => 'rw',
);

=head1 Operations on an outbound payment

=head2 update

Update the outbound payment's metadata:

    $OutboundPayment->update( metadata => { ... } );

=head2 approve

Approve the outbound payment:

    $OutboundPayment->approve;

=head2 cancel

Cancel the outbound payment (only possible before it is C<executing>):

    $OutboundPayment->cancel;

=cut

sub update  { shift->_update( @_ ); }
sub approve { shift->_action( 'approve',@_ ); }
sub cancel  { shift->_action( 'cancel',@_ ); }

=head1 Status checks on an outbound payment

    verifying
    pending_approval
    scheduled
    executing
    executed
    cancelled
    failed

    if ( $OutboundPayment->verifying ) {
        ...
    }

=cut

sub verifying        { return ( shift->status // '' ) eq 'verifying' }
sub pending_approval { return ( shift->status // '' ) eq 'pending_approval' }
sub scheduled        { return ( shift->status // '' ) eq 'scheduled' }
sub executing        { return ( shift->status // '' ) eq 'executing' }
sub executed         { return ( shift->status // '' ) eq 'executed' }
sub cancelled        { return ( shift->status // '' ) eq 'cancelled' }
sub failed           { return ( shift->status // '' ) eq 'failed' }

=head1 AUTHOR

Lee Johnson - C<lee@payprop.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/payprop/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
