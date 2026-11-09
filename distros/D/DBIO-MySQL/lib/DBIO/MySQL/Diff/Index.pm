package DBIO::MySQL::Diff::Index;
# ABSTRACT: Diff operations for MySQL/MariaDB indexes

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::Diff::Compare qw(changed_index_fields);
use DBIO::MySQL::Identifier qw(quote_ident quote_table_in);
use DBIO::MySQL::IndexType ();
use DBIO::MySQL::Diff::View ();

__PACKAGE__->mk_diff_accessors(qw(
  table_name index_name index_info old_index_info database replaced
));



sub diff {
  my ($class, $source, $target, $source_tables, $target_tables) = @_;

  # Tables present in the source model but absent from the target are being
  # dropped in this same pass. Their indexes go with the table via DROP TABLE,
  # so a later standalone DROP INDEX for one of them must be suppressed (karr
  # #23). Backward compatible: absent table sections -> empty set -> no
  # suppression.
  $source_tables //= {};
  $target_tables //= {};

  # a view is no table, and has no index to create or drop (karr k79)
  ($source_tables, $source) = DBIO::MySQL::Diff::View::without_views($source_tables, $source);
  ($target_tables, $target) = DBIO::MySQL::Diff::View::without_views($target_tables, $target);

  my %dropped_table = map { $_ => 1 }
    grep { !exists $target_tables->{$_} } keys %$source_tables;

  # Indexes need a "union" view of the per-table membership: an index on
  # a brand-new table is just as much a create as one on a table that
  # exists in both source and target, and an index on a table that is
  # being dropped is just as much a drop. So we walk with `scope => 'all'`:
  #   * target tables  -> on_new, on_changed
  #   * source-only tables -> on_gone
  #   * both-side tables  -> member-level comparison + on_gone for
  #                          members that vanished
  # That's three kinds of "thing happened" with one walk.
  return $class->diff_nested(
    $source, $target,
    scope      => 'all',
    skip       => \&_is_auto,
    changed_when => \&changed_index_fields,
    on_new => sub {
      my ($table_name, $index_name, $index_info) = @_;
      $class->new(action => 'create', table_name => $table_name,
        index_name => $index_name, index_info => $index_info);
    },
    on_changed => sub {
      my ($table_name, $index_name, $old_info, $new_info) = @_;
      (
        $class->new(action => 'drop',   table_name => $table_name, replaced => 1,
          index_name => $index_name, index_info => $old_info),
        $class->new(action => 'create', table_name => $table_name,
          index_name => $index_name, index_info => $new_info),
      );
    },
    on_gone => sub {
      my ($table_name, $index_name, $index_info) = @_;
      # Owning table dropped this pass -> DROP TABLE already took the index;
      # a standalone DROP INDEX would fail (karr #23).
      return () if $dropped_table{$table_name};
      $class->new(action => 'drop', table_name => $table_name,
        index_name => $index_name, index_info => $index_info);
    },
  );
}

# Only the PRIMARY KEY is left out: Diff::Table writes it into CREATE TABLE.
# A unique index (origin 'u') is NOT an auto index here -- the server keeps a
# UNIQUE constraint as nothing but a unique index, and no other diff operation
# renders one, so skipping it meant it never reached the database (karr k70).
sub _is_auto {
  my ($info) = @_;
  return 0 unless defined $info->{origin};
  return $info->{origin} eq 'pk';
}


