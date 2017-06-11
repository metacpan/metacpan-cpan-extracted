package Business::GoCardless::PreAuthorization;

=head1 NAME

Business::GoCardless::PreAuthorization

=head1 DESCRIPTION

A class for a gocardless pre_authorization, extends L<Business::GoCardless::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

use Business::GoCardless::Bill;

=head1 ATTRIBUTES

    created_at
    currency
    description
    expires_at
    id
    interval_length
    interval_unit
    max_amount
    merchant_id
    name
    next_interval_start
    remaining_amount
    setup_fee
    status
    sub_resource_uris
    uri
    user_id

=cut

has [ qw/
    created_at
    currency
    description
    expires_at
    id
    interval_length
    interval_unit
    max_amount
    merchant_id
    name
    next_interval_start
    remaining_amount
    setup_fee
    status
    sub_resource_uris
    uri
    user_id
/ ] => (
    is => 'rw',
);

=head1 Operations on a pre_authorization

    bill

    my $Bill = $PreAuthorization->bill;

Creates a new bill, returning a L<Business::GoCardless::Bill> object.

    cancel

    $PreAuthorization->cancel;

Cancels a pre_authorization.

=cut

sub bill {
    my ( $self,%params ) = @_;

    if ( $self->client->api_version > 1 ) {

        my $post_data = {
            payments => {
                %params,
                links    => {
                    # $self here will be a RedirectFlow
                    mandate => $self->links->{mandate},
                },
            },
        };

        my $data = $self->client->api_post( "/payments",$post_data );

        return Business::GoCardless::Payment->new(
            client => $self->client,
            %{ $data->{payments} },
        );
    }

    my $data = $self->client->api_post(
        "/bills",
        {
            bill => {
                pre_authorization_id => $self->id,
                %params,
            }
        }
    );

    return Business::GoCardless::Bill->new(
        client => $self->client,
        %{ $data }
    );
}

sub cancel { shift->_operation( 'cancel','api_put' ); }

=head1 Status checks on a pre_authorization

    inactive
    active
    cancelled
    expired

    if ( $PreAuthorization->active ) {
        ...
    }

=cut

sub inactive  { return shift->status eq 'inactive' }
sub active    { return shift->status eq 'active' }
sub cancelled { return shift->status eq 'cancelled' }
sub expired   { return shift->status eq 'expired' }

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
