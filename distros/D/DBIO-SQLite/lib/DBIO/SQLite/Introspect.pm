package DBIO::SQLite::Introspect;
# ABSTRACT: Introspect a SQLite database via sqlite_master and PRAGMAs

use strict;
use warnings;

use base 'DBIO::Introspect::Base';

use DBIO::SQLite::Introspect::Tables;
use DBIO::SQLite::Introspect::Columns;
use DBIO::SQLite::Introspect::Indexes;
use DBIO::SQLite::Introspect::ForeignKeys;
use DBIO::SQLite::Util qw(column_is_nullable);


sub _build_model {
  my ($self) = @_;

  my $tables  = DBIO::SQLite::Introspect::Tables->fetch($self->dbh);
  my $columns = DBIO::SQLite::Introspect::Columns->fetch($self->dbh, $tables);
  my $indexes = DBIO::SQLite::Introspect::Indexes->fetch($self->dbh, $tables);
  my $fks     = DBIO::SQLite::Introspect::ForeignKeys->fetch($self->dbh, $tables);

  return {
    tables       => $tables,
    columns      => $columns,
    indexes      => $indexes,
    foreign_keys => $fks,
  };
}

# SQLite-specific override: PRAGMA table_info reports PRIMARY KEY columns
# as notnull=0 (the PK constraint is separate from the NOT NULL attribute),
# but a PK column is logically NOT NULL. The canonical Base contract derives
# is_nullable from not_null alone, so without this override PK columns would
# wrongly report is_nullable=1. column_is_nullable is the single source of
# truth for that rule (shared with DBIO::SQLite::Storage).
sub table_columns_info {
  my ($self, $key) = @_;
  my $info = $self->SUPER::table_columns_info($key);
  for my $col (@{ $self->model->{columns}{$key} || [] }) {
    $info->{ $col->{column_name} }{is_nullable} =
      column_is_nullable($col->{not_null}, $col->{is_pk});
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

version 0.900000

=head1 DESCRIPTION

C<DBIO::SQLite::Introspect> reads the live state of a SQLite database
via C<sqlite_master> and the relevant C<PRAGMA> statements and returns a
unified model hashref. It is the source side of the test-deploy-and-
compare strategy used by L<DBIO::SQLite::Deploy>.

    my $intro = DBIO::SQLite::Introspect->new(dbh => $dbh);
    my $model = $intro->model;
    # $model->{tables}, $model->{columns}, $model->{indexes}, $model->{foreign_keys}

The model shape mirrors L<DBIO::PostgreSQL::Introspect> so the same
diff/deploy patterns apply, but only covers what SQLite actually has
(no schemas, types, functions, RLS).

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
