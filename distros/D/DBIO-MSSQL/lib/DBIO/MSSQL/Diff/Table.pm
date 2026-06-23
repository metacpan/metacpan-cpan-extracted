package DBIO::MSSQL::Diff::Table;
# ABSTRACT: Diff operations for MSSQL tables

use strict;
use warnings;

use base 'DBIO::Diff::Op';

use DBIO::SQL::Util qw(_quote_ident);
use DBIO::MSSQL::DDL qw(_mssql_column_type);


__PACKAGE__->mk_diff_accessors(qw/table_name table_info columns foreign_keys/);


sub diff {
  my ($class, $source, $target, $target_columns, $target_fks) = @_;
  $target_columns //= {};
  $target_fks     //= {};

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

    my $type = _mssql_column_type($col);
    my $def = sprintf '  %s %s', _quote_ident($col->{column_name}), $type;
    $def .= ' NOT NULL' if $col->{not_null};
    if (defined $col->{default_value}) {
      $def .= " DEFAULT $col->{default_value}";
    }
    if ($col->{is_identity}) {
      $def .= ' IDENTITY(1,1)';
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

DBIO::MSSQL::Diff::Table - Diff operations for MSSQL tables

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Table-level diff operations for MSSQL. Handles C<CREATE TABLE>, C<DROP TABLE>.
C<create> ops capture the target columns and foreign keys so C<as_sql> can emit
the full inline definition. Built on L<DBIO::Diff::Op> (the C<create>/C<drop>
walk and accessor/summary plumbing).

=head1 METHODS

=head2 diff

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
