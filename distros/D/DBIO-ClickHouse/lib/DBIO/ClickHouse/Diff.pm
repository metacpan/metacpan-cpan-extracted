package DBIO::ClickHouse::Diff;
# ABSTRACT: Compare two introspected ClickHouse models

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Base';

use DBIO::ClickHouse::Diff::Table;
use DBIO::ClickHouse::Diff::Column;
use DBIO::ClickHouse::Diff::Index;
use DBIO::ClickHouse::Diff::View;


sub _build_operations {
  my ($self) = @_;

  my $source_tables = _diffable_tables($self->source->{tables});
  my $target_tables = _diffable_tables($self->target->{tables});

  # The storage is optional; when given it gates the F12 capability check
  # that decides whether diff ops emit IF [NOT] EXISTS guards in their as_sql.
  # Without it (or with one that doesn't declare the capability) the rendered
  # SQL stays bare -- the legacy shape t/40 and t/41 already pin.
  my $storage = $self->{storage};

  my @ops;

  # A view is dropped before the tables go: it may select from one of them.
  # The views to create or replace come last, below.
  my @view_ops = DBIO::ClickHouse::Diff::View->diff(
    $self->source->{tables}, $self->{declared_views}, $storage,
    $self->target->{tables},
  );
  push @ops, grep { $_->action eq 'drop' } @view_ops;

  push @ops, DBIO::ClickHouse::Diff::Table->diff(
    $source_tables, $target_tables,
    $self->target->{columns}, $self->target->{data_skipping_indexes},
    $storage, $self->{declared_settings},
  );
  # A skipping index is dropped before the column walk: the server refuses to
  # drop (or retype) a column an index still reads. An index added or
  # redefined follows the columns, because it may read a column added above.
  my @index_ops = DBIO::ClickHouse::Diff::Index->diff(
    $self->source->{data_skipping_indexes}, $self->target->{data_skipping_indexes},
    $source_tables, $target_tables,
    $storage,
  );
  push @ops, grep { $_->action eq 'drop' } @index_ops;
  push @ops, DBIO::ClickHouse::Diff::Column->diff(
    $self->source->{columns}, $self->target->{columns},
    $source_tables, $target_tables,
    $storage,
  );
  push @ops, grep { $_->action ne 'drop' } @index_ops;
  # Last: a view may select from a table or column created above.
  push @ops, grep { $_->action ne 'drop' } @view_ops;

  return \@ops;
}

