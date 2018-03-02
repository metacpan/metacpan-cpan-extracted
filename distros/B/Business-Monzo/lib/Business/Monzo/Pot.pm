package Business::Monzo::Pot;

=head1 NAME

Business::Monzo::Pot

=head1 DESCRIPTION

A class for a Monzo pot, extends L<Business::Monzo::Resource>

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

The Pot class has the following attributes (with their type).

    id (Str)
    name (Str)
    style (Str)
    balance (Int)
    currency (Data::Currency)
    created (DateTime)
    updated (DateTime)
    deleted (Bool)

Note that when a Str is passed to ->currency this will be coerced to a
Data::Currency object,

=cut

has [ qw/ id name style / ] => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has [ qw/ balance / ] => (
    is  => 'ro',
    isa => Int,
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

has [ qw/ deleted / ] => (
    is  => 'ro',
    isa => Any,
);

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
