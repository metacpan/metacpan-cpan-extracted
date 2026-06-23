package DBIO::DuckDB::Diff::Table;
# ABSTRACT: Diff operations for DuckDB tables

use strict;
use warnings;

use base 'DBIO::Diff::Op';

use DBIO::SQL::Util qw(_quote_ident);
use DBIO::DuckDB::DDL::Emit qw(
  column_def pk_clause fk_clause create_table create_sequence
);

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
  my @sequences;  # sequences referenced via nextval() in defaults

  for my $col (@{ $self->columns }) {
    push @pk_cols, $col->{column_name} if $col->{is_pk};

    if (defined $col->{default_value}) {
      # Collect any sequences referenced by nextval() so we can ensure
      # they exist before the CREATE TABLE runs.
      while ($col->{default_value} =~ /nextval\(\s*'([^']+)'\s*\)/g) {
        push @sequences, $1;
      }
    }

    push @col_defs, column_def(
      name     => $col->{column_name},
      type     => ($col->{data_type} || 'VARCHAR'),
      not_null => $col->{not_null},
      default  => $col->{default_value},
    );
  }

  push @col_defs, pk_clause(@pk_cols) if @pk_cols;

  for my $fk (@{ $self->foreign_keys }) {
    push @col_defs, fk_clause(
      from     => $fk->{from_columns},
      to_table => $fk->{to_table},
      to       => $fk->{to_columns},
    );
  }

  my $create = create_table($self->table_name, @col_defs);

  if (@sequences) {
    my $prefix = join "\n", map { create_sequence(name => $_) } @sequences;
    return "$prefix\n$create";
  }
  return $create;
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

DBIO::DuckDB::Diff::Table - Diff operations for DuckDB tables

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Represents a table-level diff operation in DuckDB: C<CREATE TABLE> or
C<DROP TABLE>. C<create> ops capture the target columns and foreign keys
so C<as_sql> can emit the full inline definition in a single statement
(DuckDB is happiest when a table is created whole rather than built up
with ALTER TABLE ADD COLUMN).

=head1 METHODS

=head2 diff

    my @ops = DBIO::DuckDB::Diff::Table->diff(
        $source_tables, $target_tables,
        $target_columns, $target_fks,
    );

=head2 as_sql

=head2 summary

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
