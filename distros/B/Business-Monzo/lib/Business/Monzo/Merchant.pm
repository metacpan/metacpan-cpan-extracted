package Business::Monzo::Merchant;

=head1 NAME

Business::Monzo::Merchant

=head1 DESCRIPTION

A class for a Monzo merchant, extends L<Business::Monzo::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::Monzo::Resource';
with 'Business::Monzo::Utils';

use Types::Standard qw/ :all /;
use Business::Monzo::Address;
use Business::Monzo::Exception;

=head1 ATTRIBUTES

The Merchant class has the following attributes (with their type).

    id (Str)
    group_id (Str)
    logo (Str)
    emoji (Str)
    name (Str)
    category (Str)
    online (Bool)
    atm (Bool)
    disable_feedback (Bool)
    address (Business::Monzo::Address)
    created (DateTime)
    updated (DateTime)
    metadata (HashRef)

Note that if a HashRef or Str is passed to ->address it will be coerced
into a Business::Monzo::Address object. When a Str is passed to ->created
or ->updated these will be coerced to a DateTime object.

=cut

has [ qw/ id group_id logo emoji name category / ] => (
    is  => 'ro',
    isa => Str,
);

has [ qw/ metadata / ] => (
    is  => 'ro',
    isa => HashRef,
);

has [ qw/ online atm disable_feedback / ] => (
    is  => 'ro',
    isa => Any,
);

has address => (
    is => 'ro',
    isa => Maybe[InstanceOf['Business::Monzo::Address']],
    coerce  => sub {

        my ( $args ) = @_;

        if ( ref ( $args ) eq 'HASH' ) {
            $args = Business::Monzo::Address->new(
                client => $Business::Monzo::Resource::client,
                %{ $args },
            );
        }

        return $args;
    },
);

has [ qw/ created updated / ] => (
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

=head1 Operations on an merchant

None at present

=cut

sub get {
    Business::Monzo::Exception->throw({
        message => "Monzo API does not currently support getting merchant data",
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
