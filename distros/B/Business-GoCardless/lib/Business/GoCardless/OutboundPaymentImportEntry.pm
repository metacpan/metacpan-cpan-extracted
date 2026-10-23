package Business::GoCardless::OutboundPaymentImportEntry;

=head1 NAME

Business::GoCardless::OutboundPaymentImportEntry

=head1 DESCRIPTION

A class for a gocardless outbound payment import entry, extends L<Business::GoCardless::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

=head1 ATTRIBUTES

    amount
    created_at
    id
    links
    metadata
    processed_at
    reference
    scheme
    validation_errors
    verification_result

=cut

has [ qw/
    amount
    created_at
    id
    links
    metadata
    processed_at
    reference
    scheme
    validation_errors
    verification_result
/ ] => (
    is => 'rw',
);

has '+endpoint' => (
    default => sub { '/outbound_payment_import_entries/%s' },
);

=head1 AUTHOR

Lee Johnson - C<lee@payprop.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/payprop/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
