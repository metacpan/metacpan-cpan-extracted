package Business::GoCardless::CreditorBankAccount;

=head1 NAME

Business::GoCardless::CreditorBankAccount

=head1 DESCRIPTION

A class for a gocardless creditor bank account, extends L<Business::GoCardless::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

=head1 ATTRIBUTES

    account_holder_name
    account_number_ending
    account_type
    bank_name
    country_code
    created_at
    currency
    enabled
    id
    links
    metadata
    verification_status

=cut

has [ qw/
    account_holder_name
    account_number_ending
    account_type
    bank_name
    country_code
    created_at
    currency
    enabled
    id
    links
    metadata
    verification_status
/ ] => (
    is => 'rw',
);

=head1 Operations on a creditor bank account

=head2 disable

Disable the bank account, no money can be paid out to a disabled account:

    $BankAccount->disable;

=cut

sub disable { shift->_action( 'disable',@_ ); }

=head1 Links

Shortcut methods to get the IDs of the linked resources

    creditor_id

=cut

sub creditor_id { return ( shift->links // {} )->{creditor} }

=head1 AUTHOR

Lee Johnson - C<lee@payprop.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/payprop/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
