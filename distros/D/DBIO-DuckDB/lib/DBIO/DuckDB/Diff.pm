package DBIO::DuckDB::Diff;
# ABSTRACT: Compare two introspected DuckDB models

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Base';

use DBIO::DuckDB::Diff::Table;
use DBIO::DuckDB::Diff::Column;
use DBIO::DuckDB::Diff::Index;
use DBIO::DuckDB::Diff::View;
use DBIO::DuckDB::Diff::Rebuild;


sub _build_operations {
  my ($self) = @_;
  my @ops;

  # A view is no table: views are split off here, so no table, column or
  # index op is ever written for one (DBIO::DuckDB::Diff::View).
  my $split = sub {
    my ($tables) = @_;
    my (%t, %v);
    for my $name (keys %{ $tables || {} }) {
      my $into = ($tables->{$name}{kind} // '') eq 'view' ? \%v : \%t;
      $into->{$name} = $tables->{$name};
    }
    return (\%t, \%v);
  };
  my ($src_tables, $src_views) = $split->($self->source->{tables});
  my ($tgt_tables, $tgt_views) = $split->($self->target->{tables});

  my @view_ops = DBIO::DuckDB::Diff::View->diff($src_views, $tgt_views);
  my $rebuild  = $self->rebuild_reasons;

  # views that go, and the old half of a replaced one, first: DuckDB refuses
  # to drop what a view depends on
  push @ops, grep { $_->action eq 'drop' } @view_ops;

  my @table_ops = DBIO::DuckDB::Diff::Table->diff(
    $src_tables, $tgt_tables,
    $self->target->{columns}, $self->target->{foreign_keys},
    $self->source->{foreign_keys}, $self->target->{unique_constraints},
  );
  # the creates are written together with the rebuilds below, in the order of
  # the foreign keys; the drops stay where they are
  my @creates = grep { $_->action eq 'create' } @table_ops;
  push @ops, grep { $_->action ne 'create' } @table_ops;
  my @column_ops = DBIO::DuckDB::Diff::Column->diff(
    $self->source->{columns}, $self->target->{columns},
    $src_tables, $tgt_tables,
  );
  my %column_ops_of;
  for my $op (@column_ops) {
    push @{ $column_ops_of{ $op->table_name } }, $op if $rebuild->{ $op->table_name };
  }
  push @ops, grep { !$rebuild->{ $_->table_name } } @column_ops;
  push @ops, $self->_order_by_keys(
    [ @creates, $self->_rebuild_ops($rebuild, \%column_ops_of) ],
  );

  # A UNIQUE constraint of a table that exists is added as a unique index
  # (DuckDB has no ALTER TABLE for it) and, once there, satisfies the
  # constraint: the unique index is not an extra index of the source then.
  my ($src_indexes, @unique_ops) = $self->_unique_constraint_ops($src_tables, $tgt_tables);
  # a rebuilt table loses its indexes with the old table and gets the ones of
  # the target again; its UNIQUE constraints are in its CREATE TABLE
  push @ops, grep { !$rebuild->{ $_->table_name } } DBIO::DuckDB::Diff::Index->diff(
    $src_indexes, $self->target->{indexes},
    $src_tables, $tgt_tables,
  );
  push @ops, grep { !$rebuild->{ $_->table_name } } @unique_ops;
  for my $table (sort keys %$rebuild) {
    my $indexes = ($self->target->{indexes} || {})->{$table} || {};
    push @ops, map {
      DBIO::DuckDB::Diff::Index->new(
        action => 'create', table_name => $table,
        index_name => $_, index_info => $indexes->{$_},
      );
    } sort keys %$indexes;
  }

  # new views behind the tables and columns they select from
  push @ops, grep { $_->action eq 'create' } @view_ops;

  return \@ops;
}


sub rebuild_reasons {
  my ($self) = @_;
  my ($src, $tgt) = ($self->source, $self->target);
  my %reasons;

  my $plain = sub {
    my ($model, $table) = @_;
    return exists $model->{tables}{$table} && ($model->{tables}{$table}{kind} // '') ne 'view';
  };
  my @both = grep { $plain->($src, $_) && $plain->($tgt, $_) } sort keys %{ $tgt->{tables} || {} };

  # a column that goes under an index or a UNIQUE constraint
  for my $table (@both) {
    my @order = map { $_->{column_name} } @{ $src->{columns}{$table} || [] };
    my %want  = map { $_->{column_name} => 1 } @{ $tgt->{columns}{$table} || [] };
    for my $at (grep { !$want{ $order[$_] } } 0 .. $#order) {
      my $column = $order[$at];
      my %later  = map { $_ => 1 } @order[ $at + 1 .. $#order ];
      my @why;
      for my $idx (values %{ ($src->{indexes} || {})->{$table} || {} }) {
        push @why, "index '$idx->{index_name}'" if grep { $later{$_} } @{ $idx->{columns} || [] };
      }
      for my $uq (values %{ ($src->{unique_constraints} || {})->{$table} || {} }) {
        push @why, sprintf "UNIQUE (%s)", join ', ', @{ $uq->{columns} }
          if grep { $later{$_} || $_ eq $column } @{ $uq->{columns} };
      }
      push @{ $reasons{$table} }, sprintf
        "column '%s' cannot be dropped, %s stands on it or on a later column",
        $column, join(', ', sort @why) if @why;
    }
  }

  # a UNIQUE constraint that goes
  my (undef, $dropped) = $self->unique_constraint_changes;
  push @{ $reasons{ $_->[0] } }, sprintf 'UNIQUE (%s) is dropped', join ', ', @{ $_->[2] }
    for @$dropped;

  # a foreign key that comes or goes
  my $key = sub {
    my ($fk) = @_;
    return sprintf 'FOREIGN KEY (%s) REFERENCES %s(%s)%s%s',
      join(', ', @{ $fk->{from_columns} }), $fk->{to_table},
      join(', ', @{ $fk->{to_columns} }),
      (defined $fk->{on_delete} && $fk->{on_delete} ne 'NO ACTION' ? " ON DELETE $fk->{on_delete}" : ''),
      (defined $fk->{on_update} && $fk->{on_update} ne 'NO ACTION' ? " ON UPDATE $fk->{on_update}" : '');
  };
  for my $table (@both) {
    my %have = map { $key->($_) => 1 } @{ ($src->{foreign_keys} || {})->{$table} || [] };
    my %want = map { $key->($_) => 1 } @{ ($tgt->{foreign_keys} || {})->{$table} || [] };
    my @changed = ( (map { "$_ is added" }   grep { !$have{$_} } sort keys %want),
                    (map { "$_ is dropped" } grep { !$want{$_} } sort keys %have) );
    push @{ $reasons{$table} }, @changed if @changed;
  }

  # a UNIQUE constraint a foreign key needs
  my $set = sub { join "\0", sort @{ $_[0] } };
  for my $from (sort keys %{ $tgt->{foreign_keys} || {} }) {
    for my $fk (@{ $tgt->{foreign_keys}{$from} }) {
      my $table = $fk->{to_table};
      next unless grep { $_ eq $table } @both;
      my $cols = $set->($fk->{to_columns});
      next unless grep { $set->($_->{columns}) eq $cols }
        values %{ ($tgt->{unique_constraints} || {})->{$table} || {} };
      my @pk = map { $_->{column_name} } grep { $_->{is_pk} } @{ $src->{columns}{$table} || [] };
      next if @pk && $set->(\@pk) eq $cols;
      next if grep { $set->($_->{columns}) eq $cols }
        values %{ ($src->{unique_constraints} || {})->{$table} || {} };
      push @{ $reasons{$table} }, sprintf
        "the foreign key (%s) of table '%s' needs a UNIQUE constraint on (%s)",
        join(', ', @{ $fk->{from_columns} }), $from, join(', ', @{ $fk->{to_columns} });
    }
  }

  for my $table (keys %reasons) {
    my %seen;
    $reasons{$table} = [ grep { !$seen{$_}++ } @{ $reasons{$table} } ];
  }
  return \%reasons;
}

sub _rebuild_ops {
  my ($self, $reasons, $column_ops_of) = @_;
  my ($src, $tgt) = ($self->source, $self->target);

  my @order = sort keys %$reasons;    # _order_by_keys puts them in key order

  return map {
    my $table = $_;
    my %have  = map { $_->{column_name} => 1 } @{ $src->{columns}{$table} || [] };
    my @cols  = @{ $tgt->{columns}{$table} || [] };
    DBIO::DuckDB::Diff::Rebuild->new(
      action             => 'rebuild',
      table_name         => $table,
      columns            => \@cols,
      foreign_keys       => ($tgt->{foreign_keys} || {})->{$table} || [],
      unique_constraints => ($tgt->{unique_constraints} || {})->{$table} || {},
      copy_columns       => [ grep { $have{$_} } map { $_->{column_name} } @cols ],
      reasons            => $reasons->{$table},
      column_ops         => $column_ops_of->{$table} || [],
    );
  } @order;
}

# Creates and rebuilds in one order, the table a key points to first, whichever
# of the two it is: a new table with a key to the new UNIQUE of a rebuilt one
# follows the rebuild, a rebuilt table with a key to a new table follows its
# create.
sub _order_by_keys {
  my ($self, $nodes) = @_;
  my $fks  = $self->target->{foreign_keys} || {};
  my @rest = @$nodes;
  my (@order, %done);
  my %pending = map { $_->table_name => 1 } @rest;
  while (@rest) {
    my ($at) = grep {
      my $t = $rest[$_]->table_name;
      !grep { $_ ne $t && $pending{$_} && !$done{$_} }
        map { $_->{to_table} } @{ $fks->{$t} || [] };
    } 0 .. $#rest;
    $at //= 0;    # a circle: as it comes, what cannot run is refused by the deploy
    my ($n) = splice @rest, $at, 1;
    $done{ $n->table_name } = 1;
    push @order, $n;
  }
  return @order;
}


sub unique_constraint_changes {
  my ($self) = @_;
  my ($src, $tgt) = ($self->source, $self->target);
  my (@added, @dropped);

  my $tuples = sub {
    my ($model, $table) = @_;
    my %c = map { join("\0", @{ $_->{columns} }) => $_ }
      values %{ ($model->{unique_constraints} || {})->{$table} || {} };
    my %i = map { join("\0", @{ $_->{columns} }) => $_ }
      grep { $_->{is_unique} && !$_->{partial} && @{ $_->{columns} || [] } }
      values %{ ($model->{indexes} || {})->{$table} || {} };
    return (\%c, \%i);
  };

  for my $table (sort keys %{ $tgt->{tables} || {} }) {
    next unless exists $src->{tables}{$table};
    next if ($tgt->{tables}{$table}{kind} // '') eq 'view';
    my ($sc, $si) = $tuples->($src, $table);
    my ($tc, $ti) = $tuples->($tgt, $table);
    for my $key (sort keys %$tc) {
      push @added, [ $table, $tc->{$key}{constraint_name}, $tc->{$key}{columns} ]
        unless $sc->{$key} || $si->{$key};
    }
    for my $key (sort keys %$sc) {
      push @dropped, [ $table, $sc->{$key}{constraint_name}, $sc->{$key}{columns} ]
        unless $tc->{$key} || $ti->{$key};
    }
  }

  return (\@added, \@dropped);
}

sub _unique_constraint_ops {
  my ($self, $src_tables, $tgt_tables) = @_;
  my ($added) = $self->unique_constraint_changes;

  # unique indexes of the source that stand for a UNIQUE constraint of the
  # target are not touched by the index diff
  my %keep;
  for my $table (keys %{ $self->target->{unique_constraints} || {} }) {
    $keep{$table}{ join "\0", @{ $_->{columns} } } = 1
      for values %{ $self->target->{unique_constraints}{$table} };
  }
  my %indexes;
  my $source_indexes = $self->source->{indexes} || {};
  for my $table (keys %$source_indexes) {
    for my $name (keys %{ $source_indexes->{$table} }) {
      my $idx = $source_indexes->{$table}{$name};
      next if $idx->{is_unique} && !$idx->{partial}
        && $keep{$table}{ join "\0", @{ $idx->{columns} || [] } }
        && !exists(($self->target->{indexes} || {})->{$table}{$name});
      $indexes{$table}{$name} = $idx;
    }
  }

  my @ops = map {
    my ($table, $name, $columns) = @$_;
    DBIO::DuckDB::Diff::Index->new(
      action     => 'create',
      table_name => $table,
      index_name => $name,
      index_info => { index_name => $name, columns => $columns, is_unique => 1,
                      from_unique_constraint => 1 },
    );
  } @$added;

  return (\%indexes, @ops);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DuckDB::Diff - Compare two introspected DuckDB models

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::DuckDB::Diff> compares two introspected DuckDB models (produced
by L<DBIO::DuckDB::Introspect>) and emits a list of structured diff
operations that can be rendered to SQL or a human-readable summary.

    my $diff = DBIO::DuckDB::Diff->new(
        source => $current_model,
        target => $desired_model,
    );

    if ($diff->has_changes) {
        print $diff->as_sql;
        print $diff->summary;
    }

Operations are emitted in dependency order: views that go, tables, then
columns, then indexes, then views that are new. Drops come last for each
layer. A view is created and dropped as a view (L<DBIO::DuckDB::Diff::View>);
it is never diffed as a table.

DuckDB enforces foreign keys, so the install DDL writes them and a table the
diff creates brings its keys, after the tables they point to (a table is
dropped before those).

What C<ALTER TABLE> cannot do, the diff does by rebuilding the table
(L<DBIO::DuckDB::Diff::Rebuild>,
C<docs/adr/0010-tables-are-rebuilt-for-what-alter-cannot-do.md>): a column
dropped while an index or a C<UNIQUE> constraint stands on it or on a later
column, a C<UNIQUE> constraint that goes, a foreign key that is added or
dropped (there is no C<ALTER TABLE ... ADD FOREIGN KEY> in DuckDB), and a
C<UNIQUE> constraint a foreign key of the target needs (DuckDB takes a key to a
constraint only, not to a unique index). The column and index operations of
such a table are replaced by one rebuild and the creation of its target
indexes; creates and rebuilds come in one order, the table a key points to first,
whether it is created or rebuilt.

=head1 METHODS

=head2 rebuild_reasons

    my $reasons = $diff->rebuild_reasons;   # { $table => [ 'reason', ... ] }

The tables of both models that have to be rebuilt, each with what makes it so
(L<DBIO::DuckDB::Diff::Rebuild>):

=over 4

=item * a column that goes while an index or a C<UNIQUE> constraint stands on
it or on a later column of the table;

=item * a C<UNIQUE> constraint the target lacks (L</unique_constraint_changes>);

=item * a foreign key added or dropped, compared by columns, parent table,
parent columns and actions (the constraint name is not part of it);

=item * a C<UNIQUE> constraint of the target that a foreign key of the target
points to, while the source table has it neither as a constraint nor as its
PRIMARY KEY (it may have a unique index, which DuckDB does not take for a key).

=back

=head2 unique_constraint_changes

    my ($added, $dropped) = $diff->unique_constraint_changes;

The UNIQUE constraints of tables that exist on both sides, compared by their
column tuple in order: C<$added> are the ones the target has and the source
has neither as a constraint nor as a unique index, C<$dropped> the ones the
source has as a constraint and the target has neither as a constraint nor as
a unique index. Each is a list of C<[ $table, $name, \@columns ]>.
A dropped one makes the table a rebuild (L</rebuild_reasons>): DuckDB cannot
drop a constraint.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
