package Business::GoCardless::SchemeIdentifier;

=head1 NAME

Business::GoCardless::SchemeIdentifier

=head1 DESCRIPTION

A class for a gocardless scheme identifier, extends L<Business::GoCardless::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

=head1 ATTRIBUTES

    address_line1
    address_line2
    address_line3
    can_specify_mandate_reference
    city
    country_code
    created_at
    currency
    email
    id
    minimum_advance_notice
    name
    phone_number
    postal_code
    reference
    region
    scheme
    status

=cut

has [ qw/
    address_line1
    address_line2
    address_line3
    can_specify_mandate_reference
    city
    country_code
    created_at
    currency
    email
    id
    minimum_advance_notice
    name
    phone_number
    postal_code
    reference
    region
    scheme
    status
/ ] => (
    is => 'rw',
);

=head1 Status checks on a scheme identifier

    pending
    active

    if ( $SchemeIdentifier->pending ) {
        ...
    }

=cut

sub pending { return ( shift->status // '' ) eq 'pending' }
sub active  { return ( shift->status // '' ) eq 'active' }

=head1 AUTHOR

Lee Johnson - C<lee@payprop.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/payprop/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
