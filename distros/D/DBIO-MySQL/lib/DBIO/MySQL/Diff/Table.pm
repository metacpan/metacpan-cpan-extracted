package DBIO::MySQL::Diff::Table;
# ABSTRACT: Diff operations for MySQL/MariaDB tables

use strict;
use warnings;

use base 'DBIO::Diff::Op';

__PACKAGE__->mk_diff_accessors(qw(
  table_name table_info columns foreign_keys
));



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
    return sprintf 'DROP TABLE `%s`;', $self->table_name;
  }

  my @col_defs;
  my @pk_cols;

  for my $col (@{ $self->columns }) {
    push @pk_cols, $col->{column_name} if $col->{is_pk};

    my $type = $col->{column_type} || $col->{data_type} || 'text';
    my $def = sprintf '  `%s` %s', $col->{column_name}, $type;
    $def .= ' NOT NULL' if $col->{not_null};
    $def .= ' AUTO_INCREMENT' if $col->{is_auto_increment};
    if (defined $col->{default_value}) {
      $def .= " DEFAULT '$col->{default_value}'";
    }
    push @col_defs, $def;
  }

  if (@pk_cols) {
    push @col_defs, sprintf '  PRIMARY KEY (%s)',
      join(', ', map { "`$_`" } @pk_cols);
  }

  for my $fk (@{ $self->foreign_keys }) {
    push @col_defs, sprintf '  FOREIGN KEY (%s) REFERENCES `%s`(%s)',
      join(', ', map { "`$_`" } @{ $fk->{from_columns} }),
      $fk->{to_table},
      join(', ', map { "`$_`" } @{ $fk->{to_columns} });
  }

  my $info    = $self->table_info // {};
  my $engine  = $info->{engine}          || 'InnoDB';
  my $charset = ($info->{table_collation} && $info->{table_collation} =~ /^([^_]+)_/)
    ? $1 : 'utf8mb4';

  return sprintf "CREATE TABLE `%s` (\n%s\n) ENGINE=%s DEFAULT CHARSET=%s;",
    $self->table_name, join(",\n", @col_defs), $engine, $charset;
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

DBIO::MySQL::Diff::Table - Diff operations for MySQL/MariaDB tables

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Represents a table-level diff operation in MySQL/MariaDB: C<CREATE
TABLE> or C<DROP TABLE>. C<create> ops carry the target columns and FKs
so C<as_sql> can render the full inline definition (parallel to
L<DBIO::SQLite::Diff::Table>).

=head1 METHODS

=head2 diff

    my @ops = DBIO::MySQL::Diff::Table->diff(
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
