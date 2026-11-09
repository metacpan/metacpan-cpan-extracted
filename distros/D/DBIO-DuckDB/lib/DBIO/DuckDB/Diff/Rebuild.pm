package DBIO::DuckDB::Diff::Rebuild;
# ABSTRACT: Rebuild a DuckDB table for what ALTER TABLE cannot do

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::Exception;
use DBIO::DuckDB::DDL::Emit qw(quote_ident quote_table split_table);
use DBIO::DuckDB::Diff::Table;

__PACKAGE__->mk_diff_accessors(qw/
  table_name columns foreign_keys unique_constraints copy_columns reasons column_ops
/);



sub tmp_name {
  my ($self) = @_;
  my ($schema, $table) = split_table($self->table_name);
  return (defined $schema ? "$schema." : '') . $table . '__dbio_rebuild';
}


sub as_sql {
  my ($self) = @_;
  my @copy = @{ $self->copy_columns || [] };
  DBIO::Exception->throw(sprintf
    "Cannot rebuild table '%s': the old and the new table have no column in common, no row could be carried over",
    $self->table_name) unless @copy;

  my $create = DBIO::DuckDB::Diff::Table->new(
    action             => 'create',
    table_name         => $self->tmp_name,
    columns            => $self->columns,
    foreign_keys       => $self->foreign_keys,
    unique_constraints => $self->unique_constraints,
  )->as_sql;

  my $list = join ', ', map { quote_ident($_) } @copy;
  my ($schema, $table) = split_table($self->table_name);
  return join "\n",
    $create,
    sprintf('INSERT INTO %s (%s) SELECT %s FROM %s;',
      quote_table($self->tmp_name), $list, $list, quote_table($self->table_name)),
    sprintf('DROP TABLE %s;', quote_table($self->table_name)),
    sprintf('ALTER TABLE %s RENAME TO %s;', quote_table($self->tmp_name), quote_ident($table));
}


sub lossy_columns {
  my ($self) = @_;
  return map { $_->column_name }
    grep { $_->action eq 'drop' || $_->lossy } @{ $self->column_ops || [] };
}


sub lossy { scalar(my @c = $_[0]->lossy_columns) ? 1 : 0 }


sub summary {
  my ($self) = @_;
  my @lossy = map { $self->table_name . ".$_" } $self->lossy_columns;
  return sprintf '%s rebuild table: %s (%s)%s', $self->summary_prefix,
    $self->table_name, join('; ', @{ $self->reasons || [] }),
    (@lossy ? ' drops or may alter: ' . join(', ', @lossy) : '');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DuckDB::Diff::Rebuild - Rebuild a DuckDB table for what ALTER TABLE cannot do

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

DuckDB cannot drop a column while an index or a C<UNIQUE> constraint stands on
it or on a later column, cannot drop a C<UNIQUE> constraint, and has no
C<ALTER TABLE> for a foreign key. The diff then replaces the table's column and
index operations by one of these, after the pattern of dbio-sqlite (its ADR
0003): a new table with the target's definition under a temporary name
(C<NAME__dbio_rebuild>, in the schema of the table), the rows of the columns
both tables have copied, the old table dropped, the new one renamed, and the
table's indexes of the target created again behind it (ordinary
L<DBIO::DuckDB::Diff::Index> operations).

The statements carry no transaction of their own. L<DBIO::DuckDB::Deploy/_execute_diff>
runs the whole diff in one, so a copy that fails -- a row the new key or
C<NOT NULL> refuses -- takes the rebuild and everything before it back.

What the rebuild cannot do is refused by L<DBIO::DuckDB::Deploy> before the
first statement (see L<DBIO::DuckDB::Deploy/_check_before_apply>): DuckDB does not drop a table
another one has a foreign key to, and a table that points to itself keeps the
temporary name in its key after the rename.

C<column_ops> holds the L<DBIO::DuckDB::Diff::Column> operations the rebuild
replaces; they render nothing, but the deploy still looks at their rows
(a new C<NOT NULL> column without a default).

A rebuild that drops a column, or changes one so that values can be lost
(L</lossy>), runs only with C<allow_destructive> (ADR 0011).

=head1 METHODS

=head2 tmp_name

The name the new table has until the rename.

=head2 as_sql

=head2 lossy_columns

The names of the columns whose values the rebuild can lose or alter: the ones
its C<column_ops> drop and the ones they change with
L<DBIO::DuckDB::Diff::Column/lossy> (the same pair list, ADR 0011). A rebuild
copies every column the new table shares with the old one unchanged, so the
other columns keep their values.

=head2 lossy

True when L</lossy_columns> names a column, so that
L<DBIO::Deploy::Base/apply> runs the rebuild only with C<allow_destructive>. A
rebuild that carries every column over unchanged (a C<UNIQUE> dropped, a
foreign key added) is not lossy.

=head2 summary

Names the table and, when the rebuild loses or alters values, the columns
(C<table.column>), never a value.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
