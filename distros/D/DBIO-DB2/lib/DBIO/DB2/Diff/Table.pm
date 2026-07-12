package DBIO::DB2::Diff::Table;
# ABSTRACT: Diff operations for DB2 tables

use strict;
use warnings;

use base 'DBIO::Diff::Op';

use DBIO::DB2::Type qw(_db2_column_type);
use DBIO::SQL::Util qw(_quote_ident);
use DBIO::DB2::DDL qw(_fk_constraint_clause);


__PACKAGE__->mk_diff_accessors(qw/table_name table_info columns foreign_keys/);


sub diff {
  my ($class, $source, $target, $target_columns, $target_fks) = @_;
  $target_columns //= {};
  $target_fks     //= {};

  my @ops;

  for my $name (sort keys %$target) {
    next if exists $source->{$name};
    push @ops, $class->new(
      action       => 'create',
      table_name   => $name,
      table_info   => $target->{$name},
      columns      => $target_columns->{$name} // [],
      foreign_keys => $target_fks->{$name}     // [],
    );
  }

  for my $name (sort keys %$source) {
    next if exists $target->{$name};
    push @ops, $class->new(
      action     => 'drop',
      table_name => $name,
      table_info => $source->{$name},
    );
  }

  return @ops;
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

    my $type = _db2_column_type($col->{data_type}, $col->{size});
    my $def = sprintf '  %s %s', _quote_ident($col->{column_name}), $type;
    $def .= ' NOT NULL' if $col->{not_null};
    if (defined $col->{default_value}) {
      $def .= " DEFAULT $col->{default_value}";
    }
    push @col_defs, $def;
  }

  if (@pk_cols) {
    push @col_defs, sprintf '  PRIMARY KEY (%s)',
      join(', ', map { _quote_ident($_) } @pk_cols);
  }

  # Named inline FK constraints, rendered through the same shared clause builder
  # as DBIO::DB2::DDL->install_ddl so a table created via the diff apply/upgrade
  # path gets the deterministic fk_<table>_<cols> name and its ON DELETE/UPDATE
  # rule -- both come straight from the target model. Without this, the server
  # would assign a random FK name (the next compare phantom-drops+adds it) and
  # the referential rule would be silently lost (ADR 0005).
  for my $fk (@{ $self->foreign_keys }) {
    push @col_defs, '  ' . _fk_constraint_clause($fk);
  }

  return sprintf "CREATE TABLE %s (\n%s\n);",
    _quote_ident($self->table_name), join(",\n", @col_defs);
}


sub summary {
  my ($self) = @_;
  return sprintf '%s table: %s', $self->summary_prefix, $self->table_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DB2::Diff::Table - Diff operations for DB2 tables

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Represents a table-level diff operation in DB2: C<CREATE TABLE> or
C<DROP TABLE>. C<create> ops capture the target columns and foreign keys
so C<as_sql> can emit the full inline definition in a single statement.

C<new>, the C<action> accessor and C<summary_prefix> come from
L<DBIO::Diff::Op>.

=head1 METHODS

=head2 diff

    my @ops = DBIO::DB2::Diff::Table->diff(
        $source_tables, $target_tables,
        $target_columns, $target_fks,
    );

=head2 as_sql

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
