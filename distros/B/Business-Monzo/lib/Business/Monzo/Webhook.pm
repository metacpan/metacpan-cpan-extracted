package Business::Monzo::Webhook;

=head1 NAME

Business::Monzo::Webhook

=head1 DESCRIPTION

A class for a Monzo webhook, extends L<Business::Monzo::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::Monzo::Resource';

use Types::Standard qw/ :all /;
use Business::Monzo::Exception;

=head1 ATTRIBUTES

The Webhook class has the following attributes (with their type).

    id (Str)
    callback_url (Str)
    account (Business::Monzo::Account)

Note that when a Str is passed to ->account this will be coerced
to a Business::Monzo::Account object.

=cut

has [ qw/ id callback_url / ] => (
    is  => 'ro',
    isa => Str,
);

has account => (
    is      => 'ro',
    isa     => InstanceOf['Business::Monzo::Account'],
    coerce  => sub {
        my ( $args ) = @_;

        if ( ! ref( $args ) ) {
            require Business::Monzo::Account;
            $args = Business::Monzo::Account->new(
                id     => $args,
                client => $Business::Monzo::Resource::client,
            );
        }

        return $args;
    },
);

=head1 Operations on an webhook

=head2 delete

Deletes a webhook

    $webhook->delete

=cut

sub delete {
    my ( $self ) = @_;
    return $self->client->api_delete( $self->url );
}

sub get {
    Business::Monzo::Exception->throw({
        message => "Monzo API does not currently support getting webhook data",
    });
}

=head1 SEE ALSO

L<Business::Monzo>

L<Business::Monzo::Resource>

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
