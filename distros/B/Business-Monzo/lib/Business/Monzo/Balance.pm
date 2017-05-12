package Business::Monzo::Balance;

=head1 NAME

Business::Monzo::Balance

=head1 DESCRIPTION

A class for a Monzo balance, extends L<Business::Monzo::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::Monzo::Resource';
with 'Business::Monzo::Utils';
with 'Business::Monzo::Currency';

use Types::Standard qw/ :all /;
use Business::Monzo::Merchant;
use DateTime::Format::DateParse;

=head1 ATTRIBUTES

The Balance class has the following attributes (with their type).

    account_id (Str)
    balance (Int)
    spend_today (Int)
    currency (Data::Currency)

Note that when a Str is passed to ->currency this will be coerced to a
Data::Currency object,

=cut

has [ qw/ account_id / ] => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has [ qw/ balance spend_today / ] => (
    is  => 'ro',
    isa => Int,
);

has [ qw/ url / ] => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my ( $self ) = @_;
        return $self->client->api_url . '/balance?account_id=' . $self->account_id;
    },
);

=head1 Operations on an transaction

=head2 get

Returns a new instance of the object with the attributes populated
having called the Monzo API

    $Balance = $Balance->get;

=cut

sub get {
    my ( $self ) = @_;

    my $data = $self->client->api_get(
        'balance?account_id=' . $self->account_id
    );

    return $self->new(
        account_id => $self->account_id,
        client     => $self->client,
        %{ $data },
    );
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
