package Business::GoCardless::BankAuthorisation;

=head1 NAME

Business::GoCardless::BankAuthorisation

=head1 DESCRIPTION

A class for a gocardless bank authorisation, extends L<Business::GoCardless::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

=head1 ATTRIBUTES

    authorisation_type
    authorised_at
    created_at
    expires_at
    id
    last_visited_at
    links
    qr_code_url
    redirect_uri
    url

=cut

has [ qw/
    authorisation_type
    authorised_at
    created_at
    expires_at
    id
    last_visited_at
    links
    qr_code_url
    redirect_uri
    url
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
