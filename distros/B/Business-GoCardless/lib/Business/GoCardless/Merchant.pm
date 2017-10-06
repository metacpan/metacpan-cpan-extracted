package Business::GoCardless::Merchant;

=head1 NAME

Business::GoCardless::Merchant

=head1 DESCRIPTION

A class for a gocardless merchant, extends L<Business::GoCardless::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

use Carp qw/ carp /;

use Business::GoCardless::Bill;
use Business::GoCardless::PreAuthorization;
use Business::GoCardless::Payout;
use Business::GoCardless::User;
use Business::GoCardless::Paginator;

=head1 ATTRIBUTES

    balance
    created_at
    description
    email
    eur_balance
    eur_pending_balance
    first_name
    gbp_balance
    gbp_pending_balance
    hide_variable_amount
    id
    last_name
    name
    next_payout_amount
    next_payout_date
    pending_balance
    sub_resource_uris
    uri

=cut

has [ qw/
    balance
    created_at
    description
    email
    eur_balance
    eur_pending_balance
    first_name
    gbp_balance
    gbp_pending_balance
    hide_variable_amount
    id
    last_name
    name
    next_payout_amount
    next_payout_date
    pending_balance
    sub_resource_uris
    uri
/ ] => (
    is => 'rw',
);

sub BUILD {
    my ( $self ) = @_;

    my $data = $self->client->api_get( sprintf( $self->endpoint,$self->id ) );

    foreach my $attr ( keys( %{ $data } ) ) {
        eval { $self->$attr( $data->{$attr} ); };
        $@ && do {
            carp( "Couldn't set $attr on @{[ ref( $self ) ]}: $@" );
        };
    }

    return $self;
}

=head1 List operations on a merchant

    bills
    pre_authorizations
    subscriptions
    payouts
    users

    my @bills = $Merchant->bills( \%filter );

Note that these methods marked have a dual interface, when called in list context
they will return the first 100 resource objects, when called in scalar context
they will return a L<Business::GoCardless::Paginator> object.

=cut

sub bills              { shift->_list( 'bills',shift ) }
sub pre_authorizations { shift->_list( 'pre_authorizations',shift )}
sub subscriptions      { shift->_list( 'subscriptions',shift ) }
sub payouts            { shift->_list( 'payouts',shift ) }
sub users              { shift->_list( 'users',shift ) }

sub _list {
    my ( $self,$endpoint,$filters ) = @_;

    my $class = {
        bills              => 'Bill',
        pre_authorizations => 'PreAuthorization',
        subscriptions      => 'Subscription',
        payouts            => 'Payout',
        users              => 'User',
    }->{ $endpoint };

    $filters             //= {};
    $filters->{per_page} ||= 100;
    $filters->{page}     ||= 1;

    my $uri = sprintf( $self->endpoint,$self->id ) . "/$endpoint";

    if ( keys( %{ $filters } ) ) {
        $uri .= '?' . $self->client->normalize_params( $filters );
    }

    my ( $data,$links,$info ) = $self->client->api_get( $uri );

    $class = "Business::GoCardless::$class";
    my @objects = map { $class->new( client => $self->client,%{ $_ } ) }
        @{ $data };

    return wantarray ? ( @objects ) : Business::GoCardless::Paginator->new(
        class   => $class,
        client  => $self->client,
        links   => $links,
        info    => $info ? JSON->new->decode( $info ) : {},
        objects => \@objects,
    );
}

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
