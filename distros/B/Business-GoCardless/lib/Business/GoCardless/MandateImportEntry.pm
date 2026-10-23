package Business::GoCardless::MandateImportEntry;

=head1 NAME

Business::GoCardless::MandateImportEntry

=head1 DESCRIPTION

A class for a gocardless mandate import entry, extends L<Business::GoCardless::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

=head1 ATTRIBUTES

    created_at
    links
    processing_errors
    record_identifier

=cut

has [ qw/
    created_at
    links
    processing_errors
    record_identifier
/ ] => (
    is => 'rw',
);

has '+endpoint' => (
    default => sub { '/mandate_import_entries/%s' },
);

=head1 Links

Shortcut methods to get the IDs of the linked resources

    mandate_import_id
    mandate_id
    customer_id
    customer_bank_account_id

=cut

sub mandate_import_id        { return ( shift->links // {} )->{mandate_import} }
sub mandate_id               { return ( shift->links // {} )->{mandate} }
sub customer_id              { return ( shift->links // {} )->{customer} }
sub customer_bank_account_id { return ( shift->links // {} )->{customer_bank_account} }

=head1 AUTHOR

Lee Johnson - C<lee@payprop.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/payprop/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
