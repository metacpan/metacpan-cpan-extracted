package DBIO::SQLite::Diff;
# ABSTRACT: Compare two introspected SQLite models

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Base';

use DBIO::SQLite::Diff::Table;
use DBIO::SQLite::Diff::Column;
use DBIO::SQLite::Diff::Index;
use DBIO::SQLite::Diff::Rebuild;
use DBIO::SQLite::Diff::View;
use DBIO::SQLite::Util qw(
  comparable_statement create_name_index foreign_key_action refuse_qualified_name
  split_type_size sql_tokens
);



# The introspected spelling of a compiled default. A plain value becomes the
# literal install_ddl writes for it, by the same function and with the column's
# type, which decides whether a value of digits is a string, so the two cannot
# drift apart. Literal SQL comes out of its scalar ref, without the parentheses
# of DEFAULT (expr), which the PRAGMA does not report. Whatever follows DEFAULT
# and starts with "(" is that form, so the closing one is the last character --
# no matching needed.
sub _compiled_default {
  my ($default, $type) = @_;
  return $default unless defined $default;
  return DBIO::SQLite::Util::default_literal_sql($default, $type)
    unless ref $default eq 'SCALAR';
  my $sql = $$default;
  $sql =~ s/\A\s+|\s+\z//g;
  $sql =~ s/\A\(\s*(.*?)\s*\)\z/$1/s;
  return $sql;
}

