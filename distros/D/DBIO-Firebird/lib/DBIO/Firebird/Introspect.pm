package DBIO::Firebird::Introspect;
# ABSTRACT: Introspect a Firebird database via rdb$ system tables

use strict;
use warnings;

use base 'DBIO::Introspect::Base';


use DBIO::Firebird::Introspect::Tables;
use DBIO::Firebird::Introspect::Columns;
use DBIO::Firebird::Introspect::Indexes;
use DBIO::Firebird::Introspect::Uniques;
use DBIO::Firebird::Introspect::ForeignKeys;

sub _build_model {
  my ($self) = @_;
  my $dbh = $self->dbh;

  # Firebird returns result-column names upper-cased; the helpers read
  # lower-case rdb$ keys from fetchrow_hashref. Force lower-cased hash keys so
  # the two agree (statement handles inherit this at prepare time).
  local $dbh->{FetchHashKeyName} = 'NAME_lc';

  my $tables = DBIO::Firebird::Introspect::Tables->fetch($dbh);
  my $columns = DBIO::Firebird::Introspect::Columns->fetch($dbh, $tables);
  my $indexes = DBIO::Firebird::Introspect::Indexes->fetch($dbh, $tables);
  my $uniques = DBIO::Firebird::Introspect::Uniques->fetch($dbh, $tables);
  my $foreign_keys = DBIO::Firebird::Introspect::ForeignKeys->fetch($dbh, $tables);

  return {
    tables             => $tables,
    columns            => $columns,
    indexes            => $indexes,
    unique_constraints => $uniques,
    foreign_keys       => $foreign_keys,
  };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Firebird::Introspect - Introspect a Firebird database via rdb$ system tables

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

C<DBIO::Firebird::Introspect> reads the live state of a Firebird database
via the C<rdb$*> system tables and returns a unified model hashref. It is the
source side of the test-deploy-and-compare strategy used by
L<DBIO::Firebird::Deploy>.

    my $intro = DBIO::Firebird::Introspect->new(dbh => $dbh);
    my $model = $intro->model;
    # $model->{tables}, $model->{columns}, $model->{indexes},
    # $model->{unique_constraints}, $model->{foreign_keys}

The model is built lazily on first access and has five top-level sections:
tables, columns, indexes, unique_constraints, and foreign_keys (views are
surfaced within the tables section, not as a separate top-level key). On top
of it, this class implements the normalized
generation contract from L<DBIO::Introspect::Base> so it can act as a
L<DBIO::Generate> source.

=head1 THE INTROSPECTED MODEL

The model hashref returned by L</model> is the shared substrate of this
distribution: produced here by the C<Introspect::*> helpers, consumed by
L<DBIO::Firebird::Diff> (table/column/index comparison) and by the
L</NORMALIZED CONTRACT> methods below (the L<DBIO::Generate> source). It has
exactly five top-level sections — C<tables>, C<columns>, C<indexes>,
C<unique_constraints>, and C<foreign_keys> — each a hashref keyed by
I<table name> (Firebird has no schemas, so keys are bare, un-qualified
relation names).

=head2 tables

    { $table_name => { table_name => $name, kind => 'table' | 'view' } }

=head2 columns

    { $table_name => [ \%column, ... ] }   # in rdb$field_position order

Each column hashref:

=over 4

=item * C<column_name> — the column name.

=item * C<data_type> — the I<bare> SQL type (e.g. C<'integer'>, C<'decimal'>,
C<'varchar'>). Size/precision is B<not> folded in here; it lives in C<size>.

=item * C<size> — C<undef>, a scalar length (C<varchar>/C<char>), or an
C<[ precision, scale ]> pair (C<decimal>/C<numeric>). Rendered to SQL via
L<DBIO::Firebird::Type/render_size>.

=item * C<not_null> — C<1> if the column is C<NOT NULL>, else C<0>
(from C<rdb$null_flag>).

=item * C<default_value> — the column default expression, or C<undef>.

=item * C<is_pk> / C<pk_position> — primary-key membership and 0-based position (C<rdb$field_position>).

=back

=head2 indexes

    { $table_name => { $index_name => { index_name, is_unique, columns => [...] } } }

Indexes backed by C<PRIMARY KEY> / C<UNIQUE> constraints are B<excluded> —
they belong to the table definition, not an explicit C<CREATE INDEX>.

=head2 unique_constraints

    { $table_name => [ [ $constraint_name, \@column_names ], ... ] }

C<UNIQUE> I<constraints> (distinct from the C<CREATE UNIQUE INDEX> objects in
C<indexes>), sorted by constraint name. Source of the C<table_uniq_info>
contract method.

=head2 foreign_keys

    { $table_name => [ \%fk, ... ] }

Each FK hashref: C<fk_id>, C<from_table>, C<from_columns>, C<to_table>,
C<to_columns>, and the referential actions C<on_update>, C<on_delete>,
C<match> (from C<rdb$ref_constraints>).

=head1 NORMALIZED CONTRACT

The L<DBIO::Generate> generation contract (C<table_keys>, C<table_columns>,
C<table_columns_info>, C<table_pk_info>, C<table_uniq_info>, C<table_fk_info>,
C<table_is_view>) is B<inherited unchanged> from L<DBIO::Introspect::Base>:
the model built by L</_build_model> follows the canonical single-schema shape
(see L<DBIO::Introspect::Base/CANONICAL MODEL>) that those default
implementations read, so no Firebird-specific override is needed. In
particular C<unique_constraints> is the authoritative source for
C<table_uniq_info>, and FK C<remote_schema> is always C<undef> (Firebird has
no schemas).

=seealso

=over 4

=item * L<DBIO::Firebird::Deploy> - uses this class to compare current and desired state

=item * L<DBIO::Firebird::Diff> - compares two models produced by this class

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
