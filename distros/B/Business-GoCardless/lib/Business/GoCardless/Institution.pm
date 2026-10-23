package Business::GoCardless::Institution;

=head1 NAME

Business::GoCardless::Institution

=head1 DESCRIPTION

A class for a gocardless institution, extends L<Business::GoCardless::Resource>

An institution (bank) for use with Pay by Bank billing requests

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

=head1 ATTRIBUTES

    autocompletes_collect_bank_account
    country_code
    icon_url
    id
    limits
    logo_url
    name
    roles
    status

=cut

has [ qw/
    autocompletes_collect_bank_account
    country_code
    icon_url
    id
    limits
    logo_url
    name
    roles
    status
/ ] => (
    is => 'rw',
);

=head1 Status checks on an institution

    enabled
    disabled
    temporarily_disabled

    if ( $Institution->enabled ) {
        ...
    }

=cut

sub enabled              { return ( shift->status // '' ) eq 'enabled' }
sub disabled             { return ( shift->status // '' ) eq 'disabled' }
sub temporarily_disabled { return ( shift->status // '' ) eq 'temporarily_disabled' }

=head1 AUTHOR

Lee Johnson - C<lee@payprop.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/payprop/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