# Views have operations of their own (Diff::View); see "Views follow the
# schema's declaration" above. Filtering them here rather than in each op
# class means every walk -- tables, columns, indexes -- agrees on which
# sources are in scope, because they are all scoped by these two hashrefs.
sub _diffable_tables {
  my ($tables) = @_;
  return {} unless ref $tables eq 'HASH';
  return {
    map  { $_ => $tables->{$_} }
    grep { (($tables->{$_} || {})->{kind} // 'table') ne 'view' }
    keys %$tables
  };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ClickHouse::Diff - Compare two introspected ClickHouse models

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::ClickHouse::Diff> compares two introspected ClickHouse models
(produced by L<DBIO::ClickHouse::Introspect>) and emits a list of structured
diff operations that can be rendered to SQL or to a human-readable summary.

    my $diff = DBIO::ClickHouse::Diff->new(
        source => $current_model,
        target => $desired_model,
    );

    if ($diff->has_changes) {
        print $diff->as_sql;
        print $diff->summary;
    }

Operations are emitted in dependency order: tables, index drops, columns,
the other data-skipping index operations, then views. An index drop comes
before the column walk because the server refuses to drop a column an index
still reads.

=head1 BOTH SIDES MUST BE INTROSPECTED

The comparison is done on the B<native> ClickHouse type strings the model
carries (C<LowCardinality(Nullable(String))>, C<Decimal(10, 2)>), not on
portable DBIO type names. That is what makes it exact -- and it means a model
hand-assembled from C<column_info> is not a valid input: the DDL layer maps the
whole C<varchar> / C<char> / C<text> / C<json> family onto C<String>, so such a
target would differ from the live side on every string column and never
converge. Build the desired side the way L<DBIO::ClickHouse::Deploy> does:
deploy the install DDL into a scratch database and introspect that.

=head1 WHAT THIS DIFF WILL NOT DO

=head2 It will not silently rebuild a table

C<ENGINE>, C<ORDER BY>, C<PRIMARY KEY> and C<PARTITION BY> are fixed at
C<CREATE TABLE> time on ClickHouse. A change to any of them throws a
L<DBIO::Exception> naming the table, the property and the statements to run
by hand, rather than emitting a C<DROP TABLE> that would delete the data or --
worse -- emitting nothing at all and reporting success. The policy, and why it
is a refusal rather than a rebuild, is documented in
L<DBIO::ClickHouse::Diff::Table/THE REBUILD POLICY>.

Because the check runs while the operation list is built, it fires from
C<has_changes>, C<as_sql> and C<summary> alike -- there is no route into the
diff that skips it.

=head2 It drops every skipping index the schema does not declare

A C<DROP INDEX> is emitted for each data-skipping index a surviving table has
and the target lacks, also when the target declares none for that table: the
column drop of a column whose last index reads it needs it. An index created by
hand is therefore removed unless the schema declares it. See
L<DBIO::ClickHouse::Diff::Index/Every skipping index the target lacks is dropped>.

=head2 Views follow the schema's declaration

Views are filtered out of both models before the table, column and index walks.
That keeps L<DBIO::ClickHouse::Diff::Column> from emitting C<ALTER TABLE ...
MODIFY COLUMN> against a view, and a view's C<CREATE TABLE> from being rendered
out of its C<kind>. Their own operations come from
L<DBIO::ClickHouse::Diff::View>, against the optional C<declared_views>
constructor argument (C<< { view =E<gt> $select_sql } >>, built by
L<DBIO::ClickHouse::DDL/declared_views> from the schema itself, the selection
C<install_ddl> uses):

=over 4

=item * a declared view the live model lacks gets a C<CREATE VIEW>;

=item * a declared view whose live definition differs gets a C<CREATE OR
REPLACE VIEW> (compared as the server holds the text, see
L<DBIO::ClickHouse::Diff::View/What "differs" means>);

=item * a live view the schema does not declare gets a C<DROP VIEW>, emitted
B<before> the table operations; create and replace come after all table, column
and index operations (no opt-in -- a view holds no data).

=back

A B<materialized view> holds data, so a live one that the schema does not
declare, or declares as a plain view, is not dropped or replaced: the diff
throws a L<DBIO::Exception> naming it, while the operation list is built and so
before any statement runs. Without C<declared_views> no view operation is
produced and no view is refused.

=head1 NOT PART OF THE MODEL, NOT PART OF THE DIFF

Three things the introspector reads but this diff deliberately ignores, because
the desired side can never carry them and comparing them would delete or
freeze live state on the first upgrade: table and column B<comments>,
per-column B<compression codecs>, and the engine's B<SETTINGS> (the server
fills those with its own defaults; an existing table's settings are never
compared). One exception, for a table the diff B<creates>: the optional
C<declared_settings> constructor argument (C<< { table =E<gt> \%settings } >>,
built by L<DBIO::ClickHouse::DDL/declared_settings>) is rendered as the
C<SETTINGS> clause of that C<CREATE TABLE>, so the table does not come into
being with server defaults the schema never asked for. Foreign keys and unique constraints do not
appear at all -- ClickHouse has neither, and the model's C<foreign_keys> and
C<indexes> sections are always empty (C<docs/adr/0004-no-foreign-keys.md>).

=head1 SEE ALSO

=over 4

=item * L<DBIO::ClickHouse::Deploy> - builds the desired model and applies the diff

=item * L<DBIO::ClickHouse::Introspect> - produces both models

=item * L<DBIO::ClickHouse::DDL::Emit> - the statement shapes the ops render through

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
