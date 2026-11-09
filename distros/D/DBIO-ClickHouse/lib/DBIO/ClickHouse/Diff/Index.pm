package DBIO::ClickHouse::Diff::Index;
# ABSTRACT: Diff operations for ClickHouse data-skipping indexes

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use Exporter 'import';

use DBIO::Diff::Op   ();
use DBIO::Diff::Compare qw(norm);
use DBIO::ClickHouse::DDL::Emit qw(
  index_def alter_table_add_index alter_table_drop_index
);

our @EXPORT_OK = qw(changed_index);

__PACKAGE__->mk_diff_accessors(qw/table_name index_name index_info storage/);



sub changed_index {
  my ($old, $new) = @_;

  my @changed;
  for my $field (qw/expr type_full granularity/) {
    push @changed, $field if norm($old->{$field}) ne norm($new->{$field});
  }
  return @changed;
}


sub diff {
  my ($class, $source, $target, $source_tables, $target_tables, $storage) = @_;
  $source ||= {};
  $target ||= {};

  return $class->diff_nested($source, $target,
    scope         => 'both',
    source_tables => $source_tables || {},
    target_tables => $target_tables || {},
    changed_when  => sub {
      my ($old, $new) = @_;
      scalar changed_index($old, $new);
    },
    on_new => sub {
      my ($table_name, $name, $new) = @_;
      $class->new(
        action     => 'add',
        table_name => $table_name,
        index_name => $name,
        index_info => $new,
        storage    => $storage,
      );
    },
    on_changed => sub {
      my ($table_name, $name, $old, $new) = @_;
      # No ALTER INDEX in ClickHouse: the old summary has to go before the new
      # definition can take the name.
      return (
        $class->new(
          action => 'drop', table_name => $table_name,
          index_name => $name, index_info => $old,
          storage => $storage,
        ),
        $class->new(
          action => 'add', table_name => $table_name,
          index_name => $name, index_info => $new,
          storage => $storage,
        ),
      );
    },
    on_gone => sub {
      my ($table_name, $name, $old) = @_;
      $class->new(
        action     => 'drop',
        table_name => $table_name,
        index_name => $name,
        index_info => $old,
        storage    => $storage,
      );
    },
  );
}


sub as_sql {
  my ($self) = @_;

  my $if_guard = DBIO::Diff::Op::should_emit_if_exists($self->storage) ? 1 : 0;

  return alter_table_drop_index(
    table     => $self->table_name,
    name      => $self->index_name,
    if_exists => $if_guard,
  ) if $self->action eq 'drop';

  return alter_table_add_index(
    table         => $self->table_name,
    definition    => index_def($self->index_info),
    if_not_exists => $if_guard,
  );
}


