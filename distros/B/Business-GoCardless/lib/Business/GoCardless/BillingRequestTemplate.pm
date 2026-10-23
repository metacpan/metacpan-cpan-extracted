package Business::GoCardless::BillingRequestTemplate;

=head1 NAME

Business::GoCardless::BillingRequestTemplate

=head1 DESCRIPTION

A class for a gocardless billing request template, extends L<Business::GoCardless::Resource>

A Billing Request Template provides a reusable C<authorisation_url> that
creates a new L<Business::GoCardless::BillingRequest> each time it is visited

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

=head1 ATTRIBUTES

    authorisation_url
    created_at
    id
    mandate_request_constraints
    mandate_request_currency
    mandate_request_description
    mandate_request_metadata
    mandate_request_scheme
    mandate_request_verify
    metadata
    name
    payment_request_amount
    payment_request_currency
    payment_request_description
    payment_request_metadata
    payment_request_scheme
    redirect_uri
    updated_at

=cut

has [ qw/
    authorisation_url
    created_at
    id
    mandate_request_constraints
    mandate_request_currency
    mandate_request_description
    mandate_request_metadata
    mandate_request_scheme
    mandate_request_verify
    metadata
    name
    payment_request_amount
    payment_request_currency
    payment_request_description
    payment_request_metadata
    payment_request_scheme
    redirect_uri
    updated_at
/ ] => (
    is => 'rw',
);

=head1 Operations on a billing request template

=head2 update

Update the template, this affects all future billing requests created from it:

    $Template->update( name => 'New name' );

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
