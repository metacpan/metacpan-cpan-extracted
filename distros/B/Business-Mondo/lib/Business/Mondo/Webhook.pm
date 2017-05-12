package Business::Mondo::Webhook;

=head1 NAME

Business::Mondo::Webhook

=head1 DESCRIPTION

A class for a Mondo webhook, extends L<Business::Mondo::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::Mondo::Resource';

use Types::Standard qw/ :all /;
use Business::Mondo::Exception;

=head1 ATTRIBUTES

The Webhook class has the following attributes (with their type).

    id (Str)
    callback_url (Str)
    account (Business::Mondo::Account)

Note that when a Str is passed to ->account this will be coerced
to a Business::Mondo::Account object.

=cut

has [ qw/ id callback_url / ] => (
    is  => 'ro',
    isa => Str,
);

has account => (
    is      => 'ro',
    isa     => InstanceOf['Business::Mondo::Account'],
    coerce  => sub {
        my ( $args ) = @_;

        if ( ! ref( $args ) ) {
            require Business::Mondo::Account;
            $args = Business::Mondo::Account->new(
                id     => $args,
                client => $Business::Mondo::Resource::client,
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
    Business::Mondo::Exception->throw({
        message => "Mondo API does not currently support getting webhook data",
    });
}

=head1 SEE ALSO

L<Business::Mondo>

L<Business::Mondo::Resource>

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/leejo/business-mondo

=cut

1;

# vim: ts=4:sw=4:et
