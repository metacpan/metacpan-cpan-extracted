package Business::Monzo::Account;

=head1 NAME

Business::Monzo::Account

=head1 DESCRIPTION

A class for a Monzo account, extends L<Business::Monzo::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::Monzo::Resource';
with 'Business::Monzo::Utils';

use Types::Standard qw/ :all /;
use Business::Monzo::Address;
use Business::Monzo::Balance;
use Business::Monzo::Webhook;
use Business::Monzo::Exception;

=head1 ATTRIBUTES

The Account class has the following attributes (with their type).

    id (Str)
    description (Str)
    created (DateTime)

Note that when a Str is passed to ->created this will be coerced
to a DateTime object.

=cut

has [ qw/ id / ] => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has [ qw/ description / ] => (
    is  => 'ro',
    isa => Str,
);

has created => (
    is      => 'ro',
    isa     => Maybe[InstanceOf['DateTime']],
    coerce  => sub {
        my ( $args ) = @_;

        if ( ! ref( $args ) ) {
            $args = DateTime::Format::DateParse->parse_datetime( $args );
        }

        return $args;
    },
);

=head1 Operations on an account

=cut

sub url {
    Business::Monzo::Exception->throw({
        message => "Monzo API does not currently support getting account data",
    });
}

sub get {
    Business::Monzo::Exception->throw({
        message => "Monzo API does not currently support getting account data",
    });
}

=head2 add_feed_item

Adds a feed item to the Account. Returns true on success, otherwise will throw
an error. Note the required parameters:

    $Account->add_feed_item(
        account_id => $id,   # defaults to $Account->id,
        type       => $type, # defaults to 'basic'
        url        => $url,  # optional, the URL to open when the item is tapped
        params => {
            title            => $title, # REQUIRED
            image_url        => $url,   # REQUIRED
            body             => $body_text, # optional
            background_color => $hex_value, # optional
            title_color      => $hex_value, # optional
            body_color       => $hex_value, # optional
        }
    );

=cut

sub add_feed_item {
    my ( $self,%params ) = @_;

    $params{params}{title} && $params{params}{image_url} ||
        Business::Monzo::Exception->throw({
            message => "add_feed_item requires params: title, image_url",
        });

    $params{account_id}  = $self->id;
    $params{type}      //= 'basic';

    # title -> params[title] (params, params, params, params, params... what a mess)
    $params{params}      = { $self->_params_as_array_string( 'params',$params{params} ) };

    my %post_params = (
        %{ delete $params{params} },
        %params,
    );

    return $self->client->api_post( 'feed',\%post_params );
}

=head2 register_webhook

Registers a webhook against the Account. Returns a Business::Monzo::Webhook
object. Note the required parameters:

    my $Webhook = $Account->webhooks(
        callback_url => 'https://www.example.com/monzo/callback' # REQUIRED
    );

=cut

sub register_webhook {
    my ( $self,%params ) = @_;

    $params{callback_url} || Business::Monzo::Exception->throw({
        message => "register_webhook requires params: callback_url",
    });

    my %post_params = (
        url        => $params{callback_url},
        account_id => $self->id,
    );

    my $data = $self->client->api_post( 'webhooks',\%post_params );

    return Business::Monzo::Webhook->new(
        client       => $self->client,
        id           => $data->{webhook}{id},
        callback_url => $data->{webhook}{url},
        account      => $self,
    );
}

=head2 webhooks

Returns a list of Business::Monzo::Webhook objects linked to the Account

    my @webhooks = $Account->webhooks

=cut

sub webhooks {
    my ( $self ) = @_;

    my $data = $self->client->api_get(
        'webhooks',{ account_id => $self->id }
    );

    my @webhooks;

    foreach my $webhook ( @{ $data->{webhooks} // [] } ) {

        push(
            @webhooks,
            Business::Monzo::Webhook->new(
                client       => $self->client,
                id           => $webhook->{id},
                callback_url => $webhook->{url},
                account      => $self,
            )
        );
    }

    return @webhooks;
}

=head2 transactions

Returns a list of L<Business::Monzo::Transaction> objects for the
account

    my @transactions = $Account->transactions( %query_params );

=cut

sub transactions {
    my ( $self,%params ) = @_;

    return $self->client->_get_transactions({
        %params,
        account_id => $self->id,
    });
}

=head2 balance

Returns a L<Business::Monzo::Balance> object for the account with the
attributes populated having called the Monzo API

    $Balance = $Account->balance;

=cut

sub balance {
    my ( $self ) = @_;

    return Business::Monzo::Balance->new(
        client     => $self->client,
        account_id => $self->id,
    )->get;
}

=head1 SEE ALSO

L<Business::Monzo>

L<Business::Monzo::Resource>

L<Business::Monzo::Balance>

L<Business::Monzo::Transaction>

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/leejo/business-monzo

=cut

1;

# vim: ts=4:sw=4:et
