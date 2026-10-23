package Business::GoCardless::InstalmentSchedule;

=head1 NAME

Business::GoCardless::InstalmentSchedule

=head1 DESCRIPTION

A class for a gocardless instalment schedule, extends L<Business::GoCardless::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

=head1 ATTRIBUTES

    created_at
    currency
    id
    links
    metadata
    name
    payment_errors
    status
    total_amount

=cut

has [ qw/
    created_at
    currency
    id
    links
    metadata
    name
    payment_errors
    status
    total_amount
/ ] => (
    is => 'rw',
);

=head1 Operations on an instalment schedule

=head2 update

Update the instalment schedule's metadata:

    $Schedule->update( metadata => { ... } );

=head2 cancel

Cancel the instalment schedule, cancelling any payments not yet submitted:

    $Schedule->cancel;

=cut

sub update { shift->_update( @_ ); }
sub cancel { shift->_action( 'cancel',@_ ); }

=head1 Status checks on an instalment schedule

    pending
    active
    creation_failed
    completed
    cancelled
    errored

    if ( $InstalmentSchedule->pending ) {
        ...
    }

=cut

sub pending         { return ( shift->status // '' ) eq 'pending' }
sub active          { return ( shift->status // '' ) eq 'active' }
sub creation_failed { return ( shift->status // '' ) eq 'creation_failed' }
sub completed       { return ( shift->status // '' ) eq 'completed' }
sub cancelled       { return ( shift->status // '' ) eq 'cancelled' }
sub errored         { return ( shift->status // '' ) eq 'errored' }

=head1 Links

Shortcut methods to get the IDs of the linked resources

    mandate_id
    customer_id

=cut

sub mandate_id  { return ( shift->links // {} )->{mandate} }
sub customer_id { return ( shift->links // {} )->{customer} }

=head1 AUTHOR

Lee Johnson - C<lee@payprop.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/payprop/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
