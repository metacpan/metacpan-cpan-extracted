package DBIx::Result::Convert::JSONSchema::Default::MySQL;

=head1 NAME

DBIx::Result::Convert::JSONSchema::Default::MySQL - Mapping of MySQL field type lengths

=head1 VERSION

    0.01

=head1 SYNOPSIS

    use DBIx::Result::Convert::JSONSchema::Default::MySQL;
    my $lenght_map = DBIx::Result::Convert::JSONSchema::Default::MySQL->get_length_map;

=head1 DESCRIPTION

This module defines default field lengths of MySQL database field types.

=cut

use strict;
use warnings;

our $VERSION = '0.01';

use Readonly;


Readonly my %LENGTH_MAP => (
    char       => [ 0, 1 ],
    varchar    => [ 0, 255 ],
    binary     => [ 0, 255 ],
    varbinary  => [ 0, 255 ],
    blob       => [ 0, 65_535 ],
    text       => [ 0, 65_535 ],
    mediumtext => [ 0, 16_777_215 ],
    tinytext   => [ 0, 255 ],
    date       => [ 10, 10 ],
    datetime   => [ 19, 19 ],
    timestamp  => [ 19, 19 ],
    time       => [ 8, 8 ],
    year       => [ 4, 4 ],
    integer    => {
        signed   => [ -2_147_483_648, 2_147_483_647 ],
        unsigned => [ 0,              4_294_967_295 ],
    },
    smallint   => {
        signed   => [ -32_768, 32_767 ],
        unsigned => [ 0,       65_535 ],
    },
    tinyint    => {
        signed   => [ -128, 127 ],
        unsigned => [ 0,    255 ],
    },
    mediumint  => {
        signed   => [ -8_388_608, 8_388_607  ],
        unsigned => [ 0,          16_777_215 ],
    },
    bigint     => {
        signed   => [ (2**63) * -1, (2**63) - 1 ],
        unsigned => [ 0,            (2**64) - 1 ],
    },
    bit        => {
        signed   => [ 0, 1 ],
        unsigned => [ 0, 1 ],
    },
);

=head2 C<get_length_map>

Static method on class that returns field length mapping.

    my $lenght_map = DBIx::Result::Convert::JSONSchema::Default::MySQL->get_length_map;

=cut

sub get_length_map { \%LENGTH_MAP }

=head1 AUTHOR

malishew - C<malishew@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation
or file a bug report then please raise an issue / pull request:

    https://github.com/Humanstate/p5-dbix-result-convert-jsonschema

=cut

1;
