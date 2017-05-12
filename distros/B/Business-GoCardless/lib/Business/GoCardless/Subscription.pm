package Business::GoCardless::Subscription;

=head1 NAME

Business::GoCardless::Subscription

=head1 DESCRIPTION

A class for a gocardless subscription, extends L<Business::GoCardless::Resource>

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
    expires_at
    id
    interval_length
    interval_unit
    merchant_id
    name
    next_interval_start
    setup_fee
    start_at
    status
    sub_resource_uris
    uri
    user_id

=cut

has [ qw/
    amount
    created_at
    currency
    description
    expires_at
    id
    interval_length
    interval_unit
    merchant_id
    name
    next_interval_start
    setup_fee
    start_at
    status
    sub_resource_uris
    uri
    user_id
/ ] => (
    is => 'rw',
);

=head1 Operations on a subscription

    cancel

    $Subscription->cancel

Cancels a subscription.

=cut

sub cancel { shift->_operation( 'cancel','api_put' ); }

=head1 Status checks on a subscription

    inactive
    active
    cancelled
    expired

    if ( $Subscription->active ) {
        ...
    }

=cut

sub inactive  { return shift->status eq 'inactive' }
sub active    { return shift->status eq 'active' }
sub cancelled { return shift->status eq 'cancelled' }
sub expired   { return shift->status eq 'expired' }

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
