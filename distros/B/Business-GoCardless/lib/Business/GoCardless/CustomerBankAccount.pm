package Business::GoCardless::CustomerBankAccount;

=head1 NAME

Business::GoCardless::CustomerBankAccount

=head1 DESCRIPTION

A class for a gocardless customer bank account, extends L<Business::GoCardless::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

=head1 ATTRIBUTES

    account_holder_name
    account_number_ending
    account_type
    bank_account_token
    bank_name
    country_code
    created_at
    currency
    enabled
    id
    links
    metadata
    payer_name_verification_result
    trusted_recipient

=cut

has [ qw/
    account_holder_name
    account_number_ending
    account_type
    bank_account_token
    bank_name
    country_code
    created_at
    currency
    enabled
    id
    links
    metadata
    payer_name_verification_result
    trusted_recipient
/ ] => (
    is => 'rw',
);

=head1 Operations on a customer bank account

=head2 update

Update the bank account's metadata:

    $BankAccount->update( metadata => { ... } );

=head2 disable

Disable the bank account, B<this immediately cancels all associated mandates
and cancellable payments>:

    $BankAccount->disable;

=cut

sub update  { shift->_update( @_ ); }
sub disable { shift->_action( 'disable',@_ ); }

=head1 Links

Shortcut methods to get the IDs of the linked resources

    customer_id

=cut

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
