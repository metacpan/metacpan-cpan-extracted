package DBIx::Result::Convert::JSONSchema::Type::MySQL;

=head1 NAME

DBIx::Result::Convert::JSONSchema::Type::MySQL - Mapping of MySQL field type to JSON property type

=head1 VERSION

    0.01

=head1 SYNOPSIS

    use DBIx::Result::Convert::JSONSchema::Type::MySQL;
    my $type_map = DBIx::Result::Convert::JSONSchema::Type::MySQL->get_type_map;

=head1 DESCRIPTION

This module defines mapping between DBIx MySQL field types to JSON schema property types.

=cut

use strict;
use warnings;

our $VERSION = '0.01';

use Readonly;


Readonly my %TYPE_MAP => (
    string  => [
        qw/ char varchar binary varbinary blob text mediumtext tinytext /,
        qw/ date datetime timestamp time year /
    ],
    enum    => [ qw/ enum set / ],
    integer => [ qw/ integer smallint tinyint mediumint bigint bit / ],
    number  => [ qw/ decimal float double /, 'double precision' ],
    object  => [ qw/ json / ],
);

=head2 C<get_type_map>

Return mapping of DBIx::Class:Result field name => JSON Schema field name.

    # { decimal => 'number', time => 'string', ... }
    my $map = DBIx::Result::Convert::Type::MySQL->get_type_map;

=cut

sub get_type_map {
    my ( $class ) = @_;

    my $mapped_fields;
    foreach my $json_type ( keys %TYPE_MAP ) {
        foreach my $dbix_type ( @{ $TYPE_MAP{ $json_type } } ) {
            $mapped_fields->{ $dbix_type } = $json_type;
        }
    }

    return $mapped_fields;
}

=head1 AUTHOR

malishew - C<malishew@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation
or file a bug report then please raise an issue / pull request:

    https://github.com/Humanstate/p5-dbix-result-convert-jsonschema

=cut

1;
