package DBIO::ClickHouse::Introspect::Tables;
# ABSTRACT: Introspect ClickHouse tables and views via system.tables

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::ClickHouse::Introspect::Util ();



sub fetch {
  my ($class, $dbh, $database) = @_;

  my $sql = q{
    SELECT
      name,
      database,
      engine,
      engine_full,
      sorting_key,
      primary_key,
      partition_key,
      sampling_key,
      comment,
      create_table_query
    FROM system.tables
    WHERE database = %s
    ORDER BY name
  };
  my @bind;
  if (defined $database) {
    $sql = sprintf $sql, '?';
    push @bind, $database;
  }
  else {
    $sql = sprintf $sql, 'currentDatabase()';
  }

  my $sth = $dbh->prepare($sql);
  $sth->execute(@bind);

  my %tables;
  while (my $row = $sth->fetchrow_hashref) {
    my $name = $row->{name};

    my @sorting   = _entries($row->{sorting_key});
    my @primary   = _entries($row->{primary_key});
    my @partition = _entries($row->{partition_key});

    # ClickHouse leaves primary_key empty for engines that have no key at all
    # (Log, Memory, View); for MergeTree it mirrors the sorting key unless a
    # narrower PRIMARY KEY prefix was declared.
    @primary = @sorting unless @primary;

    $tables{$name} = {
      table_name            => $name,
      database              => $row->{database},
      kind                  => _kind($row->{engine}),
      engine                => $row->{engine},
      engine_full           => $row->{engine_full},
      engine_expression     => _engine_expression($row->{engine}, $row->{engine_full}),
      sorting_key           => $row->{sorting_key},
      sorting_key_entries   => \@sorting,
      primary_key           => $row->{primary_key},
      primary_key_entries   => \@primary,
      primary_key_columns   => [ grep { /\A\w+\z/ } @primary ],
      partition_key         => $row->{partition_key},
      partition_key_entries => \@partition,
      sampling_key          => $row->{sampling_key},
      comment               => $row->{comment},
    };

    # What a view selects, as the server holds it: the diff compares it
    # (DBIO::ClickHouse::Diff::View). Only views carry one.
    if ($tables{$name}{kind} eq 'view') {
      $tables{$name}{definition} = DBIO::ClickHouse::Introspect::Util->view_select(
        $row->{create_table_query});
    }
  }

  return \%tables;
}

sub _entries {
  my ($expression) = @_;
  return DBIO::ClickHouse::Introspect::Util->split_top_level($expression);
}

# ClickHouse has no table_type column: the engine is the discriminator.
# View, MaterializedView, LiveView and WindowView are all views.
sub _kind {
  my ($engine) = @_;
  return (($engine // '') =~ /View\z/) ? 'view' : 'table';
}

# engine_full is "<Engine>[(args)] [PARTITION BY ...] [ORDER BY ...] [SETTINGS ...]".
# Take the leading engine term with its arguments, if any.
sub _engine_expression {
  my ($engine, $engine_full) = @_;
  return $engine unless defined $engine_full && length $engine_full;
  return $1 if $engine_full =~ /\A(\w+\((?:[^()]|\([^()]*\))*\))/;
  return $1 if $engine_full =~ /\A(\w+)/;
  return $engine;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ClickHouse::Introspect::Tables - Introspect ClickHouse tables and views via system.tables

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches ClickHouse table and view metadata from C<system.tables>, scoped to
one database (C<currentDatabase()> by default).

C<system.tables> is used rather than C<information_schema.tables> on purpose:
C<information_schema> is a MySQL-shaped compatibility view that has no column
for the engine, the sorting key or the partition key -- exactly the three
things a ClickHouse C<CREATE TABLE> cannot be rebuilt without. See
C<docs/adr/0001-mysql-wire-protocol-transport.md>: the wire is MySQL's, the
catalog is not.

=head2 What is captured, and why

Beyond the canonical C<table_name> / C<kind>, every row carries the MergeTree
metadata the diff layer needs to tell "the same table" from "a table that
needs recreating":

=over 4

=item * C<engine> -- the bare engine name (C<MergeTree>, C<ReplacingMergeTree>).

=item * C<engine_expression> -- the engine B<with> its arguments, extracted
from C<engine_full>. C<system.tables.engine> drops them, so a
C<ReplacingMergeTree(version)> table reports plain C<ReplacingMergeTree> there
and the version column would be lost. This is the value that maps back to
L<DBIO::ClickHouse::Result>'s C<< clickhouse_table->{engine} >>.

=item * C<sorting_key> / C<primary_key> / C<partition_key> -- the raw
expression strings as the server renders them, plus C<*_entries>, the same
lists split on top-level commas.

=item * C<primary_key_columns> -- the C<primary_key_entries> that are bare
column names, in order. ClickHouse has no primary-key constraint; the
MergeTree key B<is> the primary key, and it may contain expressions
(C<cityHash64(id)>) that are not columns at all. Only the bare identifiers can
answer "is this column part of the primary key", which is what
L<DBIO::Introspect::Base/table_pk_info> asks.

=back

C<sorting_key> and C<primary_key> are equal whenever the table did not declare
a separate C<PRIMARY KEY> prefix -- ClickHouse fills the latter in from the
former. The caller decides whether that is worth emitting.

=head1 METHODS

=head2 fetch

    my $tables = DBIO::ClickHouse::Introspect::Tables->fetch($dbh);
    my $tables = DBIO::ClickHouse::Introspect::Tables->fetch($dbh, $database);

Returns a hashref keyed by table name. Each value is a hashref with keys:
C<table_name>, C<kind> (C<table> or C<view>), C<database>, C<engine>,
C<engine_full>, C<engine_expression>, C<sorting_key>, C<sorting_key_entries>,
C<primary_key>, C<primary_key_entries>, C<primary_key_columns>,
C<partition_key>, C<partition_key_entries>, C<sampling_key>, C<comment>, and
for a view C<definition>, its C<SELECT> as the server holds it
(C<create_table_query> without the statement head; the server writes the
database into the names it qualifies).

When C<$database> is undef the query is scoped to C<currentDatabase()>.

=head1 SEE ALSO

=over 4

=item * L<DBIO::ClickHouse::Introspect> - assembles the model from this and its sibling readers

=item * L<DBIO::ClickHouse::Result> - the C<clickhouse_table> options this metadata maps back to

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
