package DBIO::SQLite::Diff::Table;
# ABSTRACT: Diff operations for SQLite tables

use strict;
use warnings;

use base 'DBIO::Diff::Op';

use DBIO::SQL::Util qw(_quote_ident);
use namespace::clean;


__PACKAGE__->mk_diff_accessors(qw/table_name table_info columns foreign_keys/);


sub diff {
  my ($class, $source, $target, $target_columns, $target_fks) = @_;
  $target_columns //= {};
  $target_fks     //= {};

  # The generic create/drop walk lives in DBIO::Diff::Op->diff_toplevel; we
  # only supply the SQLite-shaped ops (create captures target columns + FKs so
  # as_sql can render the full inline CREATE TABLE).
  return $class->diff_toplevel($source, $target,
    create => sub {
      my ($name) = @_;
      $class->new(
        action       => 'create',
        table_name   => $name,
        table_info   => $target->{$name},
        columns      => $target_columns->{$name} // [],
        foreign_keys => $target_fks->{$name}     // [],
      );
    },
    drop => sub {
      my ($name) = @_;
      $class->new(
        action     => 'drop',
        table_name => $name,
        table_info => $source->{$name},
      );
    },
  );
}


sub as_sql {
  my ($self) = @_;

  if ($self->action eq 'drop') {
    return sprintf 'DROP TABLE %s;', _quote_ident($self->table_name);
  }

  my @col_defs;
  my @pk_cols;

  for my $col (@{ $self->columns }) {
    push @pk_cols, $col->{column_name} if $col->{is_pk};

    my $type = $col->{data_type} // 'TEXT';
    my $def = sprintf '  %s %s', _quote_ident($col->{column_name}), $type;
    $def .= ' NOT NULL' if $col->{not_null};
    if (defined $col->{default_value}) {
      $def .= " DEFAULT $col->{default_value}";
    }
    push @col_defs, $def;
  }

  # Multi-column PK becomes a table-level constraint. Single-column INTEGER
  # PRIMARY KEY is left inline (it's already part of the column type
  # roundtrip via introspection -- pk=1 in the column metadata).
  if (@pk_cols > 1) {
    push @col_defs, sprintf '  PRIMARY KEY (%s)',
      join(', ', map { _quote_ident($_) } @pk_cols);
  }

  for my $fk (@{ $self->foreign_keys }) {
    push @col_defs, sprintf '  FOREIGN KEY (%s) REFERENCES %s(%s)',
      join(', ', map { _quote_ident($_) } @{ $fk->{from_columns} }),
      _quote_ident($fk->{to_table}),
      join(', ', map { _quote_ident($_) } @{ $fk->{to_columns} });
  }

  return sprintf "CREATE TABLE %s (\n%s\n);",
    _quote_ident($self->table_name), join(",\n", @col_defs);
}


sub summary {
  my ($self) = @_;
  my $prefix = $self->action eq 'create' ? '+' : '-';
  return sprintf '%s table: %s', $prefix, $self->table_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::Diff::Table - Diff operations for SQLite tables

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Represents a table-level diff operation in SQLite: C<CREATE TABLE> or
C<DROP TABLE>. Unlike PostgreSQL, where the table shell can be created
empty and columns added one at a time, SQLite is much friendlier when
the full table definition is emitted at once -- so for C<create>
operations the SQL is generated directly from the introspected target
columns (and any FKs / PK constraints) inline.

=head1 METHODS

=head2 diff

    my @ops = DBIO::SQLite::Diff::Table->diff(
        $source_tables, $target_tables,
        $target_columns, $target_fks,
    );

Compares two table hashrefs (keyed by table name) and returns C<create>
ops for tables present only in target and C<drop> ops for tables only in
source. C<create> ops capture the target columns and FKs so C<as_sql>
can render the full inline definition.

=head2 as_sql

Returns the SQL for this operation. For C<create>, emits a full
C<CREATE TABLE> with columns, primary key, and foreign keys inline. For
C<drop>, emits C<DROP TABLE>.

=head2 summary

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
