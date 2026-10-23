package Business::GoCardless::BankAccountDetail;

=head1 NAME

Business::GoCardless::BankAccountDetail

=head1 DESCRIPTION

A class for a gocardless bank account detail, extends L<Business::GoCardless::Resource>

The encrypted bank account details of a customer bank account, as a flattened
JWE (RFC 7516). You will need to decrypt this with your private key, see
L<https://developer.gocardless.com/api-reference/#core-endpoints-bank-account-details>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

=head1 ATTRIBUTES

    ciphertext
    encrypted_key
    id
    iv
    protected
    tag

=cut

has [ qw/
    ciphertext
    encrypted_key
    id
    iv
    protected
    tag
/ ] => (
    is => 'rw',
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
