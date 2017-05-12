package Business::Monzo::Address;

=head1 NAME

Business::Monzo::Address

=head1 DESCRIPTION

A class for a Monzo address, extends L<Business::Monzo::Resource>

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

The Address class has the following attributes (with their type).

    address (Str)
    city (Str)
    country (Str)
    postcode (Str)
    region (Str)
    longitude (Num)
    latitude (Num)

=cut

has [ qw/ address city country postcode region / ] => (
    is  => 'ro',
    isa => Str,
);

has [ qw/ latitude longitude / ] => (
    is  => 'ro',
    isa => Num,
);

=head1 Operations on an address

None at present

=cut

sub url {
    Business::Monzo::Exception->throw({
        message => "Monzo API does not currently support getting address data",
    });
}

sub get {
    Business::Monzo::Exception->throw({
        message => "Monzo API does not currently support getting address data",
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
