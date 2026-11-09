package DBIO::ClickHouse::Diff::Table;
# ABSTRACT: Diff operations for ClickHouse tables, and the no-silent-rebuild policy

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::Diff::Op   ();
use DBIO::Exception  ();
use DBIO::ClickHouse::DDL::Emit qw(
  quote_ident column_def index_def create_table drop_table
  engine_clause partition_by_clause primary_key_clause order_by_clause
  settings_clause
);

__PACKAGE__->mk_diff_accessors(qw/table_name table_info columns skipping_indexes storage settings/);



sub throw_exception {
  my ($self, $message) = @_;
  DBIO::Exception->throw($message);
}

# The four immutable properties. 'list' entries are compared order-preservingly
# and rendered comma-joined; 'scalar' entries are compared as strings.
#
# The order is which one to REPORT, not the CREATE TABLE clause order, and the
# sorting key deliberately comes before the primary key: ClickHouse fills the
# primary key in from ORDER BY when none was declared separately, so changing
# the sorting key changes both. Reporting the primary key there would name the
# mirror instead of the cause and send the operator looking for a PRIMARY KEY
# clause their schema never had.
my @IMMUTABLE = (
  { field => 'engine_expression',     kind => 'scalar', label => 'engine' },
  { field => 'partition_key_entries', kind => 'list',   label => 'partition key (PARTITION BY)' },
  { field => 'sorting_key_entries',   kind => 'list',   label => 'sorting key (ORDER BY)' },
  { field => 'primary_key_entries',   kind => 'list',   label => 'primary key (PRIMARY KEY)' }
);


sub check_rebuild_required {
  my ($class, $source, $target) = @_;
  $source ||= {};
  $target ||= {};

  for my $name (sort keys %$target) {
    my $old = $source->{$name} or next;
    my $new = $target->{$name};

    for my $property (@IMMUTABLE) {
      my $field = $property->{field};

      # Desired-state contract: not prescribed by the target -> not compared.
      next unless defined $new->{$field};

      my ($old_value, $new_value) = $property->{kind} eq 'list'
        ? (_render_key($old->{$field}), _render_key($new->{$field}))
        : (defined $old->{$field} ? $old->{$field} : '', $new->{$field});

      next if $old_value eq $new_value;

      $class->throw_exception(
        _rebuild_message($name, $property->{label}, $old_value, $new_value));
    }
  }

  return 1;
}

sub _render_key {
  my ($entries) = @_;
  return '' unless ref $entries eq 'ARRAY';
  return join ', ', @$entries;
}

sub _rebuild_message {
  my ($table, $label, $old, $new) = @_;

  my $live = quote_ident($table);
  my $new_table = quote_ident($table . '_new');
  $old = '(none)' if $old eq '';
  $new = '(none)' if $new eq '';

  return <<"END_MESSAGE";
Table $live cannot be upgraded in place: its $label changed from
    $old
to
    $new
and ClickHouse fixes that property at CREATE TABLE time -- there is no ALTER
for it. DBIO::ClickHouse::Diff refuses to drop and recreate a data table on
your behalf, because that deletes every row in it and there is no transaction
to undo it with.

Apply the change by hand, in this order:

  1. CREATE TABLE $new_table (...) with the new definition. Take the exact
     statement from DBIO::ClickHouse::DDL->install_ddl(\$schema) and rename the
     table in it.
  2. INSERT INTO $new_table SELECT * FROM $live;
     Then compare the row counts -- this copy is NOT atomic and NOT
     transactional; concurrent inserts land in the old table only.
  3. EXCHANGE TABLES $new_table AND $live;
     Atomic on an Atomic database (the default). On an Ordinary database use
     RENAME TABLE twice instead, and accept the gap between them.
  4. DROP TABLE $new_table;

Re-run the upgrade afterwards; this check will pass and the remaining column
and index changes will be applied normally.
END_MESSAGE
}


sub diff {
  my ($class, $source, $target, $target_columns, $target_indexes, $storage,
      $declared_settings) = @_;
  $declared_settings //= {};
  $source         ||= {};
  $target         ||= {};
  $target_columns //= {};
  $target_indexes //= {};

  $class->check_rebuild_required($source, $target);

  return $class->diff_toplevel($source, $target,
    create => sub {
      my ($name) = @_;
      $class->new(
        action           => 'create',
        table_name       => $name,
        table_info       => $target->{$name},
        columns          => $target_columns->{$name} // [],
        skipping_indexes => $target_indexes->{$name} // {},
        storage          => $storage,
        settings         => $declared_settings->{$name},
      );
    },
    drop => sub {
      my ($name) = @_;
      $class->new(
        action     => 'drop',
        table_name => $name,
        table_info => $source->{$name},
        storage    => $storage,
      );
    },
  );
}


