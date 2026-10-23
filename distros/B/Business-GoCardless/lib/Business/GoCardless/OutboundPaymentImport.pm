package Business::GoCardless::OutboundPaymentImport;

=head1 NAME

Business::GoCardless::OutboundPaymentImport

=head1 DESCRIPTION

A class for a gocardless outbound payment import, extends L<Business::GoCardless::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

=head1 ATTRIBUTES

    amount_sum
    authorisation_url
    created_at
    currency
    entry_counts
    id
    links
    status

=cut

has [ qw/
    amount_sum
    authorisation_url
    created_at
    currency
    entry_counts
    id
    links
    status
/ ] => (
    is => 'rw',
);

=head1 Status checks on an outbound payment import

    created
    validating
    invalid
    valid
    processing
    processed
    cancelled

    if ( $OutboundPaymentImport->created ) {
        ...
    }

=cut

sub created    { return ( shift->status // '' ) eq 'created' }
sub validating { return ( shift->status // '' ) eq 'validating' }
sub invalid    { return ( shift->status // '' ) eq 'invalid' }
sub valid      { return ( shift->status // '' ) eq 'valid' }
sub processing { return ( shift->status // '' ) eq 'processing' }
sub processed  { return ( shift->status // '' ) eq 'processed' }
sub cancelled  { return ( shift->status // '' ) eq 'cancelled' }

=head1 AUTHOR

Lee Johnson - C<lee@payprop.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/payprop/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
