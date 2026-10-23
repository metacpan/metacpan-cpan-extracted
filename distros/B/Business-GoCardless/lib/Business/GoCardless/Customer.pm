package Business::GoCardless::Customer;

=head1 NAME

Business::GoCardless::Customer

=head1 DESCRIPTION

A class for a gocardless user, extends L<Business::GoCardless::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

=head1 ATTRIBUTES

    created_at
    email
    id
    given_name
    family_name
    company_name
    address_line1
    address_line2
    address_line3
    city
    region
    postal_code
    country_code
    language
    phone_number
    swedish_identity_number
    danish_identity_number
    metadata

=cut

has [ qw/
    created_at
    email
    id
    given_name
    family_name
    company_name
    address_line1
    address_line2
    address_line3
    city
    region
    postal_code
    country_code
    language
    phone_number
    swedish_identity_number
    danish_identity_number
    metadata
/ ] => (
    is => 'rw',
);

=head1 Operations on a customer

=head2 update

Update the customer, returns the updated Customer object:

    $Customer->update( email => 'new@example.com',metadata => { ... } );

=head2 remove

Remove the customer, which removes all of their personal data. B<This cannot
be undone>, and the customer must not have any active mandates:

    $Customer->remove;

=cut

sub update { shift->_update( @_ ); }
sub remove { shift->_delete; }

# BACK COMPATIBILITY METHODS
sub first_name { shift->given_name; }
sub last_name  { shift->family_name; }

=head1 AUTHOR

Lee Johnson - C<lee@payprop.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/payprop/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
