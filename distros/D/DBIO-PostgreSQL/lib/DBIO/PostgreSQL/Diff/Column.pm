package DBIO::PostgreSQL::Diff::Column;
# ABSTRACT: Diff operations for PostgreSQL columns

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::Diff::Compare qw(changed_fields column_change_lossy);
use DBIO::PostgreSQL::Diff::CaseOnly ();
use DBIO::PostgreSQL::Diff::NoStatement ();
use DBIO::PostgreSQL::Diff::View ();
use DBIO::PostgreSQL::Introspect ();
use DBIO::PostgreSQL::Util qw(quote_ident quote_qualified type_with_modifier);

__PACKAGE__->mk_diff_accessors(qw(
  table_key schema_name table_name column_name old_info new_info using
));










sub _refuse_generated_change {
  my ($table_key, $table, $src, $tgt) = @_;
  my $column = $src->{column_name};

  my ($from, $to) = map { DBIO::PostgreSQL::Introspect->generated_kind($_->{generated}) } $src, $tgt;
  my $what
    = !$from      ? 'an ordinary column in the database and a generated column in the target'
    : !$to        ? 'a generated column in the database and an ordinary column in the target'
    : $from ne $to ? sprintf('a %s generated column in the database and a %s one in the target', lc $from, lc $to)
    : sprintf('generated from %s in the database and from %s in the target',
        map { $_->{default_value} // 'nothing' } $src, $tgt);

  die join "\n",
    "refusing to diff: column $table_key.$column is $what",
    '',
    'The diff has no statement for a change to how a column is generated: ALTER',
    'COLUMN ... SET EXPRESSION exists from PostgreSQL 17 on only, and nothing makes',
    'an ordinary column a generated one. No statement was generated.',
    '',
    'Drop the column yourself when what it holds can go,',
    "  ALTER TABLE $table DROP COLUMN " . quote_ident($column) . ';',
    'and diff again: the diff then adds it as the target has it.',
    '';
}

# Field comparison spec for the PostgreSQL column model. Covers the
# canonical data_type / not_null / default_value / size set plus the
# PostgreSQL-specific identity and generated flags (attidentity,
# attgenerated from pg_catalog) and the referenced enum type name
# (pg_enum_type). size is a 'dim' field because it may be a scalar length
# (varchar(100)) or an ordered [precision, scale] pair (numeric(10,2)) —
# matching DBIO::Diff::Compare::changed_column_fields. identity, generated
# and pg_enum_type are scalars (short opcodes / a schema-qualified type
# name, not user data).
my %_COLUMN_FIELD_SPEC = (
  type   => [qw/data_type/],
  bool   => [qw/not_null/],
  scalar => [qw/default_value identity generated pg_enum_type/],
  dim    => [qw/size/],
);

# The tables a table has columns from: the partitioned table it is a
# partition of, or the tables it inherits from.
sub _parents {
  my ($info) = @_;
  return grep { defined } $info->{partition_of}, @{ $info->{inherits} // [] };
}

# @keys with each table behind the tables it has columns from, and otherwise
# in the order given.
sub _parents_first {
  my ($tables, @keys) = @_;
  my %wanted = map { $_ => 1 } @keys;
  my (%seen, @order);
  my $visit;
  $visit = sub {
    my ($key) = @_;
    return if $seen{$key}++;
    $visit->($_) for grep { $wanted{$_} } _parents($tables->{$key} // {});
    push @order, $key;
  };
  $visit->($_) for @keys;
  undef $visit;
  return @order;
}

# What the columns of a table are once the statements for the tables it has
# columns from have run. PostgreSQL carries those down (measured on 18.6, for
# partitions and for inheritance alike): ADD COLUMN puts the column into the
# child as it is above, DROP COLUMN takes it from a child that does not define
# it itself as well, ALTER COLUMN TYPE, SET DEFAULT, DROP DEFAULT and SET NOT
# NULL do to the child's column what they do above -- a default of the
# child's own is overwritten. Two things are not carried down for certain,
# and are left as the child has them: DROP NOT NULL leaves a NOT NULL the
# child has of its own, which the model cannot tell from an inherited one;
# and an identity is a partition's as it is the partitioned table's, but not
# inherited by a table that inherits -- there the target says which it was.
#
# $own and $target are the table's columns by name, in the database and in
# the target; each of @parents is [ columns before, columns after ] of a table
# it has columns from.
sub _after_cascade {
  my ($own, $target, @parents) = @_;
  my %now = %$own;

  my %names = map { $_ => 1 } map { keys %{ $_->[0] }, keys %{ $_->[1] } } @parents;
  for my $name (sort keys %names) {
    my @before = grep { $_->[0]{$name} } @parents;
    my @after  = grep { $_->[1]{$name} } @parents;
    my $same_identity = sub {
      my ($above) = @_;
      return $target->{$name}
        && ($target->{$name}{identity} // '') eq ($above->{identity} // '');
    };

    if (!$now{$name}) {
      next if @before || !@after;
      my $above = $after[0][1]{$name};
      $now{$name} = {
        %$above, is_local => 0,
        identity => ( $same_identity->($above) ? $above->{identity} : '' ),
      };
      next;
    }

    next unless @before;    # a column of the table's own
    if (!@after) {
      delete $now{$name} unless $now{$name}{is_local};
      next;
    }

    my %column = %{ $now{$name} };
    for my $parent (@parents) {
      my ($was, $is) = ($parent->[0]{$name}, $parent->[1]{$name});
      next unless $was && $is;

      @column{qw( data_type size pg_enum_type )} = @{$is}{qw( data_type size pg_enum_type )}
        if _render_type($was) ne _render_type($is);
      $column{default_value} = $is->{default_value}
        if ($was->{default_value} // '') ne ($is->{default_value} // '');
      $column{not_null} = 1 if !$was->{not_null} && $is->{not_null};
      $column{identity} = $is->{identity}
        if ($was->{identity} // '') ne ($is->{identity} // '') && $same_identity->($is);
    }
    $now{$name} = \%column;
  }

  return \%now;
}

# What reads a column, in the model of the database: { table key => { column
# => [ view keys ] } }, from the depends_on_columns of its views.
sub _readers {
  my ($tables) = @_;
  my %readers;
  for my $view (sort keys %$tables) {
    next unless DBIO::PostgreSQL::Diff::View->is_view($tables->{$view});
    my $reads = $tables->{$view}{depends_on_columns} // {};
    for my $table (keys %$reads) {
      push @{ $readers{$table}{$_} }, $view for @{ $reads->{$table} };
    }
  }
  return \%readers;
}

# The views of the database that the target does not have and that stand on a
# column whose type changes. The target's views are dropped and created again
# by Diff::View; these are not the declaration's to create again.
sub _refuse_type_change_under_undeclared_view {
  my ($table_key, $column, $from, $to, $source_tables, @undeclared) = @_;

  my $kind = sub { $source_tables->{ $_[0] }{kind} eq 'm' ? 'materialized view' : 'view' };
  my @drop = DBIO::PostgreSQL::Diff::View->with_dependents($source_tables, @undeclared);

  die join "\n",
    sprintf('refusing to diff: column %s.%s changes its type from %s to %s while %s, which only the database has, depends on it',
      $table_key, $column, $from, $to,
      join(', ', map { $kind->($_) . " $_" } sort @undeclared)),
    '',
    'PostgreSQL does not alter the type of a column while a view uses it',
    '(cannot alter type of a column used by a view or rule). The diff drops the',
    'views the target has around that change and creates them again, but not a view',
    'the target does not have: only the declaration is the diff\'s to create.',
    'No statement was generated.',
    '',
    'Drop what only the database has yourself, with the views that stand on it,',
    ( map { '  ' . DBIO::PostgreSQL::Diff::View->drop_sql($source_tables->{$_}) } @drop ),
    'and diff again: the diff then drops the views the target has, alters the column',
    'and creates them again.',
    ( ( grep { $kind->($_) ne 'view' } @drop )
        ? 'A materialized view is built anew by that, and the indexes on it are created again.'
        : () ),
    '';
}

# The materialized views that stand on a column whose type changes -- reading
# it, or standing on a view that does. The diff drops and creates again the
# views around such a change, but not a materialized view: that would build
# its data anew and take its indexes with it (decision 2026-10-16).
sub _refuse_type_change_under_matview {
  my ($table_key, $column, $from, $to, $source_tables, $read_by, $in_the_way, @matviews) = @_;

  my %reads_in = map { $_->[0] => $_->[1] } @$read_by;
  my %in_the_way = map { $_ => 1 } @$in_the_way;
  my $kind = sub { $source_tables->{ $_[0] }{kind} eq 'm' ? 'materialized view' : 'view' };
  my $through = sub {
    my @on = sort grep { $in_the_way{$_} } @{ $source_tables->{ $_[0] }{depends_on} // [] };
    return @on ? ' (through ' . join(', ', map { $kind->($_) . " $_" } @on) . ')' : '';
  };
  my @drop = DBIO::PostgreSQL::Diff::View->with_dependents($source_tables, @matviews);

  die join "\n",
    sprintf('refusing to diff: column %s.%s changes its type from %s to %s and is read by %s',
      $table_key, $column, $from, $to,
      join(', ', map {
        my $in = $reads_in{$_};
        "materialized view $_"
          . (!defined $in ? $through->($_) : $in eq $table_key ? '' : " (in $in)")
      } sort @matviews)),
    '',
    'PostgreSQL does not alter the type of a column while a view uses it',
    '(cannot alter type of a column used by a view or rule). The diff drops the',
    'views around that change and creates them again, but not a materialized view:',
    'that would build its data anew and take the indexes on it with it.',
    'No statement was generated.',
    '',
    'Drop it yourself when that is acceptable, with the views that stand on it,',
    ( map { '  ' . DBIO::PostgreSQL::Diff::View->drop_sql($source_tables->{$_}) } @drop ),
    'and diff again: the diff then alters the column, creates again the views the',
    'target has, and creates the materialized view as the target has it, with the',
    'indexes the target has on it.',
    '';
}

# What the server says to a statement for a column at the table that only
# has it from another.
my %NOT_AT_PARENT = (
  add  => [ 'is to be added to %s, a partition of %s, and not to %2$s', 'cannot add column to a partition' ],
  drop => [ 'is to be dropped from %s and not from %s, which it has the column from', 'cannot drop inherited column' ],
  type => [ 'is to change its type in %s and not in %s, which it has the column from', 'cannot alter inherited column' ],
);

sub _refuse_not_at_parent {
  my ($what, $table_key, $column, @parents) = @_;
  my ($phrase, $server) = @{ $NOT_AT_PARENT{$what} };
  die join "\n",
    "refusing to diff: column $table_key.$column "
      . sprintf($phrase, $table_key, join(', ', @parents)),
    '',
    'A column a table has from the table it is a partition of, or inherits from, is',
    "changed there, and PostgreSQL refuses the statement anywhere else ($server).",
    'No database has the two differ in it; this target model does.',
    'No statement was generated.',
    '',
    'Make the two agree in the target model and diff again.',
    '';
}

# What else reads a column, in the model of the database, and is not a view of
# the model: { relation key => { column => [ reader ] } }. A reader is
# { kind, table (key of the relation it is on), name } for a policy, a trigger
# and a generated column, and { kind => 'view', key, ... } for a view outside
# the schemas the model holds.
sub _other_readers {
  my ($cols, $policies, $triggers, $outside) = @_;
  my %readers;
  for my $pair ([ policy => $policies ], [ trigger => $triggers ]) {
    my ($kind, $section) = @$pair;
    for my $table (sort keys %{ $section // {} }) {
      for my $name (sort keys %{ $section->{$table} }) {
        my $entry = $section->{$table}{$name};
        my $reads = $entry->{depends_on_columns} // {};
        for my $relation (keys %$reads) {
          push @{ $readers{$relation}{$_} }, {
            kind => $kind, table => $table, name => $name,
            schema_name => $entry->{schema_name}, table_name => $entry->{table_name},
          } for @{ $reads->{$relation} };
        }
      }
    }
  }
  for my $table (sort keys %{ $cols // {} }) {
    for my $column (@{ $cols->{$table} }) {
      push @{ $readers{$table}{$_} }, {
        kind => 'generated column', table => $table, name => $column->{column_name},
      } for @{ $column->{depends_on_columns} // [] };
    }
  }
  for my $view (sort keys %{ $outside // {} }) {
    my $info  = $outside->{$view};
    my $reads = $info->{depends_on_columns} // {};
    for my $relation (keys %$reads) {
      push @{ $readers{$relation}{$_} }, {
        kind => $info->{kind} eq 'm' ? 'materialized view' : 'view',
        table => $view, name => $info->{table_name}, schema_name => $info->{schema_name},
        table_name => $info->{table_name}, outside => 1,
      } for @{ $reads->{$relation} };
    }
  }
  return \%readers;
}

# The statement that removes a reader, and the one that makes it again where
# the target says how.
sub _drop_reader_sql {
  my ($reader) = @_;
  my $on = quote_qualified(DBIO::PostgreSQL::Introspect->key_names(
    $reader->{table}, table_name => $reader));
  my $name = quote_ident($reader->{name});
  my $kind = $reader->{kind};
  return "DROP POLICY $name ON $on;"        if $kind eq 'policy';
  return "DROP TRIGGER $name ON $on;"       if $kind eq 'trigger';
  return "ALTER TABLE $on DROP COLUMN $name;" if $kind eq 'generated column';
  return 'DROP ' . uc($kind) . " $on;";
}

sub _describe_reader {
  my ($reader) = @_;
  my $kind = $reader->{kind};
  return "$kind $reader->{table}" . ($reader->{outside} ? ' (outside the declared schemas)' : '')
    if $kind =~ /view/;
  return "$kind $reader->{table}.$reader->{name}" if $kind eq 'generated column';
  return "$kind $reader->{name} on $reader->{table}";
}

# A column whose type changes while a policy, a trigger or a generated column
# reads it, or a view the model does not hold. PostgreSQL does not alter such
# a column, and the diff does not drop and create these again: a policy and a
# trigger would be created by the sections behind the columns, but only
# the model's own objects are the diff's, and what a generated column or an
# outside view has lost is not in it.
sub _refuse_type_change_under_readers {
  my ($table_key, $column, $from, $to, @readers) = @_;
  my %seen;
  @readers = grep { !$seen{ join "\0", @{$_}{qw( kind table name )} }++ } @readers;

  my %server = (
    'policy'            => 'cannot alter type of a column used in a policy definition',
    'trigger'           => 'cannot alter type of a column used in a trigger definition',
    'generated column'  => 'cannot alter type of a column used by a generated column',
    'view'              => 'cannot alter type of a column used by a view or rule',
    'materialized view' => 'cannot alter type of a column used by a view or rule',
  );
  my @kinds = do { my %k; grep { !$k{$_}++ } map { $_->{kind} } @readers };

  die join "\n",
    sprintf('refusing to diff: column %s.%s changes its type from %s to %s while %s depends on it',
      $table_key, $column, $from, $to, join(', ', map { _describe_reader($_) } @readers)),
    '',
    'PostgreSQL does not alter the type of a column that a policy, a trigger\'s WHEN',
    'or UPDATE OF, a generated column or a view uses ('
      . join('; ', map { $server{$_} } @kinds) . ').',
    'The diff does not take these out of the way and put them back: only the views',
    'the declaration has are, and the other objects are not the type change\'s to',
    'drop. No statement was generated.',
    '',
    'Take them out yourself, then diff again:',
    ( map { '  ' . _drop_reader_sql($_) } @readers ),
    'The diff then alters the column and creates again what the target has',
    ( ( grep { $_->{outside} } @readers )
        ? '(a view outside the declared schemas is not the target\'s: create it again yourself, after).'
        : '(a policy, a trigger or a generated column the target declares).' ),
    'Or change the type by hand, with the statements above and their CREATE',
    'statements around it, in one transaction.',
    '';
}

# The relations whose columns $column of $table_key is: the table itself and
# the tables that have the column from it.
sub _holders {
  my ($table_key, $column, $children, $source_cols) = @_;
  my (@holders, %asked);
  my @todo = ($table_key);
  while (defined(my $key = shift @todo)) {
    next if $asked{$key}++;
    push @holders, $key;
    push @todo, sort grep {
      grep { $_->{column_name} eq $column } @{ $source_cols->{$_} // [] }
    } @{ $children->{$key} // [] };
  }
  return @holders;
}

# The views that read $column of $table_key, or of a table that has it from
# this one: [ view key, table key it reads it in ], each view once.
sub _read_by {
  my ($table_key, $column, $readers, $children, $source_cols) = @_;
  my (@holders, %asked);
  my @todo = ($table_key);
  while (defined(my $key = shift @todo)) {
    next if $asked{$key}++;
    push @holders, $key;
    push @todo, sort grep {
      grep { $_->{column_name} eq $column } @{ $source_cols->{$_} // [] }
    } @{ $children->{$key} // [] };
  }
  my %named;
  return grep { !$named{ $_->[0] }++ }
    map { my $in = $_; map { [ $_, $in ] } @{ $readers->{$in}{$column} // [] } } @holders;
}


sub type_changed_readers {
  my ($class, $source_cols, $target_cols, $source_tables, $target_tables) = @_;
  $source_cols //= {}; $target_cols //= {};
  $source_tables //= {}; $target_tables //= {};

  my $readers = _readers($source_tables);
  return {} unless %$readers;
  my %children;
  for my $key (keys %$source_tables) {
    push @{ $children{$_} }, $key for _parents($source_tables->{$key});
  }

  my %found;
  for my $table_key (sort keys %$target_cols) {
    next unless exists $source_tables->{$table_key} && exists $target_tables->{$table_key};
    next if grep { DBIO::PostgreSQL::Diff::View->is_view($_->{$table_key}) }
      $source_tables, $target_tables;
    my %was = map { $_->{column_name} => $_ } @{ $source_cols->{$table_key} // [] };
    for my $now (@{ $target_cols->{$table_key} }) {
      my $name = $now->{column_name};
      next unless $was{$name} && _render_type($was{$name}) ne _render_type($now);
      $found{ $_->[0] } = 1
        for _read_by($table_key, $name, $readers, \%children, $source_cols);
    }
  }
  return \%found;
}

sub diff {
  my ($class, $source_cols, $target_cols, $source_tables, $target_tables,
      $source_types, $target_types, $source_policies, $target_policies,
      $source_triggers, $target_triggers, $source_outside, $target_outside,
      $extensions) = @_;
  my (@ops, @case_only, @extension_refusals);
  my $others = _other_readers(
    $source_cols, $source_policies, $source_triggers, $source_outside);

  # The columns of each table that has been through the loop below, by name:
  # as the statements for the tables above it leave them, and as the target
  # has them.
  my (%before, %after);
  my $readers = _readers($source_tables);
  my %children;
  for my $key (keys %$source_tables) {
    push @{ $children{$_} }, $key for _parents($source_tables->{$key});
  }

  # Only diff columns for tables that exist in both source and target.
  # Brand new tables are handled by Diff::Table as full CREATE TABLE
  # statements with columns inline. A table comes behind the tables it has
  # columns from: what is its own is changed after what comes down to it.
  for my $table_key (_parents_first($source_tables, sort keys %$target_cols)) {
    next unless exists $source_tables->{$table_key} && exists $target_tables->{$table_key};
    next if grep { DBIO::PostgreSQL::Diff::View->is_view($_->{$table_key}) }
      $source_tables, $target_tables;

    my ($table_name, $schema_name) = reverse DBIO::PostgreSQL::Introspect->key_names(
      $table_key, table_name => $target_tables->{$table_key}, $source_tables->{$table_key},
    );
    my @table = (
      table_key   => $table_key,
      schema_name => $schema_name,
      table_name  => $table_name,
    );

    my %source_by_name = map { $_->{column_name} => $_ } @{ $source_cols->{$table_key} // [] };
    my %target_by_name = map { $_->{column_name} => $_ } @{ $target_cols->{$table_key} // [] };

    # What goes down from this table to the ones that have columns from it
    # is all that changes in it, whether by a statement for it or by one for
    # a table above it.
    $before{$table_key} = { %source_by_name };
    $after{$table_key}  = \%target_by_name;

    # A partition, or a table that inherits: what the statements for the
    # tables above it have done to its columns by now.
    my @parents = grep { $before{$_} && $_ ne $table_key } _parents($source_tables->{$table_key});
    %source_by_name = %{ _after_cascade(
      \%source_by_name, \%target_by_name, map { [ $before{$_}, $after{$_} ] } @parents,
    ) } if @parents;
    my $from_parents = sub {
      my ($name) = @_;
      return grep { $after{$_}{$name} } @parents;
    };

    # A column to add beside one to drop that is the same name but for its
    # case: refused below, for every table at once.
    push @case_only, map {
      my ($old, $new) = map { $_->{name} } @$_;
      {
        kind     => 'column',
        database => "$table_key.$old",
        target   => "$table_key.$new",
        rename   => sprintf('ALTER TABLE %s RENAME COLUMN %s TO %s;',
          quote_qualified(grep { defined } $schema_name, $table_name),
          quote_ident($old), quote_ident($new)),
      }
    } DBIO::PostgreSQL::Diff::CaseOnly->pairs(
      map { [ map { { in => [], name => $_ } } keys %$_ ] } \%source_by_name, \%target_by_name,
    );

    # New columns
    for my $col_name (sort keys %target_by_name) {
      next if exists $source_by_name{$col_name};
      _refuse_not_at_parent(add => $table_key, $col_name, $source_tables->{$table_key}{partition_of})
        if @parents && defined $source_tables->{$table_key}{partition_of};
      push @ops, $class->new(
        action      => 'add',
        @table,
        column_name => $col_name,
        new_info    => $target_by_name{$col_name},
      );
    }

    # Dropped columns
    for my $col_name (sort keys %source_by_name) {
      next if exists $target_by_name{$col_name};
      _refuse_not_at_parent(drop => $table_key, $col_name, $from_parents->($col_name))
        if $from_parents->($col_name);
      push @ops, $class->new(
        action      => 'drop',
        @table,
        column_name => $col_name,
        old_info    => $source_by_name{$col_name},
      );
    }

    # Altered columns
    for my $col_name (sort keys %target_by_name) {
      next unless exists $source_by_name{$col_name};
      my $src = $source_by_name{$col_name};
      my $tgt = $target_by_name{$col_name};

      my @changed = changed_fields($src, $tgt, %_COLUMN_FIELD_SPEC);

      # Both models come from a catalog, so a target without a default is a
      # column without one; the desired-state rule of changed_fields, which
      # skips a field the target leaves undef, would keep the database's
      # (karr k150). A generated column keeps its expression there and is
      # refused below, not dropped.
      push @changed, 'default_value'
        if !grep({ $_ eq 'default_value' } @changed)
          && !defined $tgt->{default_value}
          && defined $src->{default_value} && length $src->{default_value}
          && !length($src->{generated} // '') && !length($tgt->{generated} // '');
      next unless @changed;

      # How the column is generated: the mark, and for a generated column
      # the expression, which the model has in default_value.
      _refuse_generated_change(
        $table_key, quote_qualified($schema_name, $table_name), $src, $tgt,
      ) if ($src->{generated} // '') ne ($tgt->{generated} // '')
        || (length($tgt->{generated} // '')
            && ($src->{default_value} // '') ne ($tgt->{default_value} // ''));

      # A type that changes: not at a table that only has the column from
      # another, and not while a view reads the column -- here, or in a table
      # that has the column from this one.
      my ($from, $to) = map { _render_type($_) } $src, $tgt;
      if ($from ne $to) {
        # Composite to composite: only a type of the same attributes is
        # converted, through its text.
        if ((_type_kind($src) // '') eq 'composite' && (_type_kind($tgt) // '') eq 'composite') {
          my ($shape_from, $shape_to)
            = (_composite_shape($src, $source_types), _composite_shape($tgt, $target_types));
          _refuse_composite_change(
            $table_key, quote_qualified($schema_name, $table_name), $col_name, $from, $to, $shape_from, $shape_to)
            if defined $shape_from && defined $shape_to && $shape_from ne $shape_to;
        }

        _refuse_not_at_parent(type => $table_key, $col_name, $from_parents->($col_name))
          if $from_parents->($col_name);

        # A policy, a trigger or a generated column of the database, or a
        # view outside the schemas of the model: not the diff's to take out
        # of the way.
        my @others = map { @{ $others->{$_}{$col_name} // [] } }
          _holders($table_key, $col_name, \%children, $source_cols);
        _refuse_type_change_under_readers($table_key, $col_name, $from, $to, @others)
          if @others;

        my @read_by = _read_by($table_key, $col_name, $readers, \%children, $source_cols);

        # Views the target has are dropped and created again by
        # Diff::View; a view only the database has is named, and so is a
        # materialized view, which is not built anew for it.
        if (@read_by) {
          my @in_the_way = DBIO::PostgreSQL::Diff::View->with_dependents(
            $source_tables, map { $_->[0] } @read_by);
          my @undeclared = grep {
            !exists $target_tables->{$_}
              || !DBIO::PostgreSQL::Diff::View->is_view($target_tables->{$_})
          } @in_the_way;
          _refuse_type_change_under_undeclared_view(
            $table_key, $col_name, $from, $to, $source_tables, @undeclared)
            if @undeclared;
          my @matviews = grep { $source_tables->{$_}{kind} eq 'm' } @in_the_way;
          _refuse_type_change_under_matview(
            $table_key, $col_name, $from, $to, $source_tables, \@read_by, \@in_the_way, @matviews)
            if @matviews;
        }
      }

      # What the extensions of the schema say to a change of the type
      # (ADR 0066, phase 3): a USING of their own, or a refusal.
      my $using;
      if ($from ne $to && $extensions) {
        my $answer = $extensions->verdict({
          kind        => 'column_type',
          table       => $table_key,
          schema_name => $schema_name,
          table_name  => $table_name,
          column_name => $col_name,
          old_info    => $src,
          new_info    => $tgt,
          old_type    => $from,
          new_type    => $to,
        });
        if ($answer && $answer->{refuse}) {
          push @extension_refusals,
            map { "column $table_key.$col_name: $_" } @{ $answer->{refuse} };
        }
        elsif ($answer) {
          $using = $answer->{using};
        }
      }

      push @ops, $class->new(
        action      => 'alter',
        @table,
        column_name => $col_name,
        old_info    => $src,
        new_info    => $tgt,
        (defined $using ? (using => $using) : ()),
      );
      $ops[-1]->_type_change;   # the USING and the loss are decided once, here
    }
  }

  DBIO::PostgreSQL::Diff::CaseOnly->refuse(
    'DROP COLUMN takes what the column holds, in every row.', @case_only,
  );

  die join "\n",
    'refusing to diff: the extensions of the schema refuse the change of a column type:',
    (map { "  - $_" } @extension_refusals),
    '',
    'No statement was generated.',
    ''
    if @extension_refusals;

  return @ops;
}

# 'enum' or 'composite' for a column of such a type, else nothing. The model
# the diff reads is the catalog row (Introspect::Columns): data_type is the
# type's name and type_category its kind. An already normalized column says
# it with data_type 'enum' (Introspect::Normalize).
sub _type_kind {
  my ($info) = @_;
  my $category = $info->{type_category} // '';
  return 'enum'      if ($info->{data_type} // '') eq 'enum' || $category eq 'e';
  return 'composite' if $category eq 'c';
  return;
}

# The attributes of the composite type a column has, in order, as one string;
# undef where the model of types does not hold it.
sub _composite_shape {
  my ($info, $types) = @_;
  return unless ref $types eq 'HASH' && defined $info->{composite_type};
  my $type = $types->{ DBIO::PostgreSQL::Introspect->qualified_key(
    $info->{type_schema} // 'public', $info->{composite_type}) } or return;
  return join ', ', map { "$_->{name} $_->{type}" }
    sort { $a->{ordinal} <=> $b->{ordinal} } @{ $type->{attributes} // [] };
}

# A composite type gives the value to another through its text, which is
# positional: a type with other attributes would read the same text as other
# fields, or fail on it, depending on the rows.
sub _refuse_composite_change {
  my ($table_key, $table, $column, $from, $to, $shape_from, $shape_to) = @_;
  my ($old, $new) = map { quote_ident($_) } $column, "${column}_new";
  die join "\n",
    "refusing to diff: column $table_key.$column changes from composite type $from to $to, which has other attributes",
    '',
    "  $from: ($shape_from)",
    "  $to: ($shape_to)",
    '',
    'PostgreSQL has no cast from one composite type to another, and the text of a',
    'value is read by position: with other attributes it fails on some rows or reads',
    'the same text as other fields. No statement was generated.',
    '',
    'Say how a value of the old type becomes one of the new, with a column of the',
    'new type beside the old one:',
    "  ALTER TABLE $table ADD COLUMN $new $to;",
    "  UPDATE $table SET $new = ROW(...)::$to;",
    "  ALTER TABLE $table DROP COLUMN $old;",
    "  ALTER TABLE $table RENAME COLUMN $new TO $old;",
    'and diff again.',
    '';
}

# Render a column's PostgreSQL type string from its introspect-shaped info
# hashref: data_type plus size. A scalar size becomes data_type(size)
# (e.g. varchar(100)); an arrayref size becomes data_type(p,s) (e.g.
# numeric(10,2)); no size leaves data_type untouched. Where the modifier
# stands is the rule of DBIO::PostgreSQL::Util::type_with_modifier -- behind
# the first word of "timestamp with time zone", not at its end. Enum columns
# carry the literal 'enum' in data_type with the real PG type name in
# pg_enum_type (e.g. auth.role_type), so render that name instead.
sub _render_type {
  my ($info, $context) = @_;
  if (($info->{data_type} // '') eq 'enum' && defined $info->{pg_enum_type}) {
    return $info->{pg_enum_type};
  }
  return type_with_modifier($info->{data_type} // '', $info->{size}, $context);
}

# The pairs of types a column changes between without altering a stored
# value, as DBIO::Diff::Compare::column_change_lossy reads them (old->new, in
# lower case, of the type names as format_type writes them). What is left out
# is left out on purpose: char(n) and bit(n) pad on a change, real to double
# precision shows another text, timestamp and timestamptz depend on the
# session's time zone, text to varchar(n) cuts.
my %LOSSLESS_PAIRS = map { $_ => 1 } (
  'smallint->integer', 'smallint->bigint', 'integer->bigint', 'varchar->text',
);

# The types whose modifier only grows a limit: a larger one keeps every value
# (the core compares the numbers; numeric has its own rule below).
my %SIZE_LIMIT_ONLY = map { $_ => 1 } (
  'varchar', 'timestamp', 'timestamp with time zone', 'time', 'time with time zone',
);

my %TYPE_ALIAS = (
  'character varying' => 'varchar', int2 => 'smallint', int4 => 'integer', int => 'integer',
  int8 => 'bigint', decimal => 'numeric', timestamptz => 'timestamp with time zone',
);

# 'numeric(10,2)' as ('numeric', [10, 2]); 'timestamp(3) with time zone' as
# ('timestamp with time zone', [3]); a type without modifier has no list.
sub _split_type {
  my ($type) = @_;
  $type = lc($type // '');
  $type =~ s/\s+/ /g;
  $type =~ s/\A | \z//g;
  my @params;
  if ($type =~ /\A([a-z0-9_ ]+?) ?\(([0-9, ]+)\)(.*)\z/) {
    my ($head, $list, $tail) = ($1, $2, $3);
    @params = split /\s*,\s*/, $list;
    $type = "$head$tail";
    $type =~ s/ +\z//;
  }
  return ($TYPE_ALIAS{$type} // $type, @params ? \@params : undef);
}

# True when the change from the type $old to the type $new (as rendered, with
# modifier) may alter or lose a stored value. Anything not known to keep every
# value is lossy.
sub _type_change_is_lossy {
  my ($old, $new) = @_;
  return 0 if lc($old) eq lc($new);
  my ($old_base, $old_params) = _split_type($old);
  my ($new_base, $new_params) = _split_type($new);

  if ($old_base eq 'numeric' && $new_base eq 'numeric') {
    return 0 unless $new_params;          # numeric without limit takes every value
    return 1 unless $old_params;
    my ($p, $s)   = ($old_params->[0], $old_params->[1] // 0);
    my ($np, $ns) = ($new_params->[0], $new_params->[1] // 0);
    # the scale does not shrink and the digits before the point do not shrink
    return ($ns >= $s && $np - $ns >= $p - $s) ? 0 : 1;
  }
  return 0 if $old_base eq 'text' && $new_base eq 'varchar' && !$new_params;   # the same strings
  return 1 if $old_base eq $new_base && !$SIZE_LIMIT_ONLY{$old_base};
  return column_change_lossy(
    { data_type => $old_base, (defined $old_params ? (size => $old_params) : ()) },
    { data_type => $new_base, (defined $new_params ? (size => $new_params) : ()) },
    \%LOSSLESS_PAIRS,
  ) ? 1 : 0;
}

# What the change of the column's type comes to, decided once for the
# operation and kept: the rendered types, the USING (given by an extension, or
# by a hook of register_using_hook) and whether the change may alter a stored
# value. L</lossy> and L</as_sql> read it, so that the statement and the answer
# to the guard of the deploy cannot differ.
sub _type_change {
  my ($self) = @_;
  return $self->{_type_change} //= do {
    my ($src, $tgt) = ($self->old_info // {}, $self->new_info // {});
    my $context = ($self->table_key // '') . '.' . ($self->column_name // '');
    my ($src_type, $tgt_type) = (_render_type($src, $context), _render_type($tgt, $context));
    my $using;
    if ($src_type ne $tgt_type) {
      $using = defined $self->using && length $self->using ? $self->using
        : _type_kind($tgt) ? undef
        : _using_from_hooks($self, quote_ident($self->column_name // ''), $src, $tgt, $src_type, $tgt_type);
    }
    my $lossy = $src_type eq $tgt_type ? 0
      : (defined $using && length $using) || _type_kind($tgt) || _type_kind($src)
        || _type_change_is_lossy($src_type, $tgt_type) ? 1 : 0;
    { src_type => $src_type, tgt_type => $tgt_type, using => $using, lossy => $lossy };
  };
}


sub lossy {
  my ($self) = @_;
  return 0 unless ($self->action // '') eq 'alter' && $self->old_info && $self->new_info;
  return $self->_type_change->{lossy};
}

# The registry of USING hooks: [ name, coderef ] in registration order.
my @_USING_HOOKS;


sub register_using_hook {
  my ($class, $name, $code) = @_;
  die "register_using_hook: a name is required\n"
    unless defined $name && !ref $name && length $name;
  die "register_using_hook: hook '$name' is not a code reference\n"
    unless ref $code eq 'CODE';
  @_USING_HOOKS = grep { $_->[0] ne $name } @_USING_HOOKS;
  push @_USING_HOOKS, [ $name, $code ];
  return;
}


sub unregister_using_hook {
  my ($class, $name) = @_;
  @_USING_HOOKS = grep { $_->[0] ne ($name // '') } @_USING_HOOKS;
  return;
}

sub _using_from_hooks {
  my ($self, $column, $src, $tgt, $src_type, $tgt_type) = @_;
  for my $hook (@_USING_HOOKS) {
    my ($name, $code) = @$hook;
    my $using = $code->({
      table_key   => $self->table_key,
      column_name => $self->column_name,
      column      => $column,
      old_info    => $src,
      new_info    => $tgt,
      old_type    => $src_type,
      new_type    => $tgt_type,
    });
    next unless defined $using;
    die sprintf "USING hook '%s' for column %s.%s returned a %s reference, not a plain string\n",
      $name, $self->table_key // '', $self->column_name, ref $using
      if ref $using;
    next unless length $using;
    return $using;
  }
  return undef;
}


sub as_sql {
  my ($self) = @_;
  my $table = quote_qualified(
    DBIO::PostgreSQL::Introspect->key_names($self->table_key, table_name => $self));
  my $column = quote_ident($self->column_name);
  my $object = sprintf 'column %s.%s', $self->table_key // '', $self->column_name;
  my $context = ($self->table_key // '') . '.' . $self->column_name;

  if ($self->action eq 'add') {
    my $type = _render_type($self->new_info, $context);
    DBIO::PostgreSQL::Diff::NoStatement->throw(
      $self, $object, 'its new_info has no data_type, and a column is added with a type',
    ) unless $type =~ /\S/;
    my $sql = sprintf 'ALTER TABLE %s ADD COLUMN %s %s',
      $table, $column, $type;
    $sql .= ' NOT NULL' if $self->new_info->{not_null};
    my $kind = DBIO::PostgreSQL::Introspect->identity_kind($self->new_info->{identity});
    if (my $generated = DBIO::PostgreSQL::Introspect->generated_kind($self->new_info->{generated})) {
      # default_value is the expression the column is computed from
      $sql .= sprintf ' GENERATED ALWAYS AS (%s) %s',
        $self->new_info->{default_value}, $generated;
    }
    elsif ($kind) {
      $sql .= " GENERATED $kind AS IDENTITY";
    }
    elsif (defined $self->new_info->{default_value}) {
      $sql .= sprintf ' DEFAULT %s', $self->new_info->{default_value};
    }
    return "$sql;";
  }
  elsif ($self->action eq 'drop') {
    return sprintf 'ALTER TABLE %s DROP COLUMN %s;',
      $table, $column;
  }
  elsif ($self->action eq 'alter') {
    my @stmts;
    my $src = $self->old_info;
    my $tgt = $self->new_info;

    # Compare the fully rendered type strings (data_type + size), so a
    # size-only change (varchar(50) -> varchar(100), numeric(10,2) ->
    # numeric(12,2)) emits an ALTER even though data_type is unchanged.
    my $change   = $self->_type_change;
    my ($src_type, $tgt_type) = @{$change}{qw( src_type tgt_type )};
    my $default_dropped;
    if ($src_type ne $tgt_type) {
      my $stmt = sprintf 'ALTER TABLE %s ALTER COLUMN %s TYPE %s',
        $table, $column, $tgt_type;
      # An enum or composite target has no implicit cast from the previous
      # type; route the conversion through text so the generated ALTER is
      # executable. The server also casts the column's default to the new
      # type and cannot do so for these, so the default stands out of the way
      # (karr k121).
      if (_type_kind($tgt)) {
        $stmt .= defined $change->{using} && length $change->{using}
          ? ' USING ' . $change->{using}
          : sprintf ' USING %s::text::%s', $column, $tgt_type;
        if (defined $src->{default_value} && $src->{default_value} ne ''
            && !length($src->{generated} // '')) {
          push @stmts, sprintf 'ALTER TABLE %s ALTER COLUMN %s DROP DEFAULT;',
            $table, $column;
          $default_dropped = 1;
        }
      }
      else {
        $stmt .= " USING $change->{using}" if defined $change->{using};
      }
      push @stmts, "$stmt;";
    }
    if (($src->{not_null} // 0) != ($tgt->{not_null} // 0)) {
      if ($tgt->{not_null}) {
        push @stmts, sprintf 'ALTER TABLE %s ALTER COLUMN %s SET NOT NULL;',
          $table, $column;
      } else {
        push @stmts, sprintf 'ALTER TABLE %s ALTER COLUMN %s DROP NOT NULL;',
          $table, $column;
      }
    }
    # Identity transitions. attidentity is '' (none), 'a' (ALWAYS), 'd' (BY
    # DEFAULT). An identity and a default do not stand on one column, so the
    # one goes before the other comes: DROP IDENTITY ahead of SET DEFAULT
    # (column ... is an identity column), DROP DEFAULT ahead of ADD GENERATED
    # (column ... already has a default value).
    my $src_id = $src->{identity} // '';
    my $tgt_id = $tgt->{identity} // '';
    my $src_kind = DBIO::PostgreSQL::Introspect->identity_kind($src_id);
    my $tgt_kind = DBIO::PostgreSQL::Introspect->identity_kind($tgt_id);
    if ($src_kind && !$tgt_kind) {
      push @stmts, sprintf 'ALTER TABLE %s ALTER COLUMN %s DROP IDENTITY;',
        $table, $column;
    }

    if ($default_dropped || ($src->{default_value} // '') ne ($tgt->{default_value} // '')) {
      if (defined $tgt->{default_value} && $tgt->{default_value} ne '') {
        push @stmts, sprintf 'ALTER TABLE %s ALTER COLUMN %s SET DEFAULT %s;',
          $table, $column, $tgt->{default_value};
      } elsif (!$default_dropped) {
        push @stmts, sprintf 'ALTER TABLE %s ALTER COLUMN %s DROP DEFAULT;',
          $table, $column;
      }
    }

    if ($src_id ne $tgt_id && $tgt_kind) {
      push @stmts, sprintf 'ALTER TABLE %s ALTER COLUMN %s %s;', $table, $column,
        ( $src_kind ? "SET GENERATED $tgt_kind" : "ADD GENERATED $tgt_kind AS IDENTITY" );
    }
    DBIO::PostgreSQL::Diff::NoStatement->throw(
      $self, $object,
      'old_info and new_info differ in nothing the diff has a statement for (type, NOT NULL, default, identity)',
    ) unless @stmts;
    return join "\n", @stmts;
  }
  DBIO::PostgreSQL::Diff::NoStatement->throw($self, $object);
}


sub summary {
  my ($self) = @_;
  my $prefix = $self->summary_prefix;
  my $type = $self->new_info ? " ($self->{new_info}{data_type})" : '';
  return sprintf '  %scolumn: %s.%s%s', $prefix, $self->table_key, $self->column_name, $type;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Diff::Column - Diff operations for PostgreSQL columns

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents a column-level diff operation: C<ADD COLUMN>, C<DROP COLUMN>, or
C<ALTER COLUMN> (type change, nullability change, or default change). Only
columns on tables that exist in both source and target are compared, and none
of a view or a materialized view.

=head1 ATTRIBUTES

=head2 table_key

The C<schema.table> key identifying which table the column belongs to. It is
where the model files the table, and what L</summary> prints; it is not SQL.

=head2 schema_name

The schema of that table.

=head2 table_name

The name of that table. L</as_sql> writes the table from C<schema_name> and
C<table_name>, each quoted for itself -- the key cannot be taken apart again,
a schema or a table may have a dot in its name. L</diff> takes both from the
C<tables> sections. An operation built by hand without them falls back to the
key (L<DBIO::PostgreSQL::Introspect/key_names>).

=head2 column_name

The column name.

=head2 old_info

The source column metadata hashref (present for C<drop> and C<alter>).

=head2 new_info

The target column metadata hashref (present for C<add> and C<alter>).

=head2 using

For an C<alter> that changes the column's type: the C<USING> expression an
extension supplied by its verdict (L</diff>), written in place of the cast the
diff would write. Unset when no extension answered.

=head1 METHODS

=head2 diff

    my @ops = DBIO::PostgreSQL::Diff::Column->diff(
        $source_cols, $target_cols, $source_tables, $target_tables,
    );

Compares column lists for tables that exist in both source and target.
Detects added columns, dropped columns, and altered columns (data type,
C<NOT NULL>, default value, or identity kind).

A view or a materialized view is passed over: its columns are what its
definition says, and L<DBIO::PostgreSQL::Diff::View> compares that.

A change to how an existing column is generated is B<refused>, with
C<refusing to diff: ...> naming the table, the column and what changes, and no
statement: an ordinary column that is a generated one in the target or the
other way round, a stored generated column that is a virtual one in the target
or the other way round, and a generated column with another expression. For a
generated column the catalog keeps the expression where it keeps a default, so
such a change would come out as C<ALTER COLUMN ... SET DEFAULT>, which
PostgreSQL does not take for a generated column -- and of the statements that
do change one, C<SET EXPRESSION> exists from PostgreSQL 17 on only and no
statement turns an ordinary column into a generated one.

A column to add whose name differs only in upper and lower case from one to
drop in the same table -- C<createdAt> in the target, C<createdat> in the
database -- is B<refused> as well (L<DBIO::PostgreSQL::Diff::CaseOnly>): the
two are most likely one column, and C<DROP COLUMN> takes what it holds in
every row. The message names the table and both columns, for every table at
once, and the way out: C<ALTER TABLE public.acct RENAME COLUMN createdat TO
"createdAt">.

A column that changes its type while a view reads it is not altered in place:
PostgreSQL does not (C<cannot alter type of a column used by a view or rule>).
The views the target has -- the declaration's -- are dropped, with the views
that stand on them, ahead of everything that is done to tables, and created
again behind the columns in the order they depend on one another, from the
definition of the target (L<DBIO::PostgreSQL::Diff::View/diff>), all of it in
the one transaction C<apply> runs a diff in. It is the views of the
I<database> that read the column that count, and only those that read this
column (L<DBIO::PostgreSQL::Introspect::Tables/fetch>, C<depends_on_columns>)
-- also one that reads it in a partition or in a table that inherits it,
which holds the column of the table above just the same. What a dropped view
loses is what the model does not hold: privileges granted on it, its comment,
its options.

Two kinds of view are not dropped for it, and the change is B<refused>:

=over 4

=item * a view that only the database has -- one the target does not -- that
reads the column, or stands on a view that does: it is not the declaration's
to create again, and dropping it takes what nobody declared. The message
names the table, the column, both types and the views, and the way out: the
C<DROP VIEW> statements for them, in order; the diff after that alters the
column and creates again the views the target has.

=item * a materialized view that reads the column, or stands on a view that
does (and would be dropped with it): dropping it builds its data anew and
takes the indexes on it with it. The message names the table, the column,
both types and the materialized views (C<through> the view it stands on, or
C<in> the partition it reads the column in), and the way out: the C<DROP
MATERIALIZED VIEW> statements for them and for the views that stand on them,
in order; the diff after that alters the column, creates again the views the
target has and creates the materialized view as the target has it.

=back

A change that
is none of type -- C<NOT NULL>, the default -- is made under a view, and so is
the type of a column no view reads, of one a view reads only as part of the
whole row, and of one whose views the model has no columns for (a model built
by hand that gives C<depends_on> alone).

A column that changes from one composite type to another is B<refused> when
the two have other attributes (names, types or their order, from the C<types>
sections of the model): the text of a composite value is read by position, so
the conversion would fail on some rows or read the same text as other fields.
The message gives the attributes of both and the way out, a column of the new
type beside the old one. Two composite types of the same attributes are
converted through their text. A model that gives no C<types> is not asked, and
the server judges.

=head2 type_changed_readers

    my $views = DBIO::PostgreSQL::Diff::Column->type_changed_readers(
        $source_cols, $target_cols, $source_tables, $target_tables);

The views and materialized views of the database that read a column whose
type changes in the target, as a hashref of their keys. Only those: a view
that reads another column of the table, or the table as a whole row, is not
among them. L<DBIO::PostgreSQL::Diff::View/rebuilt> drops and creates again the
views among these that the target has, and so the diff asks one place what
the type change is read by; a materialized view among them is refused by
L</diff>.

=head2 lossy

True for an C<alter> that changes the column's type in a way that may alter or
lose a stored value; L<DBIO::Deploy::Base/apply> then runs only with
C<allow_destructive> (L<DBIO::Diff::Base/destructive_operations>). The answer
is made once, when the operation is built, with the statement's C<USING>.

A change is lossless between C<smallint>, C<integer> and C<bigint> in the
widening direction, from C<varchar> of any limit to C<text>, to a larger limit
or to none (C<varchar(n)> to C<varchar(m)>, m >= n, and C<text> to C<varchar> without a limit; the same for the precision
of C<timestamp>, C<timestamptz>, C<time> and C<timetz>), and for C<numeric(p,s)>
to C<numeric(p',s')> when the scale does not shrink and the digits before the
point do not (s' >= s and p'-s' >= p-s), or to C<numeric> without limit.
Everything else is lossy: a narrower type or limit, a change between other
types, any change to or from an enum or composite type, and every change that
carries a C<USING>. A change of nullability, default or identity is not lossy.
An enum that gains values is a change of L<DBIO::PostgreSQL::Diff::Type>, not of
a column, and not lossy.

=head2 register_using_hook

    DBIO::PostgreSQL::Diff::Column->register_using_hook(
        my_hook => sub {
            my ($ctx) = @_;
            return $ctx->{new_type} eq 'integer'
              ? "$ctx->{column}::integer" : undef;
        },
    );

Registers a hook, class-wide, that may supply the C<USING> expression of the
C<ALTER COLUMN ... TYPE> of a column whose type changes -- how a layer or
extension converts a value the server cannot cast on its own. The hook is
called with one hashref: C<table_key>, C<column_name>, C<column> (the quoted
identifier), C<old_info>, C<new_info>, C<old_type> and C<new_type> (the
rendered type strings). It returns the expression or C<undef>.

Hooks are asked in registration order, and only when the rendered type
changes and the target is no enum or composite type (that path writes its own
C<USING>). The first defined, non-empty answer is written as C<USING
EXPRESSION>. A hook that dies stops the diff, and an answer that is not a
plain string is refused. Registering a name again replaces that hook and puts
it last.

=head2 unregister_using_hook

    DBIO::PostgreSQL::Diff::Column->unregister_using_hook('my_hook');

Removes the hook of that name; a name nobody registered is ignored.

=head2 as_sql

Returns one or more C<ALTER TABLE> statements for this operation. For C<alter>,
may return multiple statements (one per changed attribute).

Table and column are written as identifiers by the server's rule
(L<DBIO::PostgreSQL::Util/quote_ident>). The column type and the default come
from the catalog (C<format_type>, C<pg_get_expr>) and are written as given. A
model that keeps a C<size> beside the type has it written as the type's
modifier, where the server takes it
(L<DBIO::PostgreSQL::Util/type_with_modifier>): C<timestamp with time zone>
and a size of 3 are C<timestamp(3) with time zone>.

C<ADD COLUMN> writes a generated column as one, C<GENERATED ALWAYS AS (expr)
STORED> or C<... VIRTUAL>, as L<DBIO::PostgreSQL::Diff::Table/as_sql> does in
C<CREATE TABLE>.

A default that calls a sequence (C<nextval('t_id_seq'::regclass)>, what
C<serial> comes to in the catalog) is written as it is, in C<ADD COLUMN> and
in C<SET DEFAULT>. The sequence is not made here: L<DBIO::PostgreSQL::Diff::Sequence>
creates it ahead of the column and L<DBIO::PostgreSQL::Diff::SequenceOwner>
gives it to the column behind it.

An identity and a default do not stand on one column, so an C<alter> takes
the one away before it puts the other: C<DROP IDENTITY> comes ahead of
C<SET DEFAULT> and C<DROP DEFAULT> (a column made C<serial> from an identity
column), and C<ADD GENERATED ... AS IDENTITY> or C<SET GENERATED> behind
them (a column made an identity column from C<serial>).

An C<alter> whose C<old_info> and C<new_info> differ in nothing this method
writes -- type, C<NOT NULL>, default, identity -- has no statement, and
neither has an C<action> this class does not know: C<as_sql> dies
(L<DBIO::PostgreSQL::Diff::NoStatement/throw>) and returns no empty string in
its place. The same holds for an C<add> whose C<new_info> has no
C<data_type>: C<ADD COLUMN> without a type is no SQL, so it dies instead of
writing it.

A type that changes to an enum or a composite type is written with C<USING
column::text::type>: PostgreSQL has no cast from the old type to it, and the
value goes through its text. A value the new type does not take -- text that
is no label of the enum -- is refused by the server, the upgrade is rolled
back and the column stays as it was. A default the column has is dropped
ahead of that statement, because the server casts it to the new type as well
and cannot, and set again behind it as the target has it. A change to text or
to another type the server converts on its own is written without C<USING>.

A type change an extension answered with a C<USING> (L</using>) is written
with it, in place of the cast above (the default of an enum or composite
target is dropped and set again around it as before). Any other type change asks the
hooks of L</register_using_hook>; the first expression one gives is written as
C<USING expression>. With none registered, or none answering, the statement has
no C<USING>.

=head2 summary

Returns a one-line description such as C<+column: auth.users.avatar (text)>.

=head2 A column that changes its type while something else reads it

A policy (C<USING>, C<WITH CHECK>), a trigger (C<WHEN>, C<UPDATE OF col>), a
generated column (C<GENERATED ALWAYS AS (expr) STORED>) and a view or
materialized view outside the schemas of the model (C<pg_schemas>) each stop
PostgreSQL from altering the type of a column they read: C<cannot alter type of
a column used in a policy definition>, C<... in a trigger definition>, C<...
used by a generated column>, C<... used by a view or rule>. The model carries
these as C<depends_on_columns> of the policy, the trigger and the generated
column and as the C<outside_readers> section
(L<DBIO::PostgreSQL::Introspect::Policies>,
L<DBIO::PostgreSQL::Introspect::Triggers>,
L<DBIO::PostgreSQL::Introspect::Columns>,
L<DBIO::PostgreSQL::Introspect::OutsideReaders>), all read from C<pg_depend>.

Such a type change is B<refused> when the operations are built, also where the
target keeps the object, and also where it drops it in the same diff (the
drops come behind the changes). The message names the table, the column, both
types and each object, and gives the statements that take them out of the way;
the diff after that alters the column and creates again the policies, triggers
and generated columns the target has. A view outside the declared schemas is
not the target's, so it is not created again. The diff does not drop and
create these itself as it does the views of the declaration: a generated
column's values and a view's privileges and comment are not in the model. A
reader on a partition or on a table that inherits the column counts as well.
What a trigger's function or any function body reads is not known. Only the
views that read the column directly are named for the outside case; one that
stands on them is named by the server when they are dropped.

=head2 Partitions and tables that inherit

A partition has its columns from the partitioned table, and a table that
inherits has some from the tables it inherits from
(L<DBIO::PostgreSQL::Introspect::Tables/fetch>, C<partition_of> and
C<inherits>, as the model of the database has them). PostgreSQL changes such a
column where it comes from and carries the change down; at the table that
only has it, it refuses the statement (C<cannot add column to a partition>,
C<cannot drop inherited column>, C<cannot alter inherited column>). So a table
comes behind the tables it has columns from, and is compared not as the
database has it but as the statements for those leave it:

=over 4

=item * a column added above is in it, as it is above;

=item * a column dropped above is gone from it -- unless the table defines the
column itself as well (C<is_local>,
L<DBIO::PostgreSQL::Introspect::Columns/fetch>), in which case it stays, as
the table's own, and gets a C<DROP COLUMN> of its own if the target does not
have it;

=item * a type altered above is altered in it;

=item * a default set or dropped above is set or dropped in it, also where it
had one of its own -- which is then set again, behind;

=item * C<NOT NULL> set above is set in it.

=back

What is left to do is the table's own, and is written for it: a default of
its own, a C<NOT NULL> of its own, a column of its own in a table that
inherits. Two things are not carried down for certain and are asked of the
table itself. C<DROP NOT NULL> above leaves a C<NOT NULL> the table has of its
own, and the model cannot tell that from an inherited one: where the target
has the column nullable, the statement is written for the table too, behind
the one above, and does nothing where that one did it already. An identity is
a partition's as it is the partitioned table's and is not inherited by a
table that inherits; the table is taken to have got it where the target has
it the same as above, so neither is assumed. All of this is as measured on
PostgreSQL 18.6.

A statement that could only be for the table above and is asked for the table
below alone -- a column to add to a partition, a column to drop from, or a
type to alter in, a table that has it from another which keeps it as it is --
is B<refused>. No database has a table differ from its parent that way; a
target model built by hand can.

The extensions the schema declares (ADR 0066) are asked about each change of a
column's type, through the protocol the diff was built with (the argument
C<extensions> of L<DBIO::PostgreSQL::Diff>, a L<DBIO::Extension::Protocol>;
without one nothing is asked). The change is a hashref

  { kind        => 'column_type',
    table       => $table_key,       schema_name => $schema, table_name => $table,
    column_name => $column,
    old_info    => \%column_info,    # the model's column, with the annotations
    new_info    => \%column_info,
    old_type    => $rendered_type,   new_type => $rendered_type }

The answer C<< { using => $expr } >> is written as the C<USING> of the
statement in place of the cast the diff would write (L</using>); C<< { refuse
=> [...] } >> refuses the diff -- every refusing column and every message,
C<refusing to diff: the extensions of the schema refuse ...>, no statement. The
class-wide hooks of L</register_using_hook> are driver-internal and are not
asked for an extension; a verdict's C<using> goes before them.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
