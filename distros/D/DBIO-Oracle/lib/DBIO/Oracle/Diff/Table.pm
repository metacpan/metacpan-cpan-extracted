package DBIO::Oracle::Diff::Table;
# ABSTRACT: Diff operations for Oracle tables

use strict;
use warnings;

use base 'DBIO::Diff::Op';

use DBIO::SQL::Util qw(_quote_ident);

__PACKAGE__->mk_diff_accessors(qw(table_name table_info columns foreign_keys));



sub diff {
  my ($class, $source, $target, $target_columns, $target_fks) = @_;
  $target_columns //= {};
  $target_fks     //= {};

  return $class->diff_toplevel(
    $source, $target,
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
    return sprintf 'DROP TABLE %s CASCADE CONSTRAINTS;',
      _quote_ident($self->table_name);
  }

  my @col_defs;
  my @pk_cols;
  my @seq_stmts;

  for my $col (@{ $self->columns }) {
    push @pk_cols, $col->{column_name} if $col->{is_pk};

    my $type = _oracle_type($col);
    my $def  = sprintf '  %s %s', _quote_ident($col->{column_name}), $type;
    $def .= ' NOT NULL' if $col->{not_null};

    # Handle default value
    if (defined $col->{default_value}) {
      my $dv = $col->{default_value};
      if (ref $dv eq 'SCALAR') {
        $def .= " DEFAULT $$dv";
      }
      elsif (defined $dv && $dv ne 'null') {
        $def .= " DEFAULT '$dv'";
      }
    }

    # Handle sequence-based auto-increment
    if ($col->{is_auto_increment} && $col->{sequence}) {
      push @seq_stmts, sprintf 'CREATE SEQUENCE %s;',
        _quote_ident($col->{sequence});
    }

    push @col_defs, $def;
  }

  if (@pk_cols) {
    push @col_defs, sprintf '  PRIMARY KEY (%s)',
      join(', ', map { _quote_ident($_) } @pk_cols);
  }

  for my $fk (@{ $self->foreign_keys }) {
    push @col_defs, sprintf '  FOREIGN KEY (%s) REFERENCES %s(%s)',
      join(', ', map { _quote_ident($_) } @{ $fk->{from_columns} }),
      _quote_ident($fk->{to_table}),
      join(', ', map { _quote_ident($_) } @{ $fk->{to_columns} });
  }

  my $create = sprintf "CREATE TABLE %s (\n%s\n);",
    _quote_ident($self->table_name), join(",\n", @col_defs);

  if (@seq_stmts) {
    return (join "\n", @seq_stmts) . "\n$create";
  }
  return $create;
}


sub summary {
  my ($self) = @_;
  return sprintf '%s table: %s', $self->summary_prefix, $self->table_name;
}

sub _oracle_type {
  my ($col) = @_;
  my $type  = $col->{data_type} || 'VARCHAR2';

  # Handle size spec
  if (defined $col->{size}) {
    if (ref $col->{size} eq 'ARRAY') {
      return sprintf '%s(%d,%d)', uc($type), $col->{size}[0], $col->{size}[1];
    }
    else {
      return sprintf '%s(%d)', uc($type), $col->{size};
    }
  }

  return uc($type);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Diff::Table - Diff operations for Oracle tables

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Represents a table-level diff operation in Oracle: C<CREATE TABLE> or
C<DROP TABLE>. C<create> ops capture the target columns and foreign keys
so C<as_sql> can emit the full inline definition.

=head1 ATTRIBUTES

=head2 table_name

The bare table name.

=head2 table_info

Hashref of table metadata from introspection (C<kind>, C<schema>, etc.).

=head2 columns

ArrayRef of column hashrefs for new tables (populated when C<action> is
C<create>), so that C<as_sql> can emit a complete CREATE TABLE with all
column definitions rather than an empty shell.

=head2 foreign_keys

ArrayRef of FK hashrefs for new tables (populated when C<action> is
C<create>), inlined in the CREATE TABLE.

=head1 METHODS

=head2 diff

    my @ops = DBIO::Oracle::Diff::Table->diff(
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
