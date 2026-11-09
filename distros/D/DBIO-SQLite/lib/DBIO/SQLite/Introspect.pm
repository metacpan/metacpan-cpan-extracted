package DBIO::SQLite::Introspect;
# ABSTRACT: Introspect a SQLite database via sqlite_master and PRAGMAs

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Introspect::Base';

use DBIO::SQLite::Introspect::Tables;
use DBIO::SQLite::Introspect::Columns;
use DBIO::SQLite::Introspect::Indexes;
use DBIO::SQLite::Introspect::ForeignKeys;
use DBIO::SQLite::Introspect::Triggers;
use DBIO::SQLite::Util qw(column_is_nullable pk_is_rowid_alias);


sub _build_model {
  my ($self) = @_;

  my $tables  = DBIO::SQLite::Introspect::Tables->fetch($self->dbh);
  my $columns = DBIO::SQLite::Introspect::Columns->fetch($self->dbh, $tables);
  my $indexes = DBIO::SQLite::Introspect::Indexes->fetch($self->dbh, $tables);
  my $fks     = DBIO::SQLite::Introspect::ForeignKeys->fetch($self->dbh, $tables);
  my $triggers = DBIO::SQLite::Introspect::Triggers->fetch($self->dbh, $tables);

  return {
    tables       => $tables,
    columns      => $columns,
    indexes      => $indexes,
    foreign_keys => $fks,
    triggers     => $triggers,
  };
}


sub table_columns_info {
  my ($self, $key) = @_;
  my $info = $self->SUPER::table_columns_info($key);
  my $cols = $self->model->{columns}{$key} || [];

  # Only a key column can disagree with the base, and only then is the extra
  # PRAGMA worth running. Views and keyless tables keep SUPER's answer.
  return $info unless grep { $_->{is_pk} } @$cols;

  my $alias = pk_is_rowid_alias($self->dbh, $key);
  for my $col (@$cols) {
    $info->{ $col->{column_name} }{is_nullable} =
      column_is_nullable($col->{not_null}, $col->{is_pk}, $alias);
  }
  return $info;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::Introspect - Introspect a SQLite database via sqlite_master and PRAGMAs

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::SQLite::Introspect> reads the live state of a SQLite database
via C<sqlite_master> and the relevant C<PRAGMA> statements and returns a
unified model hashref. It is the source side of the test-deploy-and-
compare strategy used by L<DBIO::SQLite::Deploy>.

    my $intro = DBIO::SQLite::Introspect->new(dbh => $dbh);
    my $model = $intro->model;
    # $model->{tables}, $model->{columns}, $model->{indexes},
    # $model->{foreign_keys}, $model->{triggers}

The model shape mirrors L<DBIO::PostgreSQL::Introspect> so the same
diff/deploy patterns apply, but only covers what SQLite actually has
(no schemas, types, functions, RLS).

C<triggers> is a section of this driver, beyond the canonical model of
L<DBIO::Introspect::Base/CANONICAL MODEL>: the triggers of each table and
view, by name, each with its C<CREATE TRIGGER> statement
(L<DBIO::SQLite::Introspect::Triggers/fetch>). It is an empty hash for a
database that has none. Triggers are B<carried, not compared>.
L<DBIO::SQLite::Diff> never reports one as added, dropped or changed --
a schema cannot declare a trigger, so the target of an upgrade has none, and
comparing would drop every trigger of the live database. The section is there
for L<DBIO::SQLite::Diff::Rebuild>, which has to re-create the triggers of
the table it rebuilds, and for L<DBIO::SQLite::Diff::View>, which re-creates
the C<INSTEAD OF> triggers of a view it replaces.

=head1 METHODS

=head2 table_columns_info

Overrides L<DBIO::Introspect::Base/table_columns_info> for one key:
C<is_nullable>.

The base folds primary-key membership into it -- C<< is_pk >> alone makes a
column C<< is_nullable => 0 >> -- as a statement about DBIO's model, on the
grounds that a row identity which can be NULL is not usable in the Row layer
(core ADR 0038). On SQLite that statement is not true of the database. A
C<PRIMARY KEY> on a rowid table really does store NULL, repeatedly, and the
NULLs do not even collide; only the C<INTEGER PRIMARY KEY> rowid alias is
exempt, and C<WITHOUT ROWID> tables report C<notnull = 1> for their key
themselves. This introspector reports what the database holds, because what it
reports is what L<DBIO::Generate> writes into the regenerated result class and
what a redeploy then emits as DDL -- and a C<NOT NULL> derived from a key
column full of NULLs produces a table that refuses the rows it was generated
from.

Base's escape hatch for exactly this is a driver override of this method, which
is what this is. The rule itself lives in
L<DBIO::SQLite::Util/column_is_nullable>, shared with
L<DBIO::SQLite::Storage/_dbh_columns_info_for> so the introspect path and the
live C<PRAGMA> path cannot disagree about the same column.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
