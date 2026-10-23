package Business::GoCardless::TransferredMandate;

=head1 NAME

Business::GoCardless::TransferredMandate

=head1 DESCRIPTION

A class for a gocardless transferred mandate, extends L<Business::GoCardless::Resource>

The encrypted updated customer bank details of a mandate that has been
transferred using the Current Account Switch Service. You will need to decrypt
these with your private key, see
L<https://developer.gocardless.com/api-reference/#mandates-transferred-mandate>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

=head1 ATTRIBUTES

    encrypted_customer_bank_details
    encrypted_decryption_key
    id
    links
    public_key_id

=cut

has [ qw/
    encrypted_customer_bank_details
    encrypted_decryption_key
    id
    links
    public_key_id
/ ] => (
    is => 'rw',
);

=head1 Links

Shortcut methods to get the IDs of the linked resources

    customer_bank_account_id
    mandate_id

=cut

sub customer_bank_account_id { return ( shift->links // {} )->{customer_bank_account} }
sub mandate_id               { return ( shift->links // {} )->{mandate} }

=head1 AUTHOR

Lee Johnson - C<lee@payprop.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/payprop/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