sub as_sql {
  my ($self) = @_;

  my $info    = $self->table_info // {};
  my $if_guard = DBIO::Diff::Op::should_emit_if_exists($self->storage) ? 1 : 0;

  return drop_table(name => $self->table_name, if_exists => $if_guard)
    if $self->action eq 'drop';

  my @body = map { _column_def($_) } @{ $self->columns };

  # Skipping indexes are part of the table body, not a separate statement.
  my $indexes = $self->skipping_indexes // {};
  push @body, index_def($indexes->{$_}) for sort keys %$indexes;

  my @sorting = @{ $info->{sorting_key_entries} // [] };
  my @primary = @{ $info->{primary_key_entries} // [] };

  my @clauses = (engine_clause($info->{engine_expression} // $info->{engine}));
  push @clauses, partition_by_clause($info->{partition_key})
    if defined $info->{partition_key} && length $info->{partition_key};
  push @clauses, primary_key_clause(map { _key_entry($_) } @primary)
    if _key_differs(\@primary, \@sorting);
  push @clauses, order_by_clause(map { _key_entry($_) } @sorting);
  push @clauses, settings_clause($self->settings);

  return create_table(
    name          => $self->table_name,
    columns       => \@body,
    clauses       => \@clauses,
    if_not_exists => $if_guard,
  );
}

# A model column carries the RAW ClickHouse default expression plus the kind
# it was declared with. DEFAULT goes through Emit's column_def; MATERIALIZED /
# ALIAS / EPHEMERAL are a different clause with different semantics (computed,
# or not stored at all), so rendering them as DEFAULT would quietly change what
# the column means -- they are appended as themselves instead.
sub _column_def {
  my ($col) = @_;

  my $kind       = uc($col->{default_kind} // 'DEFAULT');
  my $expression = $col->{default_value};
  my $is_default = $kind eq 'DEFAULT';

  my $def = column_def(
    name    => $col->{column_name},
    type    => ($col->{data_type} // 'String'),
    default => ($is_default ? $expression : undef)
  );

  $def .= " $kind $expression"
    if !$is_default && defined $expression && length $expression;

  return $def;
}

# A bare column name is an identifier and gets quoted; anything else is a key
# expression (toYYYYMM(ts), cityHash64(id)) and has to reach Emit as a SCALAR
# ref, or it would come out backtick-quoted as one long identifier.
sub _key_entry {
  my ($entry) = @_;
  return $entry if $entry =~ /\A\w+\z/;
  my $expression = $entry;
  return \$expression;
}

sub _key_differs {
  my ($left, $right) = @_;
  return 1 if @$left != @$right;
  for my $i (0 .. $#$left) {
    return 1 if $left->[$i] ne $right->[$i];
  }
  return 0;
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

DBIO::ClickHouse::Diff::Table - Diff operations for ClickHouse tables, and the no-silent-rebuild policy

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Table-level diff operations for ClickHouse -- C<CREATE TABLE> and
C<DROP TABLE> -- plus L</check_rebuild_required>, the policy that refuses to
paper over a change ClickHouse cannot make in place.

A C<create> op carries the target table's columns and data-skipping indexes so
that L</as_sql> emits the whole definition as one statement. That is not a
stylistic preference: a ClickHouse table cannot be built up with
C<ALTER TABLE ADD COLUMN> from nothing, because C<ENGINE> and the sorting key
have to be present at C<CREATE> time and can never be set afterwards.

=head1 METHODS

=head2 throw_exception

    $class->throw_exception($message);

Raises a L<DBIO::Exception>. The diff layer has no storage to route through
(a diff is computed from two model hashrefs and may never touch a connection),
so this is the family's C<throw_exception> contract reduced to what is
available here. It exists so that no error path in this distribution reaches
for a bare C<die> or C<croak>.

=head2 check_rebuild_required

    DBIO::ClickHouse::Diff::Table->check_rebuild_required($source_tables, $target_tables);

Walks the tables present in B<both> models and throws on the first immutable
property that differs. Called from L</diff>, so every route into the diff --
C<< $deploy->diff >>, C<< $diff->operations >>, a direct
C<< Diff::Table->diff >> in a test -- is covered by the same check.

The comparison honours core's desired-state contract
(L<DBIO::Diff::Compare/changed_fields>): a property the B<target> side leaves
undefined was not prescribed by the desired state and is not compared. A model
assembled by hand that only carries C<table_name> therefore never trips the
policy, while a model introspected from a live server always carries all four.

C<engine_expression> is compared rather than C<engine_full>, deliberately.
C<engine_full> also carries C<SETTINGS>, and the server fills those in with its
own defaults (C<index_granularity = 8192> and friends), so comparing it would
throw on every table of every schema that never mentioned a setting.

=head2 diff

    my @ops = DBIO::ClickHouse::Diff::Table->diff(
        $source_tables, $target_tables,
        $target_columns, $target_skipping_indexes,
        $storage,                                # optional, drives IF EXISTS
        $declared_settings,                      # optional, { table => \%settings }
    );

Runs L</check_rebuild_required> first, then the ordinary create/drop walk:
a table only in the target is created (with its columns and skipping indexes
inline), a table only in the source is dropped. Tables present on both sides
produce no table-level operation -- their columns and indexes are handled by
L<DBIO::ClickHouse::Diff::Column> and L<DBIO::ClickHouse::Diff::Index>.

C<$storage> is optional: when given, the resulting ops stash it and
L</as_sql> will pass an C<if_not_exists> / C<if_exists> flag to the Emit
functions based on L<DBIO::Diff::Op/should_emit_if_exists>. Without it, the
returned SQL stays bare -- the legacy shape t/40 / t/41 already pin against.

C<$declared_settings> is optional; a table only in the target picks its entry
up for the C<SETTINGS> clause of its C<CREATE TABLE>. Tables present on both
sides are not compared on settings.

Views must be filtered out by the caller; see
L<DBIO::ClickHouse::Diff/Views are only created>.

=head2 as_sql

Renders C<DROP TABLE> or the full C<CREATE TABLE> through
L<DBIO::ClickHouse::DDL::Emit>, so the diff's C<CREATE TABLE> is
char-for-char the shape L<DBIO::ClickHouse::DDL> emits for a fresh install.

The engine clauses are emitted in the order C<SHOW CREATE TABLE> prints them:
C<ENGINE>, C<PARTITION BY>, C<PRIMARY KEY>, C<ORDER BY>. Two of them are
conditional:

=over 4

=item * C<PRIMARY KEY> is emitted only when it actually differs from the
sorting key. ClickHouse fills the primary key in from C<ORDER BY> when it was
not declared separately, so restating it would make every table look like it
declared a redundant prefix.

=item * C<SETTINGS> is emitted only from the settings the schema B<declares>
(C<clickhouse_table({ settings =E<gt> {...} })>, handed in as
C<declared_settings>), rendered by L<DBIO::ClickHouse::DDL::Emit/settings_clause>
exactly as the install DDL does -- so a table created by an upgrade is the
table a fresh install makes. The model's C<engine_full> is never used: it
reports the server's own defaults, and freezing those into a migration pins a
server default into user DDL.

=back

The two statement forms accept an optional C<if_not_exists> /
C<if_exists> flag from L<DBIO::ClickHouse::DDL::Emit> -- the flag is
populated once here, from
L<DBIO::Diff::Op/should_emit_if_exists> on the op's stashed C<storage>, and
passed through to the L<DBIO::ClickHouse::DDL::Emit/create_table>
or L<DBIO::ClickHouse::DDL::Emit/drop_table> call. A storage that
did not declare the F12 capability (or none given) keeps the legacy bare
shape, exactly as t/40 / t/41 already pin.

=head2 summary

One line naming the table and whether it is created (C<+>) or dropped (C<->).

=head1 THE REBUILD POLICY

Four properties of a MergeTree table are fixed the moment it is created and
cannot be changed by any C<ALTER>:

=over 4

=item * the B<engine> (C<MergeTree> vs C<ReplacingMergeTree(version)>, ...)

=item * the B<sorting key> -- C<ORDER BY>, the thing ClickHouse calls the
primary key

=item * the B<primary key> prefix, when one was declared separately

=item * the B<partition key> -- C<PARTITION BY>

=back

The only way to change any of them is to build a new table and move the data.
This module does B<not> do that, and it does not silently do nothing either.
L</check_rebuild_required> throws a L<DBIO::Exception> naming the table, the
property, both values, and the four statements the operator has to run.

Why refuse rather than emit C<DROP TABLE> + C<CREATE TABLE>: on every other
engine in this family a table-level diff op is a schema change; here it would
be a B<data> deletion. C<DROP TABLE> on ClickHouse takes billions of rows with
it, there is no transaction to roll back (C<docs/adr/0003-no-transactions-policy.md>),
and the failure would be discovered after the fact. An upgrade that stops with
an actionable message is strictly better than one that succeeds by deleting the
warehouse.

Why refuse rather than emit nothing: the plain create/drop walk only looks at
table B<names>, so a table present on both sides with a different sorting key
produces no operation at all. The upgrade would report success, the sorting key
would still be the old one, and every query written for the new one would do a
full scan. Silence is the worst of the three options.

=head1 SEE ALSO

=over 4

=item * L<DBIO::ClickHouse::Diff> - the orchestrator that drives this

=item * L<DBIO::ClickHouse::DDL::Emit> - the statement templates rendered here

=item * L<DBIO::ClickHouse::Introspect::Tables> - produces the model section

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
