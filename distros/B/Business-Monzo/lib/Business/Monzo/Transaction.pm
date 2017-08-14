package Business::Monzo::Transaction;

=head1 NAME

Business::Monzo::Transaction

=head1 DESCRIPTION

A class for a Monzo transaction, extends L<Business::Monzo::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::Monzo::Resource';
with 'Business::Monzo::Utils';
with 'Business::Monzo::Currency';

use Types::Standard qw/ :all /;
use Business::Monzo::Merchant;
use Business::Monzo::Attachment;
use DateTime::Format::DateParse;
use Locale::Currency::Format;

=head1 ATTRIBUTES

The Transaction class has the following attributes (with their type).

    id (Str)
    account_id (Str)
    category (Str)
    dedupe_id (Str)
    description (Str)
    notes (Str)
    scheme (Str)
    account_balance (Int)
    amount (Int)
    local_amount (Int)
    counterparty (HashRef)
    metadata (HashRef)
    is_load (Bool)
    originator (Bool)
    merchant (Business::Monzo::Merchant)
    currency (Data::Currency)
    local_currency (Data::Currency)
    created (DateTime)
    updated (DateTime)
    settled (DateTime)
    attachments (ArrayRef[Business::Monzo::Attachment])

Note that if a HashRef or Str is passed to ->merchant it will be coerced
into a Business::Monzo::Merchant object. When a Str is passed to ->currency
/ ->local_currency this will be coerced to a Data::Currency object, and
when a Str is passed to ->created / ->updated / ->settled this will be
coerced to a DateTime object.

=cut

has [ qw/
    id account_id category dedupe_id description notes scheme
/ ] => (
    is  => 'ro',
    isa => Str,
);

has [ qw/ account_balance amount local_amount / ] => (
    is  => 'ro',
    isa => Int,
);

has [ qw/ counterparty metadata / ] => (
    is  => 'ro',
    isa => HashRef,
);

has [ qw/ is_load originator / ] => (
    is  => 'ro',
    isa => Any,
);

has merchant => (
    is      => 'ro',
    isa     => Maybe[InstanceOf['Business::Monzo::Merchant']],
    coerce  => sub {
        my ( $args ) = @_;

        return undef if ! defined $args;

        if ( ref( $args ) eq 'HASH' ) {
            return undef if ! keys %{ $args };
            $args = Business::Monzo::Merchant->new(
                client => $Business::Monzo::Resource::client,
                %{ $args },
            );
        } elsif ( ! ref( $args ) ) {
            $args = Business::Monzo::Merchant->new(
                client => $Business::Monzo::Resource::client,
                id     => $args,
            );
        }

        return $args;
    },
);

has attachments => (
    is      => 'ro',
    isa     => Maybe[ArrayRef[InstanceOf['Business::Monzo::Attachment']]],
    coerce  => sub {
        my ( $args ) = @_;

        return undef if ! defined $args;

        my @attachments;

        foreach my $attachment ( @{ $args } ) {
            push( @attachments,Business::Monzo::Attachment->new(
                client => $Business::Monzo::Resource::client,
                %{ $attachment },
            ) );
        }

        return [ @attachments ];
    },
);

has [ qw/ created updated settled / ] => (
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

=head1 Operations on an transaction

=head2 get

Returns a new instance of the object populated with the attributes having called
the API

    my $populated_transaction = $transaction->get;

This is for when you have instantiated an object with the id, so calling the API
will retrieve the full details for the entity.

=cut

sub get {
    shift->SUPER::get( 'transaction' );
}

=head2 annotate

Returns a new instance of the object with annotated data having called the API

    my $annotated_transaction = $transaction->annotate(
        foo => "bar",
        baz => "boz,
    );

=cut

sub annotate {
    my ( $self,%annotations ) = @_;

    %annotations = $self->_params_as_array_string( 'metadata',\%annotations );

    my $data = $self->client->api_patch( $self->url,\%annotations );
    $data = $data->{transaction};

    return $self->new(
        client => $self->client,
        %{ $data },
    );
}

sub annotations {
    return shift->metadata;
}

sub BUILD {
    my ( $self,$args ) = @_;

    foreach my $c ( 'local_','' ) {

        my $amount_accessor   = "${c}amount";
        my $currency_accessor = "${c}currency";

        if ( my $amount = $self->$amount_accessor ) {
            # not all currencies have sub units, so default to 0 for exponent
            my $decimal_precision = decimal_precision( $self->$currency_accessor->code ) // 0;
            my $value = $amount / ( 10 ** $decimal_precision );
            $self->$currency_accessor->value( $value );
        }
    }

};

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