sub as_sql {
  my ($self) = @_;

  if ($self->action eq 'create' || $self->action eq 'replace') {
    my $info   = $self->index_info;
    my $unique = $info->{is_unique} ? 'UNIQUE ' : '';

    # index_type is the engine's index class/type from introspect (BTREE,
    # FULLTEXT, SPATIAL, HASH -- ADR 0052). Render it through the same split
    # DDL.pm uses (DBIO::MySQL::IndexType), so a FULLTEXT index a diff creates
    # is a FULLTEXT index and not the silent BTREE default (karr k52). A
    # typeless index (index_type undef, the common case) or an unrecognised
    # token yields no fragments and renders exactly as before -- the empty-list
    # return leaves both fragments undef, defaulted to '' here.
    my ($class_kw, $type) = DBIO::MySQL::IndexType::index_type_split($info->{index_type});
    $class_kw //= '';
    $type     //= '';

    my $cols = join ', ',
      map { quote_ident($_) } @{ $info->{columns} // [] };
    return sprintf 'ALTER TABLE %s DROP INDEX %s, ADD %s%sINDEX %s (%s)%s;',
      quote_table_in($self->database, $self->table_name), quote_ident($self->index_name),
      $unique, $class_kw, quote_ident($self->index_name), $cols, $type
      if $self->action eq 'replace';
    return sprintf 'CREATE %s%sINDEX %s ON %s (%s)%s;',
      $unique, $class_kw, quote_ident($self->index_name),
      quote_table_in($self->database, $self->table_name), $cols, $type;
  }
  return sprintf 'DROP INDEX %s ON %s;',
    quote_ident($self->index_name), quote_table_in($self->database, $self->table_name);
}


sub summary {
  my ($self) = @_;
  my $prefix = $self->action eq 'create' ? '+' : $self->action eq 'replace' ? '~' : '-';
  return sprintf '  %sindex: %s on %s',
    $prefix, $self->index_name, $self->table_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Diff::Index - Diff operations for MySQL/MariaDB indexes

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents an index-level diff operation: C<CREATE INDEX> or
C<DROP INDEX>. Every index is diffed here except the PRIMARY KEY (introspect
origin C<pk>), which L<DBIO::MySQL::Diff::Table> writes into C<CREATE TABLE>.

That includes the unique indexes (origin C<u>). The server keeps a UNIQUE
constraint as a unique index and nothing else, the two cannot be told apart,
and L<DBIO::MySQL::Introspect::Indexes> gives C<u> to every unique index. So a
unique key that is added to, changed in or removed from a schema is a
C<CREATE UNIQUE INDEX> or a C<DROP INDEX> like that of any other index.

An index has changed when its uniqueness differs, when the set of its columns
differs, or when both sides name an index type and the two differ (see
L<DBIO::Diff::Compare/changed_index_fields>; the same columns in another order
are not a change). A changed index is dropped and created again.

B<MariaDB and FULLTEXT.> A FULLTEXT index that is dropped and created again
does not find the rows written while the old index existed, until the table is
rebuilt (measured on MariaDB 11.8, reproducible with plain SQL; MySQL 8.0 finds
them). The diff creates the index correctly and does not rebuild the table; if
old rows must be found after such an upgrade on MariaDB, run
C<ALTER TABLE ... FORCE> on the table afterwards.

The C<CREATE TABLE> of L<DBIO::MySQL::Diff::Table> carries no index but the
primary key. The indexes of a table the diff creates, its unique keys among
them, follow as statements of their own, after the tables and the column
changes of the same diff.

A C<DROP INDEX> stands before the column changes of the same diff
(L<DBIO::MySQL::Diff> puts it there), so a column that leaves the schema
together with an index over it is dropped after that index. The other way
round the server takes an index along with the last column it was over, and a
C<DROP INDEX> after that does not find it; MariaDB refuses to drop one column
of a unique key over several; and MySQL keeps such a key over the columns that
are left, where the rows may no longer differ. A changed index is dropped
before the column changes and created after them.

That order would leave the foreign keys without an index, so the diff looks
after them. The foreign keys that leave the schema, or change, are dropped
before everything else, and those that arrive are added last
(L<DBIO::MySQL::Diff::ForeignKey>), so the index a foreign key had to have
goes after the constraint. A foreign key in the C<CREATE TABLE> of a table the
diff creates cannot reference a key that is created by the same diff, because
the key does not exist yet and the server refuses the C<CREATE TABLE> (1822 /
errno 150): such a foreign key is added after the index creates instead, with
the others. So is a foreign key of a new table whose columns an index the diff
creates on that table covers: in the C<CREATE TABLE> the server would make an
index of its own for the constraint, and the C<CREATE INDEX> would be a second
one. And a C<DROP INDEX> of an index a foreign key that stays still needs,
with no other index left over the same columns, is refused by the server
(1553): the index that replaces it, a create of the same diff over those
columns, is created before the drop. When the replacement has the name of the
index it replaces -- a changed index -- both are one statement, C<ALTER TABLE
... DROP INDEX n, ADD INDEX n (...)> (action C<replace>, with
C<old_index_info>). Where no index of the diff takes over, C<operations> dies,
naming the index and the foreign key; a statement the server is sure to refuse
is not written.

The only key of an C<AUTO_INCREMENT> column that is not the primary key is not
one of them: such a column has to have a key, and the server refuses the
C<DROP INDEX> of it (1075). L<DBIO::MySQL::Diff> puts the C<MODIFY COLUMN>
that takes C<AUTO_INCREMENT> from the column -- or the one it writes for a
column that leaves -- before that C<DROP INDEX>.

=head1 METHODS

=head2 diff

    my @ops = DBIO::MySQL::Diff::Index->diff(
      $source, $target, $source_tables, $target_tables);

The optional C<$source_tables> / C<$target_tables> hashrefs are the C<tables>
sections of the two models (threaded in by L<DBIO::MySQL::Diff>, the same way it
already threads them into C<Diff::Column> / C<Diff::ForeignKey>). They are used
to detect tables that are being dropped in this same diff pass: C<DROP TABLE>
already removes that table's own indexes, so emitting a later standalone
C<DROP INDEX ... ON <table>> for one of them would fail against the server (the
C<ON <table>> target no longer exists), aborting the deploy. When
these arguments are absent (e.g. direct unit-test calls) the set is empty and no
drops are suppressed, preserving the original two-argument behaviour.

=head2 as_sql

The C<CREATE INDEX> or C<DROP INDEX> statement, or for the action C<replace>
the one C<ALTER TABLE> that drops an index and adds the one of the same name.
The names of the index, the
table and the columns are quoted with L<DBIO::MySQL::Identifier/quote_ident>.

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
