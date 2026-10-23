package Business::GoCardless::BankAccountHolderVerification;

=head1 NAME

Business::GoCardless::BankAccountHolderVerification

=head1 DESCRIPTION

A class for a gocardless bank account holder verification, extends L<Business::GoCardless::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

=head1 ATTRIBUTES

    actual_account_name
    id
    result
    status
    type

=cut

has [ qw/
    actual_account_name
    id
    result
    status
    type
/ ] => (
    is => 'rw',
);

=head1 Status checks on a bank account holder verification

    pending
    completed

    if ( $BankAccountHolderVerification->pending ) {
        ...
    }

=cut

sub pending   { return ( shift->status // '' ) eq 'pending' }
sub completed { return ( shift->status // '' ) eq 'completed' }

=head1 AUTHOR

Lee Johnson - C<lee@payprop.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/payprop/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