sub summary {
  my ($self) = @_;
  return sprintf '  %sskipping index: %s on %s',
    $self->summary_prefix, $self->index_name, $self->table_name;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ClickHouse::Diff::Index - Diff operations for ClickHouse data-skipping indexes

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Diff operations for ClickHouse B<data-skipping indexes> -- the
C<data_skipping_indexes> section of the model produced by
L<DBIO::ClickHouse::Introspect::Indexes>, B<not> the canonical C<indexes>
section (which this driver always leaves empty).

=head2 Why these get their own identity

A data-skipping index is not a B-tree. It has no C<is_unique>, no ordered
column list, and it enforces nothing -- it is a per-granule summary
(C<minmax>, C<set(N)>, C<bloom_filter>, C<ngrambf_v1>, ...) computed over an
B<expression>, used to skip granules during a scan. Core's
C<DBIO::Diff::Compare/changed_index_fields> compares C<is_unique> and a
C<columns> list; neither field exists here, so it would report every index as
unchanged. This module compares what a skipping index actually is:

    expr          the indexed expression, verbatim
    type_full     the index type WITH its arguments (set(100), not set)
    granularity   how many index granules one summary covers

C<type_full> rather than C<type>, because C<set(100)> and C<set(1000)> are
both C<type> C<set> and are not the same index.

=head2 They are altered, not created

Skipping indexes are declared B<inline> in C<CREATE TABLE>, so there is no
C<CREATE INDEX> statement to emit. Adding one is
C<ALTER TABLE ... ADD INDEX>, removing one is C<ALTER TABLE ... DROP INDEX>,
and there is no C<ALTER INDEX> at all -- a changed definition becomes a
drop-then-add pair. For a table that is being B<created> in the same pass the
index is emitted inline by L<DBIO::ClickHouse::Diff::Table>, which is why the
walk here is scoped to tables present on both sides.

=head2 ADD INDEX does not index existing data

C<ALTER TABLE ... ADD INDEX> only affects parts written B<after> it. Existing
parts are indexed by

    ALTER TABLE `t` MATERIALIZE INDEX `idx`;

which is an asynchronous mutation that rewrites every part of the table. That
is a capacity decision, not a schema decision, so this module deliberately
does B<not> emit it -- an upgrade must not silently kick off a full-table
mutation. Run it yourself when the table is small enough or the window is
right.

=head2 Every skipping index the target lacks is dropped

The schema is the single owner of the skipping indexes a table keeps. An index
the live table has and the target does not is dropped, B<including> the last
one: when the target carries no skipping index for a table at all, every index
the live table has goes. That is what lets C<DROP COLUMN> take a column whose
only index reads it -- the server refuses the column drop while the index
stands, so the C<DROP INDEX> has to be there even when the target section for
the table is empty.

The walk covers only the skipping indexes
L<DBIO::ClickHouse::Introspect::Indexes> reads from
C<system.data_skipping_indices>, and only tables present on both sides; a table
being created or dropped is not walked (see L</diff>). An index created by hand
on a table is therefore removed by the next C<upgrade> unless the schema
declares it (C<add_index_declaration>).

=head1 METHODS

=head2 changed_index

    my @changed = changed_index($old_info, $new_info);

Returns the list of field names that differ between two skipping-index infos:
C<expr>, C<type_full> and C<granularity>. Exported for the same reason
L<DBIO::Diff::Compare>'s comparators are: so a caller can ask "did this change?"
without reconstructing the field set.

Unlike core's comparators this applies B<no> desired-state contract. An index
that reached this comparison was declared on both sides, so an C<undef> field
on the target side is a real difference and not an "unprescribed" one.

=head2 diff

    my @ops = DBIO::ClickHouse::Diff::Index->diff(
      $source_indexes, $target_indexes,
      $source_tables,  $target_tables,
      $storage,                                # optional, drives IF EXISTS
    );

Compares the C<data_skipping_indexes> sections of two models. The two
C<tables> sections scope the walk to tables present on B<both> sides
(C<< scope => 'both' >>): indexes of a brand-new table are emitted inline by
L<DBIO::ClickHouse::Diff::Table>, and indexes of a table being dropped go away
with the C<DROP TABLE>, so emitting a standalone C<DROP INDEX> for one of them
would fail against a real server once the table is gone.

Index identity is the index name. Changed definitions become a drop-then-add
pair. Every index missing from the target is dropped, see
L</Every skipping index the target lacks is dropped>. C<$storage> threads through to the constructed ops;
see L</as_sql>.

=head2 as_sql

Renders C<ALTER TABLE ... ADD INDEX ...> or C<ALTER TABLE ... DROP INDEX ...>
through L<DBIO::ClickHouse::DDL::Emit>, so that an added index is spelled
exactly as L<DBIO::ClickHouse::Diff::Table> spells the same index inline in a
C<CREATE TABLE>.

When the op carries C<storage>, the IF [NOT] EXISTS flag is taken from
L<DBIO::Diff::Op/should_emit_if_exists>; otherwise the legacy bare shape is
preserved (C<ALTER TABLE ... ADD INDEX> / C<ALTER TABLE ... DROP INDEX>) so
the existing t/41 cases stay green.

=head2 summary

One indented line naming the skipping index and its table. It says "skipping
index" rather than "index" on purpose -- these are not B-tree indexes, and a
summary that blurred the two would suggest a lookup guarantee ClickHouse never
makes.

=head1 SEE ALSO

=over 4

=item * L<DBIO::ClickHouse::Diff> - the orchestrator that drives this

=item * L<DBIO::ClickHouse::Diff::Table> - renders these inline for new tables

=item * L<DBIO::ClickHouse::DDL::Emit> - C<index_def> and the statement templates rendered here

=item * L<DBIO::ClickHouse::Introspect::Indexes> - produces the model section

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
