package DBIO::PostgreSQL::Adapter;
# ABSTRACT: PostgreSQL base->native type resolver

use strict;
use warnings;

our $VERSION = '0.900004';

use Carp qw/croak/;
use base 'DBIO::Adapter::Base';

use DBIO::PostgreSQL::Util qw(type_takes_modifier type_with_modifier);


my %NATIVE = (
  integer   => 'bigint',
  text      => 'text',
  boolean   => 'boolean',
  double    => 'double precision',
  blob      => 'bytea',
  timestamp => 'timestamptz',
);


sub to_native {
  my ($self, $col, $context) = @_;
  my $b = $col->{base_type};
  return type_with_modifier('character', $col->{size} // 255, $context) if $b eq 'char';
  if ($b eq 'numeric') {
    my ($p, $s) = @{$col}{qw/precision scale/};
    return type_with_modifier('numeric', defined $p ? [ $p, $s ] : undef, $context);
  }
  my $native = $NATIVE{$b} // croak "no PostgreSQL native type for base '$b'";
  return type_takes_modifier($native)
    ? type_with_modifier($native, $col->{size}, $context)
    : $native;
}

# capabilities inherited from DBIO::Adapter::Base: supports_alter_column_type => 1

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Adapter - PostgreSQL base->native type resolver

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Resolves a canonical column of L<DBIO::Schema::Type> -- one of the eight
portable base types -- to the PostgreSQL type it is deployed as:

  integer    bigint
  text       text
  char       character(size)       size defaults to 255
  boolean    boolean
  numeric    numeric, numeric(precision), numeric(precision,scale)
  double     double precision
  blob       bytea
  timestamp  timestamptz, timestamptz(size)

L<DBIO::PostgreSQL::DDL> asks it for every column declared with one of these
names, and L<DBIO::Schema::ModelCompiler> for every column of a schema it
compiles.

=head1 METHODS

=head2 to_native

    my $type = $adapter->to_native(\%canonical_column);

Returns the PostgreSQL type for a canonical column. A size is written where
the type takes a modifier, by the rule of
L<DBIO::PostgreSQL::Util/type_with_modifier>: the C<size> of a C<char>, the
C<precision> of a C<numeric> and its C<scale> beside it, and the C<size> of a
C<timestamp> -- its fractional seconds -- when the column carries one. A
C<size> on any other base type is not written; none of their native types
takes a modifier.

Throws for a base type that is none of the eight.

An optional second argument names the column (C<table.column>); a refused size
names it, as in L<DBIO::PostgreSQL::Util/type_with_modifier>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
