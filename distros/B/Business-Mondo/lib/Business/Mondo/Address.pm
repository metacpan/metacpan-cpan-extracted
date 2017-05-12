package Business::Mondo::Address;

=head1 NAME

Business::Mondo::Address

=head1 DESCRIPTION

A class for a Mondo address, extends L<Business::Mondo::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::Mondo::Resource';
with 'Business::Mondo::Utils';

use Types::Standard qw/ :all /;
use Business::Mondo::Address;
use Business::Mondo::Exception;

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
    Business::Mondo::Exception->throw({
        message => "Mondo API does not currently support getting address data",
    });
}

sub get {
    Business::Mondo::Exception->throw({
        message => "Mondo API does not currently support getting address data",
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