sub target_from_compiled {
  my ($class, $compiled) = @_;
  my (%tables, %columns);
  for my $tname (keys %{ $compiled->{tables} // {} }) {
    my $t = $compiled->{tables}{$tname};
    refuse_qualified_name(table => $tname);
    $tables{$tname} = { table_name => $tname };

    # The key in declared order; the columns come in column order.
    my @pk = @{ $t->{primary_key} // [] };
    my %pk_position;
    @pk_position{@pk} = 1 .. @pk;

    my @cols;
    for my $c (@{ $t->{columns} // [] }) {
      # The type and its size apart, as the introspected model has them.
      my ($type, $size) = split_type_size($c->{native_type});
      push @cols, {
        column_name   => $c->{column_name},
        data_type     => $type,
        (defined $size ? (size => $size) : ()),
        not_null      => ($c->{not_null} ? 1 : 0),
        default_value => _compiled_default($c->{default}, $c->{native_type}),
        is_pk         => ($c->{is_pk} ? 1 : 0),
        pk_position   => $pk_position{ $c->{column_name} } // 0,
      };
    }
    $columns{$tname} = \@cols;
  }
  return { tables => \%tables, columns => \%columns, indexes => {}, foreign_keys => {} };
}


sub statements {
  my ($self) = @_;
  return map { $_->can('statements') ? $_->statements : $_->as_sql }
    @{ $self->operations };
}

sub _is_generated {
  my ($column) = @_;
  my $hidden = $column->{hidden} // 0;
  return $hidden == 2 || $hidden == 3;
}

# What an entry of a model's tables section is: 'view', 'virtual' or 'table'.
# A view says so in its kind. A virtual table has kind 'table' -- that is what
# sqlite_master calls it -- and is known by its statement. Everything else is
# a plain table, an entry without kind and without statement included: the
# models built by hand and by target_from_compiled have nothing but plain
# tables.
sub _kind {
  my ($entry) = @_;
  return 'view' if ($entry->{kind} // '') eq 'view';
  my @tokens = sql_tokens($entry->{sql} // '');
  return defined create_name_index(\@tokens, 'VIRTUAL', 'TABLE')
    ? 'virtual' : 'table';
}

# A tables section sorted by that: { view => {...}, virtual => {...},
# table => {...} }, each keyed by name like the section itself.
sub _by_kind {
  my ($tables) = @_;
  my %by = (view => {}, virtual => {}, table => {});
  $by{ _kind($tables->{$_}) }{$_} = $tables->{$_} for keys %{ $tables // {} };
  return \%by;
}

# The refusals: a name that is a table on both sides, and a virtual one on at
# least one of them, without being the same virtual table on both. SQLite
# cannot alter a virtual table, and nothing may stand in for that -- a rebuild
# copies what SELECT shows and loses the rest of what the module stores.
sub _refused_tables {
  my ($src, $tgt) = @_;

  my @ops;
  my %seen;
  for my $name (sort grep { !$seen{$_}++ }
      keys %{ $src->{virtual} }, keys %{ $tgt->{virtual} }) {
    my ($old, $new) = ($src->{virtual}{$name}, $tgt->{virtual}{$name});

    my $reason;
    if ($old && $new) {
      next if comparable_statement($old->{sql}, 'VIRTUAL', 'TABLE')
        eq comparable_statement($new->{sql}, 'VIRTUAL', 'TABLE');
      $reason = "its definition as a virtual table differs from the target's, "
        . 'and SQLite cannot alter a virtual table -- a rebuild would lose '
        . 'what its module stores';
    }
    elsif ($old && $tgt->{table}{$name}) {
      $reason = 'it is a virtual table in the source and a plain table in '
        . 'the target, and SQLite cannot alter a virtual table -- replacing '
        . 'it would lose what its module stores';
    }
    elsif ($new && $src->{table}{$name}) {
      $reason = 'it is a plain table in the source and a virtual table in '
        . 'the target, and no statement turns the one into the other -- '
        . 'replacing it would lose its rows';
    }
    else {
      next;    # on one side only, or a view on the other: created or dropped
    }

    push @ops, DBIO::SQLite::Diff::Table->new(
      action     => 'refuse',
      table_name => $name,
      table_info => $new,
      reason     => $reason,
    );
  }
  return @ops;
}

# The primary key of a table as its columns in the order of the key:
# pk_position where the model has it, column order where it does not.
sub _primary_key {
  my ($columns) = @_;
  my @at = grep { $columns->[$_]{is_pk} } 0 .. $#$columns;
  return map { $columns->[$_]{column_name} } sort {
    ($columns->[$a]{pk_position} // 0) <=> ($columns->[$b]{pk_position} // 0)
      || $a <=> $b
  } @at;
}

# The UNIQUE constraints of a table: the column lists of its automatic indexes
# of origin "u", which is how PRAGMA index_list reports a constraint, written
# on the column or on the table alike. A set -- SQLite keeps one index for a
# constraint declared twice.
sub _unique_constraints {
  my ($indexes) = @_;
  return map { join(', ', @{ $_->{columns} // [] }) => 1 }
    grep { ($_->{origin} // '') eq 'u' } values %{ $indexes // {} };
}

# One foreign key as what it does: its columns in order, the table and the
# columns it points at, and its two actions. Names and actions are compared in
# any letter case, as SQLite reads them; an action nobody declared is NO
# ACTION, which is what PRAGMA foreign_key_list reports for it. The value is
# the key as the summary shows it.
sub _foreign_key {
  my ($fk) = @_;
  my @from = @{ $fk->{from_columns} // [] };
  my @to   = grep { defined } @{ $fk->{to_columns} // [] };
  my %action = map {
    $_ => foreign_key_action($fk->{$_}, 'foreign key (' . join(', ', @from)
      . ') -> ' . ($fk->{to_table} // '?'))
      // 'NO ACTION'
  } qw(on_update on_delete);

  my $key = lc join "\0", join(',', @from), $fk->{to_table} // '',
    join(',', @to), @action{qw(on_update on_delete)};
  my $shown = sprintf '(%s) -> %s%s', join(', ', @from), $fk->{to_table} // '?',
    @to ? ' (' . join(', ', @to) . ')' : '';
  $shown .= " ON UPDATE $action{on_update}" if $action{on_update} ne 'NO ACTION';
  $shown .= " ON DELETE $action{on_delete}" if $action{on_delete} ne 'NO ACTION';
  return ($key => $shown);
}

# What only one of two sets has, as reasons: "$what $shown added" for the
# target's, "... removed" for the source's.
sub _set_changes {
  my ($what, $old, $new) = @_;
  return (
    (map { "$what $new->{$_} added" }   grep { !exists $old->{$_} } sort keys %$new),
    (map { "$what $old->{$_} removed" } grep { !exists $new->{$_} } sort keys %$old),
  );
}

# What two statements declare and no PRAGMA reports, compared: the CHECK,
# COLLATE and generated clause of every column both tables have, and the
# CHECK constraints of the table. Read by Diff::Column's reader. A statement
# it cannot follow is not passed over: then the two statements are compared
# as they stand, name aside, and any difference is a reason. That errs
# towards the rebuild, and a rebuild ends it -- afterwards the live statement
# is the target's.
#
# No result class can declare any of these clauses, so a target deployed from
# result classes never has one, and "the target has none" says "not stated",
# not "none wanted". They follow the desired-state contract core's
# DBIO::Diff::Compare::changed_fields has for a column's fields (core ADR
# 0019): what the target leaves unstated is not compared, what it states is
# compared with the source, and stated against missing is a change. A column
# whose target has no CHECK, no COLLATE or is not generated is not compared in
# that clause, and neither are the table's CHECKs when the target has none.
# A target that states CHECKs has stated all of them: the sets are compared,
# and one only the source has goes.
sub _declared_changes {
  my ($old_sql, $new_sql, $shared) = @_;

  my ($old, $new) = map { DBIO::SQLite::Diff::Column::_declarations($_) }
    $old_sql, $new_sql;
  my $readable = $old && $new
    && !grep { !$old->{columns}{$_} || !$new->{columns}{$_} } @$shared;

  unless ($readable) {
    return if comparable_statement($old_sql, 'TABLE')
      eq comparable_statement($new_sql, 'TABLE');
    return 'the CREATE TABLE statements differ, and one of them cannot be '
      . 'read clause by clause';
  }

  # Each clause is compared only where the target states it -- see above.
  my @reasons;
  for my $name (@$shared) {
    my ($was, $is) = ($old->{columns}{$name}, $new->{columns}{$name});
    push @reasons, _set_changes("check on column $name:",
      map { +{ map { $_ => "($_)" } @{ $_->{checks} } } } $was, $is)
      if @{ $is->{checks} };
    push @reasons, sprintf 'collation of column %s: %s -> %s', $name,
      map { $_->{collate} // 'none' } $was, $is
      if defined $is->{collate} && ($was->{collate} // '') ne $is->{collate};
    push @reasons, sprintf 'generated expression of column %s: %s -> %s', $name,
      map { defined $_->{generated} ? "($_->{generated})" : 'none' } $was, $is
      if defined $is->{generated} && ($was->{generated} // '') ne $is->{generated};
  }
  push @reasons, _set_changes('table check',
    map { +{ map { $_ => "($_)" } @{ $_->{checks} } } } $old, $new)
    if @{ $new->{checks} };
  return @reasons;
}

# Everything a plain table declares beyond the fields of its columns, compared
# between the two models: why the table has to be rebuilt, as a list of
# reasons, empty when nothing differs (karr k72). See "When a table is
# rebuilt" for each arm and for what is left out on purpose.
sub _table_changes {
  my ($source, $target, $table) = @_;
  my ($old, $new) = map { $_->{tables}{$table} } $source, $target;
  my ($old_columns, $new_columns) =
    map { $_->{columns}{$table} // [] } $source, $target;
  my @reasons;

  # a. The primary key.
  my ($old_pk, $new_pk) =
    map { join ', ', _primary_key($_) } $old_columns, $new_columns;
  push @reasons, sprintf 'primary key (%s) -> (%s)', $old_pk, $new_pk
    if $old_pk ne $new_pk;

  # b. The UNIQUE constraints.
  push @reasons, _set_changes('unique',
    map { my %set = _unique_constraints(($_->{indexes} // {})->{$table});
          +{ map { $_ => "($_)" } keys %set } } $source, $target);

  # c. The foreign keys, as a set: a key the database holds twice is one, and
  # the order of the lines is none of it (karr k74). A key of the target over
  # a column the source has not is left out -- it comes with the column, by
  # ADD COLUMN or by the rebuild that column causes (karr k64).
  my %has = map { lc $_->{column_name} => 1 } @$old_columns;
  my %old_fk = map { _foreign_key($_) }
    @{ ($source->{foreign_keys} // {})->{$table} // [] };
  my %new_fk = map { _foreign_key($_) }
    grep { !grep { !$has{ lc $_ } } @{ $_->{from_columns} // [] } }
    @{ ($target->{foreign_keys} // {})->{$table} // [] };
  push @reasons, _set_changes('foreign key', \%old_fk, \%new_fk);

  # d. What only the statements say. A source without one states nothing.
  if (length($old->{sql} // '')) {
    my %in_new = map { $_->{column_name} => 1 } @$new_columns;
    my @shared = grep { $in_new{$_} } map { $_->{column_name} } @$old_columns;
    push @reasons, _declared_changes($old->{sql}, $new->{sql}, \@shared);
  }

  # e. The two table options, under the same contract as d: an option the
  # target has and the source has not is a change, one only the source has is
  # not stated by the target and is left alone.
  for my $option ([ without_rowid => 'WITHOUT ROWID' ], [ strict => 'STRICT' ]) {
    my ($field, $shown) = @$option;
    push @reasons, "$shown added" if $new->{$field} && !$old->{$field};
  }

  return @reasons;
}

# A column that takes a NOT NULL value from nowhere when it is added to a table
# that holds rows: NOT NULL, no default (or DEFAULT NULL), and not one SQLite
# fills itself -- the rowid alias, a generated column. Used here and by
# DBIO::SQLite::Deploy for a plain ADD COLUMN (karr k91).
sub _added_not_null_without_default {
  my ($info) = @_;
  return 0 unless $info->{not_null};
  return 0 if defined $info->{default_value} && uc $info->{default_value} ne 'NULL';
  return 0 if $info->{is_auto_increment} || _is_generated($info);
  return 0 if $info->{is_pk} && uc($info->{data_type} // '') eq 'INTEGER';
  return 1;
}

sub _build_operations {
  my ($self) = @_;
  my ($source, $target) = ($self->source, $self->target);

  # What each name is, before anything is walked (karr k67). The walks below
  # are written for tables, and each of them does to a view or a virtual
  # table something SQLite refuses.
  my $src = _by_kind($source->{tables});
  my $tgt = _by_kind($target->{tables});

  # Views: dropped and created as views, replaced when the definition differs.
  my @view_ops = DBIO::SQLite::Diff::View->diff(
    $src->{view}, $tgt->{view}, $source->{triggers},
  );

  # Tables come and go the same way whether plain or virtual: the stored
  # statement creates either, DROP TABLE removes either. A name that is a view
  # on the other side is not on that side as far as this walk goes, so a table
  # that becomes a view is dropped here and a view that becomes a table is
  # created here.
  my %src_tables = (%{ $src->{table} }, %{ $src->{virtual} });
  my %tgt_tables = (%{ $tgt->{table} }, %{ $tgt->{virtual} });
  my @table_ops = DBIO::SQLite::Diff::Table->diff(
    \%src_tables, \%tgt_tables,
    $target->{columns}, $target->{foreign_keys}, $target->{indexes},
  );

  my @refused = _refused_tables($src, $tgt);
  push @table_ops, @refused;

  # From here on only plain tables: the column walk takes the tables that are
  # plain on both sides.
  my @col_ops = DBIO::SQLite::Diff::Column->diff(
    $source->{columns}, $target->{columns},
    $src->{table},      $tgt->{table},
  );

  # SQLite cannot ALTER a column's type / nullability / default in place. A
  # table carrying any such change must be rebuilt wholesale (create-new /
  # copy / drop / rename), which also subsumes that table's add / drop column
  # ops. We can only rebuild faithfully when the target table's original
  # CREATE statement is available (the introspect path provides it; the
  # compiled-model path does not) -- otherwise the per-column ops stand, and
  # an alter among them refuses to render: as_sql of the diff throws (karr
  # k73).
  #
  # The same goes for a column that is added with a declaration ADD COLUMN
  # cannot express -- UNIQUE, PRIMARY KEY, a part in a table constraint.
  # Diff::Column marks those, and only where there is a statement (karr k64).
  #
  # Every reason is kept, in the order found: the rebuild says why it is there.
  my %reasons;
  for my $op (grep { $_->action eq 'alter' || $_->needs_rebuild } @col_ops) {
    my $table = $op->table_name;
    next unless ($tgt->{table}{$table} // {})->{sql};
    push @{ $reasons{$table} }, $op->action eq 'alter'
      ? sprintf('column %s: %s', $op->column_name, $op->changes)
      : sprintf('column %s is added with a declaration ADD COLUMN cannot carry '
          . '(UNIQUE, PRIMARY KEY, a table constraint or a non-constant DEFAULT)',
          $op->column_name);
  }

  # And for what a table declares beyond its columns' fields: key, UNIQUE,
  # foreign keys, CHECK, COLLATE, generated expressions, WITHOUT ROWID and
  # STRICT. None of it can be altered in place, so any difference rebuilds the
  # table -- under the same condition, a target that has the statement. A
  # model without one holds no indexes and no foreign keys by construction,
  # which says "not stated", not "none" (karr k72).
  for my $table (sort keys %{ $tgt->{table} }) {
    next unless $src->{table}{$table} && $tgt->{table}{$table}{sql};
    my @changes = _table_changes($source, $target, $table) or next;
    push @{ $reasons{$table} }, @changes;
  }

  my %needs_rebuild = map { $_ => 1 } keys %reasons;

  # What a rebuild asks of the rows the table holds (karr k91): the column ops
  # that go into the rebuild still know which column becomes NOT NULL and which
  # NOT NULL column has no default to fill the copied rows with.
  my %data_checks;
  for my $op (grep { $needs_rebuild{ $_->table_name } } @col_ops) {
    my $new = $op->new_info or next;
    if ($op->action eq 'alter') {
      push @{ $data_checks{ $op->table_name } },
        { column => $op->column_name, kind => 'nulls' }
        if $new->{not_null} && !$op->old_info->{not_null};
    }
    elsif ($op->action eq 'add') {
      push @{ $data_checks{ $op->table_name } },
        { column => $op->column_name, kind => 'added' }
        if _added_not_null_without_default($new);
    }
  }

  # The column ops that go into the rebuild leave with it, and so does what
  # they say about stored values: a dropped column is gone, a lossy change
  # may alter what the copy writes. The rebuild reports it (karr core k399).
  my %lossy_columns;
  for my $op (grep { $needs_rebuild{ $_->table_name } } @col_ops) {
    push @{ $lossy_columns{ $op->table_name } }, $op->column_name
      if $op->action eq 'drop' || $op->lossy;
  }

  @col_ops = grep { !$needs_rebuild{ $_->table_name } } @col_ops;

  my @rebuild_ops;
  for my $table (sort keys %needs_rebuild) {
    my %src_names = map { $_->{column_name} => 1 }
      @{ $source->{columns}{$table} // [] };

    # A column the new table generates takes no data: SQLite refuses the
    # INSERT (karr k70). PRAGMA table_xinfo marks it, hidden 2 for a VIRTUAL
    # and 3 for a STORED one.
    my @copy = map { $_->{column_name} }
      grep { $src_names{ $_->{column_name} } && !_is_generated($_) }
      @{ $target->{columns}{$table} // [] };

    # The triggers of the live table go with the DROP; the rebuild creates
    # them again from their statements (karr k69). A model that has no
    # triggers section has none.
    my $triggers = ($source->{triggers} // {})->{$table} // {};

    push @rebuild_ops, DBIO::SQLite::Diff::Rebuild->new(
      table_name   => $table,
      table_sql    => $tgt->{table}{$table}{sql},
      copy_columns => \@copy,
      triggers     => [ map { $triggers->{$_}{sql} } sort keys %$triggers ],
      reasons      => $reasons{$table},
      data_checks  => $data_checks{$table} // [],
      lossy_columns => $lossy_columns{$table} // [],
    );

    # The rebuild drops the table and with it every index; re-create the
    # table's explicit (non-auto) target indexes afterwards.
    my $tgt_idx = $target->{indexes}{$table} // {};
    for my $name (sort keys %$tgt_idx) {
      my $info = $tgt_idx->{$name};
      next if DBIO::SQLite::Diff::Index::_is_auto($info);
      push @rebuild_ops, DBIO::SQLite::Diff::Index->new(
        action     => 'create',
        table_name => $table,
        index_name => $name,
        index_info => $info,
      );
    }
  }

  # Normal index diff for every table that is NOT being rebuilt (rebuilt
  # tables' indexes are handled above). The plain tables of the two sides are
  # threaded through so Diff::Index can suppress a standalone DROP INDEX for
  # any index whose owning table is itself being dropped this pass -- SQLite's
  # DROP TABLE already removes those indexes (karr k14). A view and a virtual
  # table have no index of their own, and a refused table gets no op but its
  # refusal.
  my %src_idx = %{ $source->{indexes} // {} };
  my %tgt_idx = %{ $target->{indexes} // {} };
  delete @src_idx{ keys %needs_rebuild, keys %{ $src->{view} }, keys %{ $src->{virtual} } };
  delete @tgt_idx{ keys %needs_rebuild, keys %{ $tgt->{view} }, keys %{ $tgt->{virtual} } };
  for my $op (@refused) {
    delete $src_idx{ $op->table_name };
    delete $tgt_idx{ $op->table_name };
  }
  my @index_ops = DBIO::SQLite::Diff::Index->diff(
    \%src_idx, \%tgt_idx, $src->{table}, $tgt->{table},
  );

  # The order -- see "The order of the operations". Each step is where it is
  # because of something SQLite checks, measured on libsqlite 3.51.1:
  #
  #   1 DROP VIEW first. ALTER TABLE ... DROP COLUMN reads the whole schema
  #     and fails on any view that names something that is gone (`error in
  #     view v: no such column`), on whichever table the column is; and a view
  #     that becomes a table has to be out of the way of the CREATE TABLE.
  #   2 DROP INDEX before DROP COLUMN: SQLite refuses to drop a column an
  #     index covers (`error in index ... after drop column`).
  #   3 Tables come and go. Neither CREATE TABLE nor DROP TABLE reads the rest
  #     of the schema.
  #   4 ADD COLUMN does not read it either, and wants only the table.
  #   5 The rebuilds, each followed by its indexes. They rename under
  #     legacy_alter_table and so read nothing.
  #   6 CREATE VIEW, now that every table and column the target's views name
  #     is there -- CREATE VIEW itself would not notice, but
  #   7 DROP COLUMN does, and by now no view in the database names anything
  #     that is about to go: what is left are the target's views.
  #   8 CREATE INDEX last, over columns that all exist.
  my $is = sub { my $action = shift; grep { $_->action eq $action } @_ };
  return [
    $is->(drop => @view_ops),
    $is->(drop => @index_ops),
    @table_ops,
    (grep { $_->action ne 'drop' } @col_ops),
    @rebuild_ops,
    $is->(create => @view_ops),
    $is->(drop   => @col_ops),
    $is->(create => @index_ops),
  ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::Diff - Compare two introspected SQLite models

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::SQLite::Diff> compares two introspected SQLite database models
(as produced by L<DBIO::SQLite::Introspect>) and produces a list of
structured diff operations. These operations can then be rendered to SQL
or a human-readable summary.

    my $diff = DBIO::SQLite::Diff->new(
        source => $current_model,
        target => $desired_model,
    );

    if ($diff->has_changes) {
        print $diff->as_sql;
        print $diff->summary;
    }

=head2 What a name is

L<DBIO::SQLite::Introspect::Tables> lists everything C<sqlite_master> calls a
table or a view under C<tables>. Before anything is compared, the entries of
both models are sorted by what they are:

=over 4

=item * A B<view> -- C<< kind => 'view' >>. It is created as a view and
removed as a view, and replaced when its definition differs
(L<DBIO::SQLite::Diff::View>). No column op, index op or rebuild is ever
written for one.

=item * A B<virtual table> -- its statement begins C<CREATE VIRTUAL TABLE>;
its C<kind> is C<table>, which is what C<sqlite_master> says. One that is new
is created from its statement and one that is gone is dropped by C<DROP
TABLE>. One that both models have and that is not the same in them -- its
definition differs, compared like a view's, or it is a plain table on the
other side -- is B<refused>: SQLite cannot alter a virtual table, and a
rebuild would lose what its module stores
(L<DBIO::SQLite::Diff::Table/Changes that are refused>). No column op, index
op or rebuild is ever written for one either.

=item * A B<plain table> -- everything else, an entry without C<kind> or
without a statement included, as the models built by hand and by
L</target_from_compiled> have them. Only these are walked for columns and
indexes, and only these are rebuilt.

=back

One name can be a table on one side and a view on the other. The table is
then dropped or created as a table and the view created or dropped as a view.

=head2 The order of the operations

    1  DROP VIEW      views that go, and the old half of a replaced one
    2  DROP INDEX     indexes that go, and the old half of a changed one
    3  tables         CREATE TABLE, DROP TABLE, and the refusals
    4  ADD COLUMN
    5  rebuilds       each followed by the CREATE INDEX of its indexes
    6  CREATE VIEW    new views, and the new half of a replaced one,
                      with the triggers it carries
    7  DROP COLUMN
    8  CREATE INDEX   new indexes, and the new half of a changed one

The order follows what SQLite checks (measured on libsqlite 3.51.1). C<ALTER
TABLE ... DROP COLUMN> reads the B<whole> schema, not only its table: a view
anywhere that names something that is gone fails it (C<error in view v: no
such column>), and so does an index over the column (C<error in index ...
after drop column>). So the views that go are dropped first, the index drops
come before the column drops, and the views of the target are created before
a column is dropped -- by then every table and column they name exists, and
no view left in the database names anything that is about to go. C<CREATE
TABLE>, C<DROP TABLE>, C<ADD COLUMN> and C<CREATE VIEW> read nothing but their
own object, and a rebuild renames under C<PRAGMA legacy_alter_table>, which
reads nothing either. An index is not dropped on its own for a table that is
dropped or rebuilt: it goes with the table.

=head2 When a table is rebuilt

SQLite's C<ALTER TABLE> adds a column, drops one and renames. Everything else
a table declares can only be changed by building the table anew, and a plain
table that both models have is rebuilt as a whole by one
L<DBIO::SQLite::Diff::Rebuild>, which takes the place of that table's column
ops, when any of this differs:

=over 4

=item * a column's B<type, C<NOT NULL> or default>
(L<DBIO::SQLite::Diff::Column/What counts as a changed column>);

=item * a column is B<added> that carries C<UNIQUE> or C<PRIMARY KEY> or is
named in a table constraint (L<DBIO::SQLite::Diff::Column/Added columns>);

=item * the B<primary key> -- its columns, in the order of the key;

=item * the B<C<UNIQUE> constraints> -- the set of their column lists, as
C<PRAGMA index_list> reports them (the automatic indexes of origin C<u>),
written on a column or on the table alike;

=item * the B<foreign keys> -- the set of them, each as its columns, the
table and columns it points at, and its C<ON UPDATE> and C<ON DELETE>. Names
and actions are compared in any letter case; an action nobody declared is
C<NO ACTION>. It is a set: a key an older database holds twice is the key
declared once, and the order of the lines is no difference. A key
of the target over a column the source does not have is left out -- it
arrives with the column, by the C<ADD COLUMN> that carries its declaration or
by the rebuild the column causes;

=item * a B<C<CHECK>>, a column's B<C<COLLATE>> or a B<generated column's
expression> that the target states (L</What the target states>). No
C<PRAGMA> reports these, so they are read out of the two
C<CREATE TABLE> statements: per column that both tables have, its C<CHECK>
clauses as a set, its collation and its generated clause, and the C<CHECK>
constraints of the table as a set. They are compared as written, with
whitespace and comments set aside and the framing keywords and the name of a
collation in any letter case; an expression is compared token for token.
That is conservative on purpose: C<< CHECK (qty>=0) >> against
C<< CHECK (qty >= 0) >> is a difference, the table is rebuilt once and is the same from then on,
and a real change is never missed. A C<CHECK> moved from the column to the
table is a difference the same way;

=item * B<C<WITHOUT ROWID>> or B<C<STRICT>> that the target has and the
source has not.

=back

The reasons found are kept on the op and shown by its C<summary>:

    ~ table rebuild: item (foreign key (owner_id) -> owner (id) ON DELETE CASCADE added)

All of this needs the target table's C<CREATE TABLE> statement, which is what
the table is rebuilt from, so it happens for introspected models only. A model
without the statement (L</target_from_compiled>, a model built by hand) holds
no indexes and no foreign keys by construction; that says "not stated", not
"none", and nothing of the above is compared for it. The clauses read from the
statements are compared only where the source has a statement too.

If one of the two statements cannot be read clause by clause, the comparison
is not passed over: the two statements are then compared as they stand, the
table's name aside, and any difference rebuilds the table -- after which the
live statement is the target's, and the two are the same.

=head2 What the target states

B<The target is the desired state>, here as for columns and indexes. For a
B<primary key>, a B<C<UNIQUE>> and a B<foreign key> that holds in both
directions: a result class declares them (C<set_primary_key>,
C<add_unique_constraint>, C<belongs_to> and its
C<is_foreign_key_constraint>), so a target that has none says there is to be
none, and a key or constraint only the source has goes with the rebuild.

A B<C<CHECK>>, a B<C<COLLATE>>, a B<generated column>, B<C<WITHOUT ROWID>> and
B<C<STRICT>> no result class can declare. The target L<DBIO::SQLite::Deploy>
compares with is deployed from result classes and never has one, so "the
target has none" says "not stated" there, not "none wanted". These follow the
desired-state contract core has for the fields of a column
(L<DBIO::Diff::Compare/changed_fields>, core ADR 0019): what the target leaves
unstated is not compared, what it states is compared, and stated against
missing is a change.

=over 4

=item * A column whose target has no C<CHECK> is not compared in its
C<CHECK>s; one whose target has some is, set against set.

=item * A column whose target has no C<COLLATE> is not compared in its
collation.

=item * A column that is not generated in the target is not compared in its
generated clause; one that is, is -- against a plain column, another
expression or another storage.

=item * The C<CHECK> constraints of the table are not compared when the
target has none. A target that has some has stated all of them: the sets are
compared, and one only the source has goes.

=item * C<WITHOUT ROWID> and C<STRICT> are a change when the target has the
option and the source has not, and are not compared otherwise.

=back

So a table made by hand with one of these, under a schema that describes the
table, diffs to nothing, and an upgrade leaves it alone.

B<That is a statement about what causes a rebuild, not about what survives
one.> A table that is rebuilt, for whichever reason, is created from the
target's C<CREATE TABLE> statement, and whatever that statement does not say
is gone afterwards -- a hand-made C<CHECK>, C<COLLATE>, generated column,
C<WITHOUT ROWID> or C<STRICT> that the comparison had left alone included.
That has been so since the first rebuild (ADR 0003); the comparison only does
not cause a rebuild for it.

B<Triggers> are the exception, and do survive. The rebuild is given what the source has on
that table and the target cannot say: the triggers of the live table, from the
C<triggers> section of the source model
(L<DBIO::SQLite::Introspect::Triggers>), which it re-creates; a replaced view
gets its triggers back the same way. Triggers are carried and never compared
-- no op adds, drops or changes one. The columns a rebuild copies are those
both sides have, without the ones the target generates.

B<Not compared>, deliberately: C<AUTOINCREMENT> (ADR 0004); C<ON CONFLICT>
clauses; C<DEFERRABLE> and C<MATCH> of a foreign key; the names of
constraints; a collation or sort order inside the column list of a C<PRIMARY
KEY> or C<UNIQUE>; and the order of the columns. A foreign key declared
without its target columns (C<REFERENCES owner>) is not the key declared with
them (C<REFERENCES owner(id)>): the table is rebuilt once to the target's
spelling.

=head2 Changes that are refused

Without the statement a changed type, nullability or default cannot be
carried out at all, and it is refused: C<as_sql> throws, naming the table, the
column, the change and the reason, and so does L<DBIO::SQLite::Deploy/apply>
-- before it has run a statement of the diff. C<has_changes> and C<summary>
still answer. See L<DBIO::SQLite::Diff::Column/Changes that are refused>. A
changed virtual table is refused the same way, and so is a view the target
lists without its C<CREATE VIEW> statement
(L<DBIO::SQLite::Diff::View/A view without a statement>).

=head1 METHODS

=head2 target_from_compiled

    my $target = DBIO::SQLite::Diff->target_from_compiled($compiled_model);

Translates the neutral model from L<DBIO::Schema::ModelCompiler> into the
SQLite introspect-shaped model that C<diff> consumes: native types land in
C<data_type>, with the length or precision of a type like C<CHAR(5)> as
C<size> (L<DBIO::SQLite::Util/split_type_size>), the way the introspected side
reports it, and C<not_null> is carried over as the compiled model states it.

It used to be zeroed on every primary-key column, on the grounds that "SQLite
reports PK columns as notnull=0". That holds for the B<rowid alias> and for a
key column nobody declared C<NOT NULL>; it does not hold for a key column that
B<was> declared C<NOT NULL>, nor for a C<WITHOUT ROWID> key, both of which the
C<PRAGMA> reports as C<notnull = 1>. Zeroing them unconditionally made a table
differ from the schema it had just been deployed from. The alias --
the one shape where the declaration and the truth really do come apart -- is
reconciled where the database is, on the introspect side
(L<DBIO::SQLite::Introspect::Columns/fetch>), which is the only side that can
ask it; nothing is left for this side to guess.

C<default_value> is carried in the form the introspector reports it. A default
given as a scalar ref is literal SQL, so the ref is resolved, and one pair of
enclosing parentheses is taken off: a schema writes
C<< default_value => \"(datetime('now'))" >>, L<DBIO::SQLite::DDL> deploys it
as written, and C<PRAGMA table_xinfo> then answers C<datetime('now')>. Left as
the ref it reached the C<CREATE TABLE> as C<DEFAULT SCALAR(0x...)>;
left with its parentheses it would differ from the column it was deployed as.
L<DBIO::SQLite::Diff::Table> and L<DBIO::SQLite::Diff::Column> put the
parentheses back when they write the clause
(L<DBIO::SQLite::Util/default_value_sql>).

A default that is not a ref is a value, and is carried as the literal
L<DBIO::SQLite::DDL> writes for it
(L<DBIO::SQLite::Util/default_literal_sql>): in a column with TEXT affinity
always as a string in apostrophes, with the apostrophes inside it doubled;
in any other column a number bare and anything else as that string. The
affinity is that of the column's C<native_type>, where L<DBIO::SQLite::DDL>
asks the type it writes. C<< default_value => "it's" >> is C<'it''s'> in the
model and C<< default_value => '007' >> on a C<text> column is C<'007'>, which
is what C<PRAGMA table_xinfo> answers for the installed column. Passed on as
the bare value it differed from that column, and a value of more than one word
could not be written after C<DEFAULT> at all.

C<pk_position> is the column's place in the primary key as the result class
declares it with C<set_primary_key> -- 1 for the first key column, 0 for a
column outside the key, the convention of
L<DBIO::SQLite::Introspect::Columns/fetch>. The key's order is not the order of
the columns: C<set_primary_key('a', 'b')> on columns declared C<b, a> is the
key C<(a, b)>.

The model has no C<sql> for its tables, no indexes and no foreign keys, so a
table that is new in it is rebuilt from its columns, with the limits
L<DBIO::SQLite::Diff::Table/as_sql> lists.

=head2 statements

    my @statements = $diff->statements;

Every statement of the diff in the order it has to run, each one complete and
closed by its semicolon. L<as_sql|DBIO::Diff::Base/as_sql> is this list joined
by newlines.

Use it to B<run> a diff. The text of C<as_sql> cannot be cut back into
statements at its semicolons: a C<CREATE TRIGGER> that
L<DBIO::SQLite::Diff::Rebuild> carries has semicolons inside it, and so has
any statement with one in a string. L<DBIO::SQLite::Deploy/apply> runs what
this returns.

An op contributes its own C<statements> where it has that method
(L<DBIO::SQLite::Diff::Rebuild/statements>) and its C<as_sql> otherwise, which
for every other op of this driver is one statement. Like C<as_sql> it throws
for a change that is refused -- having run nothing, since it only renders.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
