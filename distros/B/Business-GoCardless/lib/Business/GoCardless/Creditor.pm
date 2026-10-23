package Business::GoCardless::Creditor;

=head1 NAME

Business::GoCardless::Creditor

=head1 DESCRIPTION

A class for a gocardless creditor, extends L<Business::GoCardless::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

=head1 ATTRIBUTES

    address_line1
    address_line2
    address_line3
    bank_reference_prefix
    can_create_refunds
    city
    country_code
    created_at
    creditor_type
    custom_payment_pages_enabled
    fx_payout_currency
    id
    links
    logo_url
    mandate_imports_enabled
    merchant_responsible_for_notifications
    name
    postal_code
    region
    scheme_identifiers
    verification_status

=cut

has [ qw/
    address_line1
    address_line2
    address_line3
    bank_reference_prefix
    can_create_refunds
    city
    country_code
    created_at
    creditor_type
    custom_payment_pages_enabled
    fx_payout_currency
    id
    links
    logo_url
    mandate_imports_enabled
    merchant_responsible_for_notifications
    name
    postal_code
    region
    scheme_identifiers
    verification_status
/ ] => (
    is => 'rw',
);

=head1 Operations on a creditor

=head2 update

Update the creditor:

    $Creditor->update( name => 'New name' );

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
