package DBIO::PostgreSQL::Diff::Index;
# ABSTRACT: Diff operations for PostgreSQL indexes

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::PostgreSQL::Diff::CaseOnly ();
use DBIO::PostgreSQL::Diff::NoStatement ();
use DBIO::PostgreSQL::Introspect ();
use DBIO::PostgreSQL::Util qw(quote_ident quote_qualified deferrable_clause);
use bytes ();

__PACKAGE__->mk_diff_accessors(qw(
  table_key schema_name table_name index_name index_info replaced via renamed_from partitions
));












# Every index of one model section, as { schema => { index name => entry } }.
sub _by_schema {
  my ($section, $tables) = @_;
  my %by_schema;
  for my $table_key (keys %$section) {
    for my $idx_name (keys %{ $section->{$table_key} }) {
      my $info = $section->{$table_key}{$idx_name};
      my ($table_name, $schema_name) = reverse DBIO::PostgreSQL::Introspect->key_names(
        $table_key, table_name => $info, $tables->{$table_key},
      );
      $by_schema{ $schema_name // '' }{$idx_name} = {
        table_key   => $table_key,
        schema_name => $schema_name,
        table_name  => $table_name,
        index_name  => $idx_name,
        index_info  => $info,
      };
    }
  }
  return \%by_schema;
}

# The entries of _by_schema in the order the operations come out: by index
# name, then by schema.
sub _in_order {
  my ($by_schema) = @_;
  return
    sort { $a->{index_name} cmp $b->{index_name} or ($a->{schema_name} // '') cmp ($b->{schema_name} // '') }
    map { values %$_ } values %$by_schema;
}

# The entries of _by_schema as DBIO::PostgreSQL::Diff::CaseOnly compares them:
# a name among the indexes of its table.
sub _named {
  my ($by_schema) = @_;
  return [
    map { { %$_, in => [ $_->{schema_name} // '', $_->{table_key} ], name => $_->{index_name} } }
    map { values %$_ } values %$by_schema
  ];
}

my %CONSTRAINT_KIND = (p => 'PRIMARY KEY', u => 'UNIQUE', x => 'EXCLUDE');

# The constraint an index stands behind, as the model says it: ($name, $type)
# with the type p, u or x, or an empty list for an index without one. A
# primary key's index is the constraint's, under the same name, whether or not
# the entry has the keys (a model built by hand may not).
sub _constraint {
  my ($info, $index_name) = @_;
  return ($info->{constraint_name}, $info->{constraint_type})
    if defined $info->{constraint_name} && defined $info->{constraint_type};
  return ($index_name, 'p') if $info->{is_primary} && defined $index_name;
  return;
}

# An index to create beside one to drop, on the same table, that is the same
# name but for its case -- where the one to drop stands behind a constraint:
# the drop takes the constraint, and the diff creates no constraint to put in
# its place.
sub _refuse_case_only {
  my ($src_indexes, $tgt_indexes) = @_;
  DBIO::PostgreSQL::Diff::CaseOnly->refuse(
    "The index to drop is the index of a constraint. PostgreSQL does not drop it by DROP\n"
      . "INDEX, and dropping the constraint builds the index again under the new name,\n"
      . 'where a rename keeps it.',
    map {
      my ($old, $new) = @$_;
      my @schema = grep { defined } $old->{schema_name};
      {
        kind     => 'index',
        database => join('.', @schema, $old->{name}),
        target   => join('.', @schema, $new->{name}),
        rename   => sprintf('ALTER INDEX %s RENAME TO %s;',
          quote_qualified(@schema, $old->{name}), quote_ident($new->{name})),
      }
    }
    grep { my @constraint = _constraint(@{$_->[0]}{qw( index_info index_name )}); scalar @constraint }
    DBIO::PostgreSQL::Diff::CaseOnly->pairs(_named($src_indexes), _named($tgt_indexes)),
  );
}

# The definition of an index without its name: the text pg_get_indexdef
# writes, the name behind INDEX replaced. Two indexes with this text in common
# are the same index under two names.
sub _definition_without_name {
  my ($definition) = @_;
  $definition //= '';
  $definition =~ s/\A(\s*CREATE\s+(?:UNIQUE\s+)?INDEX\s+(?:CONCURRENTLY\s+)?)(?:"(?:[^"]|"")*"|\S+)(\s+ON\s)/$1\0$2/i;
  return $definition;
}

# The index as a reader calls it, in a message: its name and its table.
sub _name {
  my ($index) = @_;
  return sprintf '%s on %s', $index->{index_name} // '', $index->{table_key} // '';
}

# Whether the index is one over NULLS NOT DISTINCT (PostgreSQL 15 and later).
# That is in no field of the model: pg_get_indexdef writes it behind the key
# list, and a constraint says it as UNIQUE NULLS NOT DISTINCT (cols).
sub _nulls_not_distinct {
  my ($info) = @_;
  return ($info->{definition} // '') =~ /\)\s+NULLS\s+NOT\s+DISTINCT\b/ ? 1 : 0;
}

# The timing of a UNIQUE constraint: its DEFERRABLE clause, with the space that
# leads it, or nothing. Only a UNIQUE constraint carries it in the model
# (karr k147); a primary key's is not read.
sub _timing {
  my ($info, $type) = @_;
  return '' unless ($type // '') eq 'u';
  return deferrable_clause($info->{deferrable}, $info->{initially_deferred});
}

# The constraint clause of the target, as far as the model carries it: what
# the diff writes for a constraint it creates, and, where it cannot write it,
# what it tells the reader. The elements of an EXCLUDE constraint are not in
# the model.
sub _add_constraint_sql {
  my ($info, $name, $type) = @_;
  my @columns = @{ $info->{columns} // [] };
  return sprintf 'ADD CONSTRAINT %s %s (...)', quote_ident($name), $CONSTRAINT_KIND{$type}
    if $type eq 'x' || !@columns || grep { !defined } @columns;
  my @include = @{ $info->{include_columns} // [] };
  my %with    = %{ $info->{storage_params} // {} };
  return sprintf 'ADD CONSTRAINT %s %s%s (%s)%s%s%s',
    quote_ident($name), $CONSTRAINT_KIND{$type},
    ($type eq 'u' && _nulls_not_distinct($info) ? ' NULLS NOT DISTINCT' : ''),
    join(', ', map { quote_ident($_) } @columns),
    (@include ? ' INCLUDE (' . join(', ', map { quote_ident($_) } @include) . ')' : ''),
    (%with ? ' WITH (' . join(', ', map { "$_ = $with{$_}" } sort keys %with) . ')' : ''),
    _timing($info, $type);
}

# Whether the source index and the target index differ in what the diff
# compares besides the text of the definition: the constraint behind it (kind),
# the key columns in the order of the key, the INCLUDE columns, the storage
# parameters. The text carries the columns, the INCLUDE list and the
# parameters as well; it does not carry the constraint (karr k139). Whether the
# index is valid is not compared: the index of a partitioned table is created
# from its text, ON ONLY, and is invalid until its partitions have theirs
# -- the diff would drop and create it again for ever.
sub _attributes_differ {
  my ($src, $tgt) = @_;
  my ($s, $t) = map { $_->{index_info} } $src, $tgt;
  my (undef, $stype) = _constraint($s, $src->{index_name});
  my (undef, $ttype) = _constraint($t, $tgt->{index_name});
  return 1 if ($stype // '') ne ($ttype // '');
  return 1 if _timing($s, $stype) ne _timing($t, $ttype);
  my $list = sub { join "\0", map { $_ // "\1" } @{ $_[0] // [] } };
  return 1 if $list->($s->{columns}) ne $list->($t->{columns});
  return 1 if $list->($s->{include_columns}) ne $list->($t->{include_columns});
  my $params = sub { my $p = $_[0] // {}; join "\0", map { "$_=$p->{$_}" } sort keys %$p };
  return 1 if $params->($s->{storage_params}) ne $params->($t->{storage_params});
  return 0;
}

# The statement a reader runs by hand to put the constraint of $tgt in place of
# the index $src, where the diff does not.
sub _by_hand {
  my ($src, $tgt) = @_;
  my ($name, $type) = _constraint($tgt->{index_info}, $tgt->{index_name});
  my @table = grep { defined } @{$tgt}{qw( schema_name table_name )};
  return (
    ( $src ? sprintf('  DROP INDEX %s;', quote_qualified(grep { defined } @{$src}{qw( schema_name index_name )})) : () ),
    sprintf('  ALTER TABLE %s %s;', quote_qualified(@table), _add_constraint_sql($tgt->{index_info}, $name, $type)),
  );
}

# Whether the foreign key $by, which points at a constraint that is to go, is
# gone before the constraint is: the target model declares foreign keys, has the
# table of the key, and either lacks the key or has it to other columns. The
# drops of the keys come ahead of the drops of the indexes (DBIO::PostgreSQL::
# Diff, ORDER OF OPERATIONS). A key the source model does not list -- the copy
# at a partition, which the introspection leaves out -- is not shown to be gone.
sub _foreign_key_goes {
  my ($by, $fk) = @_;
  my ($source_fks, $target_fks, $target_tables) = @{ $fk // [] };
  return 0 unless $target_fks;
  my $key = DBIO::PostgreSQL::Introspect->qualified_key(@{$by}{qw( schema_name table_name )});
  return 0 unless $target_tables && exists $target_tables->{$key};
  my $named = sub { grep { ($_->{constraint_name} // '') eq $by->{constraint_name} } @{ $_[0]{$key} // [] } };
  my ($old) = $named->($source_fks // {});
  return 0 unless $old;
  my ($new) = $named->($target_fks);
  return 1 unless $new;
  my $points = sub { join "\0", (map { $_[0]{$_} // '' } qw( remote_schema remote_table )), @{ $_[0]{remote_columns} // [] } };
  return $points->($old) ne $points->($new) ? 1 : 0;
}

# Why the constraint behind $src cannot go: the lines that say it, with the
# statements that settle it. Nothing when it can go -- as ALTER TABLE ... DROP
# CONSTRAINT, with the index. A foreign key that points at it is no reason when
# it is gone before the constraint is ($fk, see _foreign_key_goes); a constraint
# that is dropped and added again ($replaced) goes in the first half of the
# operations, ahead of any drop of a key.
sub _drop_reasons {
  my ($src, $replaced, $fk) = @_;
  my $info = $src->{index_info};
  my @by = grep { $replaced || !_foreign_key_goes($_, $fk) } @{ $info->{referenced_by} // [] }
    or return;
  return (
    'foreign keys of other tables point at it, and ALTER TABLE ... DROP CONSTRAINT would fail:',
    map {
      sprintf '  ALTER TABLE %s DROP CONSTRAINT %s;',
        quote_qualified(@{$_}{qw( schema_name table_name )}), quote_ident($_->{constraint_name})
    } @by,
  );
}

# The primary key constraint of the source on the table of $tgt, under another
# name than the primary key $tgt is: PostgreSQL takes one per table, and the
# diff creates before it drops.
sub _other_primary {
  my ($src_indexes, $tgt) = @_;
  my ($name, $type) = _constraint($tgt->{index_info}, $tgt->{index_name});
  return unless defined $type && $type eq 'p';
  for my $other (_in_order($src_indexes)) {
    next unless $other->{table_key} eq $tgt->{table_key};
    next if $other->{index_name} eq $tgt->{index_name};
    my (undef, $otype) = _constraint($other->{index_info}, $other->{index_name});
    return $other if defined $otype && $otype eq 'p';
  }
  return;
}

# Why the constraint of $tgt cannot be created as ALTER TABLE ... ADD
# CONSTRAINT (...): the lines that say it. Nothing when it can.
sub _create_reasons {
  my ($tgt, $src_indexes) = @_;
  my $info = $tgt->{index_info};
  my ($name, $type) = _constraint($info, $tgt->{index_name});
  my @table = grep { defined } @{$tgt}{qw( schema_name table_name )};
  my @reasons;

  if ($type eq 'x') {
    return (
      'it is an EXCLUDE constraint, and the model does not carry its elements, so the diff cannot write it:',
      sprintf('  ALTER TABLE %s ADD CONSTRAINT %s EXCLUDE (...);', quote_qualified(@table), quote_ident($name)),
    );
  }

  my @columns = @{ $info->{columns} // [] };
  push @reasons, 'its key has an expression or no column the model names, and a constraint names columns'
    if !@columns || grep { !defined } @columns;
  push @reasons, 'its index has a sort order (' . join(', ', map { "$_ " . $info->{sort_options}{$_} } sort keys %{ $info->{sort_options} })
    . '), which a constraint cannot have'
    if %{ $info->{sort_options} // {} };
  push @reasons, 'its index has an operator class (' . join(', ', map { "$_ " . $info->{opclasses}{$_} } sort keys %{ $info->{opclasses} })
    . '), which a constraint cannot name'
    if %{ $info->{opclasses} // {} };
  push @reasons, sprintf('its index is a %s index, and a constraint is a btree index', $info->{access_method})
    if defined $info->{access_method} && $info->{access_method} ne 'btree';
  @reasons = (
    ( map { "$_," } @reasons ),
    'so the diff cannot write it as a constraint. Declare it as an index of its own, or write the DDL yourself.',
  ) if @reasons;

  if (my $other = _other_primary($src_indexes, $tgt)) {
    push @reasons,
      sprintf('the table has the PRIMARY KEY constraint %s in the database, and PostgreSQL takes one per table (multiple primary keys); the diff creates before it drops:', $other->{index_name}),
      sprintf('  ALTER TABLE %s DROP CONSTRAINT %s;', quote_qualified(@table), quote_ident($other->{index_name}));
  }

  return @reasons;
}

# Why the index $src cannot become the constraint of $tgt by ALTER TABLE ...
# ADD CONSTRAINT ... USING INDEX: the lines that say it. Measured on
# PostgreSQL 18.6, the server refuses it for an index that is not unique or not
# btree, that has a predicate, an expression, a sort order other than the
# default or is not valid, for a partitioned table, and a second primary key;
# it renames the index to the name of the constraint. INCLUDE columns and
# NULLS NOT DISTINCT are kept. Nothing when it can. An index that is renamed
# first ($renamed) has the name of the constraint by the time it is used.
sub _using_index_reasons {
  my ($src, $tgt, $src_tables, $src_indexes, $renamed) = @_;
  my $info = $src->{index_info};
  my ($name, $type) = _constraint($tgt->{index_info}, $tgt->{index_name});
  my @reasons;

  push @reasons, 'the index is not unique' unless $info->{is_unique} || $info->{is_primary};
  push @reasons, sprintf('the index is a %s index, not btree', $info->{access_method})
    if defined $info->{access_method} && $info->{access_method} ne 'btree';
  push @reasons, 'the index has a predicate (it is a partial index)' if length($info->{predicate} // '');
  push @reasons, 'the index has an expression'
    if length($info->{expressions} // '') || grep { !defined } @{ $info->{columns} // [] };
  push @reasons, 'the index has a sort order other than ascending with the nulls last (' . join(', ', map { "$_ " . $info->{sort_options}{$_} } sort keys %{ $info->{sort_options} }) . ')'
    if %{ $info->{sort_options} // {} };
  push @reasons, 'the index is not valid (a CREATE INDEX CONCURRENTLY that failed)'
    if defined $info->{is_valid} && !$info->{is_valid};
  push @reasons, 'the table is partitioned, and ADD CONSTRAINT ... USING INDEX is not supported on a partitioned table'
    if (($src_tables->{ $src->{table_key} } // {})->{kind} // '') eq 'p';
  push @reasons, sprintf('the constraint is named %s and the index %s: USING INDEX would rename the index to the name of the constraint', $name, $src->{index_name})
    if $name ne $src->{index_name} && !$renamed;

  my @primary;
  if (my $other = _other_primary($src_indexes, $tgt)) {
    @primary = (
      sprintf('the table has the PRIMARY KEY constraint %s in the database, and PostgreSQL takes one per table (multiple primary keys):', $other->{index_name}),
      sprintf('  ALTER TABLE %s DROP CONSTRAINT %s;', quote_qualified(grep { defined } @{$tgt}{qw( schema_name table_name )}), quote_ident($other->{index_name})),
    );
  }

  return (
    ( @reasons ? (map({ "$_," } @reasons), 'so the diff does not put the constraint on this index. The index goes and the constraint comes, by hand:', _by_hand($src, $tgt)) : () ),
    @primary,
  );
}

# The refusal for every index that stands behind a constraint and cannot go,
# or be created, the way the diff takes it; returns when there is none. @found
# are [ $entry, @reasons ], the entry being the one whose constraint the lines
# are about.
sub _refuse_constraint {
  my (@found) = @_;
  return unless @found;
  my $first = 1;
  die join "\n",
    ( map {
        my ($entry, @reasons) = @$_;
        my ($name, $type) = _constraint($entry->{index_info}, $entry->{index_name});
        my $head = sprintf 'index %s on %s is the index of the %s constraint %s',
          $entry->{index_name}, $entry->{table_key}, $CONSTRAINT_KIND{$type}, $name;
        ( ($first-- > 0 ? "refusing to diff: $head" : $head), map { "  $_" } @reasons )
      } @found ),
    '',
    'The diff takes a constraint away with ALTER TABLE ... DROP CONSTRAINT and brings it',
    'with ALTER TABLE ... ADD CONSTRAINT [... USING INDEX]; it does not do what is named',
    'above. No statement',
    'was generated.',
    '',
    'Run the statements named above yourself and diff again.',
    '';
}

# The foreign keys the target creates (or redefines) that the server would
# bind to the index $src: a key to the table of the index, on exactly its key
# columns, where the index is a plain unique one. The server takes the first
# unique index over the columns it finds -- the older one, not the one the
# target adds -- and this index is dropped at the end of the run. Returns the
# lines that say it, with the statement that settles it; nothing when there is
# no such key.
sub _new_keys_bind {
  my ($src, $source_fks, $target_fks) = @_;
  my $info = $src->{index_info};
  return unless $target_fks;
  return unless $info->{is_unique} || $info->{is_primary};
  return if length($info->{predicate} // '') || length($info->{expressions} // '');
  my @columns = @{ $info->{columns} // [] };
  return if !@columns || grep { !defined } @columns;
  my $list  = sub { join "\0", map { $_ // '' } @_ };
  my $shape = sub {
    my ($key) = @_;
    return $list->(@{$key}{qw( remote_schema remote_table )}, @{ $key->{remote_columns} // [] }, '/', @{ $key->{local_columns} // [] });
  };
  my @found;
  for my $table_key (sort keys %$target_fks) {
    for my $key (@{ $target_fks->{$table_key} }) {
      next unless ($key->{remote_table} // '') eq ($src->{table_name} // '')
        && ($key->{remote_schema} // '') eq ($src->{schema_name} // '');
      next unless $list->(@{ $key->{remote_columns} // [] }) eq $list->(@columns);
      my ($old) = grep { ($_->{constraint_name} // '') eq $key->{constraint_name} }
        @{ ($source_fks // {})->{$table_key} // [] };
      next if $old && $shape->($old) eq $shape->($key);
      push @found, [ $table_key, $key ];
    }
  }
  return unless @found;
  my ($constraint) = _constraint($info, $src->{index_name});
  return (
    'the foreign key the target creates on its columns would be bound by the server to this index, which the same run drops:',
    ( map { sprintf '  %s on %s', $_->[1]{constraint_name}, $_->[0] } @found ),
    'Drop the index first (the key is then created against the constraint of the target), and diff again:',
    '  ' . (defined $constraint
      ? 'ALTER TABLE ' . quote_qualified(grep { defined } @{$src}{qw( schema_name table_name )}) . ' DROP CONSTRAINT ' . quote_ident($constraint)
      : 'DROP INDEX ' . quote_qualified(grep { defined } @{$src}{qw( schema_name index_name )})) . ';',
  );
}

# The refusal for every index the run drops that a foreign key stands on, or
# would be bound to; returns when there is none. @found are [ $entry,
# @reasons ].
sub _refuse_bound {
  my (@found) = @_;
  return unless @found;
  my $first = 1;
  die join "\n",
    ( map {
        my ($entry, @reasons) = @$_;
        my $head = sprintf 'index %s on %s is dropped by this run', $entry->{index_name}, $entry->{table_key};
        ( ($first-- > 0 ? "refusing to diff: $head" : $head), map { "  $_" } @reasons )
      } @found ),
    '',
    'The server refuses to drop an index a foreign key stands on. No statement',
    'was generated.',
    '',
    'Run the statements named above yourself and diff again.',
    '';
}

# --- the index of a partitioned table (karr k146) ---

my $IDENT = qr/"(?:[^"]|"")*"|[^\s".]+/;

# The text of the index of a partitioned table at one of its partitions: the
# name and the table replaced, ON ONLY kept where the partition is partitioned
# itself. Nothing when the text is not the form pg_get_indexdef writes.
sub _partition_definition {
  my ($definition, $name, $schema, $table, $only) = @_;
  $definition =~ s/\A(\s*CREATE\s+(?:UNIQUE\s+)?INDEX\s+)(?:$IDENT)(\s+ON\s+)ONLY\s+$IDENT(?:\.$IDENT)?(\s+USING\s)/
    $1 . quote_ident($name) . $2 . ($only ? 'ONLY ' : '') . quote_qualified(grep { defined } $schema, $table) . $3/ex
    or return;
  return $definition;
}

# The name the server gives an index it names itself (ChooseIndexName): the
# table, the columns of the key joined by _ ("expr" for an expression), the
# label (idx, idx1, ...); at most 63 bytes, the longer of table and columns
# losing a character at a time (makeObjectName).
sub _partition_index_name {
  my ($table, $columns, $label) = @_;
  my $cols = join '_', map { defined $_ && length $_ ? $_ : 'expr' } @$columns;
  $cols = 'expr' unless length $cols;
  my ($t, $c) = ($table, $cols);
  while (bytes::length($t) + bytes::length($c) + bytes::length($label) + 2 > 63) {
    if (length $t > length $c) { chop $t } else { chop $c }
  }
  return join '_', $t, $c, $label;
}

# The tree of indexes to put at the partitions of the table $table_key, for the
# index whose text is $definition. $taken is { schema => { name => 1 } } and
# grows with the names given. Nothing when the text cannot be rewritten.
sub _partition_tree {
  my ($source_tables, $target_tables, $table_key, $info, $definition, $taken) = @_;
  my @tree;
  for my $key (sort keys %$source_tables) {
    my $t = $source_tables->{$key};
    next unless defined $t->{partition_of} && $t->{partition_of} eq $table_key && exists $target_tables->{$key};
    my $schema = $t->{schema_name};
    my $name   = _partition_index_name($t->{table_name}, $info->{columns} // [], 'idx');
    for (my $n = 1; $taken->{ $schema // '' }{$name}; $n++) {
      $name = _partition_index_name($t->{table_name}, $info->{columns} // [], "idx$n");
    }
    $taken->{ $schema // '' }{$name} = 1;
    my $partitioned = ($t->{kind} // '') eq 'p';
    my $text = _partition_definition($definition, $name, $schema, $t->{table_name}, $partitioned) // return;
    my $below = [];
    if ($partitioned) {
      $below = _partition_tree($source_tables, $target_tables, $key, $info, $definition, $taken) // return;
    }
    push @tree, {
      schema_name => $schema,
      table_name  => $t->{table_name},
      index_name  => $name,
      definition  => $text,
      partitions  => $below,
    };
  }
  return \@tree;
}

# The statements for $tree below the index $parent (a list: schema, name).
sub _partition_sql {
  my ($parent, $tree) = @_;
  return map {
    my $child = $_;
    (
      "$child->{definition};",
      _partition_sql([ $child->{schema_name}, $child->{index_name} ], $child->{partitions} // []),
      sprintf('ALTER INDEX %s ATTACH PARTITION %s;',
        quote_qualified(grep { defined } @$parent),
        quote_qualified(grep { defined } @{$child}{qw( schema_name index_name )})),
    )
  } @$tree;
}

sub _refuse_without_definition {
  my ($tgt, $in_database) = @_;
  DBIO::PostgreSQL::Diff::NoStatement->refuse_without_definition(
    kind           => 'index',
    name           => _name($tgt),
    in_database    => $in_database,
    from           => 'pg_get_indexdef',
    null_when_gone => 1,
    also           => "The columns of the index, which the model may still hold, are not the index:\n"
      . "whether it is unique, its predicate, its access method, the order and the\n"
      . 'operator class of each column are in the definition.',
  );
}

sub diff {
  my ($class, $source, $target, $source_tables, $target_tables, $source_fks, $target_fks) = @_;
  my @ops;

  # Tables present in the source model but absent from the target are being
  # dropped in this same pass. Their indexes go with the table via
  # DROP TABLE, so a standalone DROP INDEX for one of them
  # must be suppressed (karr k32).
  $source_tables //= {};
  $target_tables //= {};
  my %dropped_table = map { $_ => 1 }
    grep { !exists $target_tables->{$_} } keys %$source_tables;

  my $src_indexes = _by_schema($source, $source_tables);
  my $tgt_indexes = _by_schema($target, $target_tables);

  _refuse_case_only($src_indexes, $tgt_indexes);

  my @constrained;

  # Indexes this run drops that a foreign key stands on or would be bound to.
  my @bound;

  # What decides whether a foreign key that points at a constraint to drop is
  # gone before it (the foreign_keys sections are optional, undef when absent).
  my $fk = [ $source_fks, $target_fks, $target_tables ];

  # Indexes of the source that are renamed and given a constraint, by schema
  # and name, so that they are not dropped as well.
  my %renamed;

  # The index of the source the constraint of $tgt is put on: on the same
  # table, with the same definition but for the name, no constraint on it, not
  # an index the target keeps. Each one serves one constraint.
  my $renamable = sub {
    my ($tgt) = @_;
    my $want = _definition_without_name($tgt->{index_info}{definition});
    for my $src (_in_order($src_indexes)) {
      next if $src->{table_key} ne $tgt->{table_key};
      next if $renamed{ $src->{schema_name} // '' }{ $src->{index_name} };
      next if $tgt_indexes->{ $src->{schema_name} // '' }{ $src->{index_name} };
      next if _constraint($src->{index_info}, $src->{index_name});
      next if _definition_without_name($src->{index_info}{definition}) ne $want;
      return $src;
    }
    return;
  };

  # The constraint of the source that is the constraint of $tgt under another
  # name: on the same table, of the same kind, with the same definition but for
  # the name, a name the target does not keep. It is renamed, ALTER TABLE ...
  # RENAME CONSTRAINT, which renames its index with it: dropping it and adding
  # the other would fail where a key stands on it.
  my $renamable_constraint = sub {
    my ($tgt) = @_;
    my (undef, $type) = _constraint($tgt->{index_info}, $tgt->{index_name});
    return unless defined $type && $type ne 'x';
    my $want = _definition_without_name($tgt->{index_info}{definition});
    for my $src (_in_order($src_indexes)) {
      next if $src->{table_key} ne $tgt->{table_key};
      next if $renamed{ $src->{schema_name} // '' }{ $src->{index_name} };
      next if $tgt_indexes->{ $src->{schema_name} // '' }{ $src->{index_name} };
      my (undef, $stype) = _constraint($src->{index_info}, $src->{index_name});
      next unless defined $stype && $stype eq $type;
      next if _definition_without_name($src->{index_info}{definition}) ne $want;
      # A rename keeps the timing of the constraint (karr k147); one that
      # changes it is a drop and a create, see $retimed.
      next if _timing($src->{index_info}, $stype) ne _timing($tgt->{index_info}, $type);
      return $src;
    }
    return;
  };

  # The constraint of the source that is the constraint of $tgt under another
  # name but for its timing (deferrable, initially_deferred): the renamed
  # constraint would keep the old one, so it is dropped and the target's
  # created (karr k147).
  my $retimed = sub {
    my ($tgt) = @_;
    my (undef, $type) = _constraint($tgt->{index_info}, $tgt->{index_name});
    return unless defined $type && $type eq 'u';
    my $want = _definition_without_name($tgt->{index_info}{definition});
    for my $src (_in_order($src_indexes)) {
      next if $src->{table_key} ne $tgt->{table_key};
      next if $renamed{ $src->{schema_name} // '' }{ $src->{index_name} };
      next if $tgt_indexes->{ $src->{schema_name} // '' }{ $src->{index_name} };
      my (undef, $stype) = _constraint($src->{index_info}, $src->{index_name});
      next unless defined $stype && $stype eq $type;
      next if _definition_without_name($src->{index_info}{definition}) ne $want;
      return $src;
    }
    return;
  };

  # The operations that put the constraint of $tgt on an index of the source
  # that has another name: the constraint renamed, or the index renamed and
  # the constraint put on it. Nothing when there is none.
  my $take_over = sub {
    my ($tgt) = @_;
    my (undef, $type) = _constraint($tgt->{index_info}, $tgt->{index_name});
    return unless defined $type && $type ne 'x';
    if (my $old = $renamable_constraint->($tgt)) {
      $renamed{ $old->{schema_name} // '' }{ $old->{index_name} } = 1;
      return $class->new(action => 'rename', %$tgt, renamed_from => $old->{index_name}, via => 'constraint');
    }
    if (my $old = $renamable->($tgt)) {
      # A second index would leave the foreign keys on this one (karr k139).
      my @reasons = _using_index_reasons($old, $tgt, $source_tables, $src_indexes, 1);
      push @constrained, [ $tgt, @reasons ] if @reasons;
      $renamed{ $old->{schema_name} // '' }{ $old->{index_name} } = 1;
      return (
        $class->new(action => 'rename', %$tgt, renamed_from => $old->{index_name}),
        $class->new(action => 'create', %$tgt, via => 'using_index'),
      );
    }
    return;
  };

  # Names the schemas hold: the indexes of the source, and what the server
  # names the copies of an index of a partitioned table at each partition
  # (the copies are not in the model).
  my %taken;
  for my $entry (map { values %$_ } values %$src_indexes) {
    $taken{ $entry->{schema_name} // '' }{ $entry->{index_name} } = 1;
    next unless (($source_tables->{ $entry->{table_key} } // {})->{kind} // '') eq 'p';
    for my $key (grep { ($source_tables->{$_}{partition_of} // '') eq $entry->{table_key} } keys %$source_tables) {
      my $part = $source_tables->{$key};
      $taken{ $part->{schema_name} // '' }{ _partition_index_name($part->{table_name}, $entry->{index_info}{columns} // [], 'idx') } = 1;
    }
  }

  # The indexes to put at the partitions when $tgt is the index of a
  # partitioned table (karr k146): (partitions => \@tree), or nothing.
  my $partitions = sub {
    my ($tgt) = @_;
    return unless (($target_tables->{ $tgt->{table_key} } // {})->{kind} // '') eq 'p';
    my $def = $tgt->{index_info}{definition} // '';
    return unless $def =~ /\A\s*CREATE\s+(?:UNIQUE\s+)?INDEX\s+$IDENT\s+ON\s+ONLY\s/i;
    my $tree = _partition_tree($source_tables, $target_tables, $tgt->{table_key}, $tgt->{index_info}, $def, \%taken)
      or return;
    return @$tree ? (partitions => $tree) : ();
  };

  # An index to create, as the constraint it is the index of when the target
  # says so, with the reasons it cannot be written that way collected.
  my $create = sub {
    my ($tgt) = @_;
    my (undef, $type) = _constraint($tgt->{index_info}, $tgt->{index_name});
    return $class->new(action => 'create', %$tgt, $partitions->($tgt)) unless defined $type;
    my @reasons = _create_reasons($tgt, $src_indexes);
    push @constrained, [ $tgt, @reasons ] if @reasons;
    return $class->new(action => 'create', %$tgt, via => 'constraint');
  };

  # New indexes
  for my $tgt (_in_order($tgt_indexes)) {
    my $src = $src_indexes->{ $tgt->{schema_name} // '' }{ $tgt->{index_name} };
    my $tgt_def = $tgt->{index_info}{definition} // '';
    if (!$src) {
      _refuse_without_definition($tgt, 0) unless $tgt_def =~ /\S/;
      # The constraint is there under another name, or its index is: the
      # constraint takes it (karr k139).
      if (my @take = $take_over->($tgt)) {
        push @ops, @take;
        next;
      }
      # The same constraint under another name and another timing: dropped
      # and created, not renamed (karr k147).
      if (my $old = $retimed->($tgt)) {
        $renamed{ $old->{schema_name} // '' }{ $old->{index_name} } = 1;
        my @reasons = _drop_reasons($old, 1, $fk);
        push @constrained, [ $old, @reasons ] if @reasons;
        push @ops, $class->new(action => 'drop', %$old, replaced => 1), $create->($tgt);
        next;
      }
      push @ops, $create->($tgt);
      next;
    }
    # Changed indexes: compare definitions, and what the definition does not
    # say (the constraint behind the index first of all)
    my $src_def = $src->{index_info}{definition} // '';
    if ($src_def ne $tgt_def || _attributes_differ($src, $tgt)) {
      _refuse_without_definition($tgt, 1) unless $tgt_def =~ /\S/;
      my (undef, $stype) = _constraint($src->{index_info}, $src->{index_name});
      my (undef, $ttype) = _constraint($tgt->{index_info}, $tgt->{index_name});

      # The index is there, the constraint is not: the constraint takes the
      # index it needs, ALTER TABLE ... ADD CONSTRAINT ... USING INDEX. Written
      # without USING INDEX the server answers "relation already exists".
      if (!defined $stype && defined $ttype && $ttype ne 'x' && $src_def eq $tgt_def) {
        my @reasons = _using_index_reasons($src, $tgt, $source_tables, $src_indexes);
        push @constrained, [ $tgt, @reasons ] if @reasons;
        push @ops, $class->new(action => 'create', %$tgt, via => 'using_index');
        next;
      }

      # Another index of the source is this constraint under another name, and
      # the one that has the name is in its way (a nonunique index, or a
      # constraint other than the target's): it goes first, then the other
      # takes the name.
      my @take = $src_def ne $tgt_def ? $take_over->($tgt) : ();
      if (defined $stype) {
        my @reasons = _drop_reasons($src, 1, $fk);
        push @constrained, [ $src, @reasons ] if @reasons;
      }
      push @ops, $class->new(action => 'drop', %$src, replaced => 1);
      push @ops, @take ? @take : $create->($tgt);
    }
  }

  # Dropped indexes
  for my $src (_in_order($src_indexes)) {
    next if $tgt_indexes->{ $src->{schema_name} // '' }{ $src->{index_name} };
    next if $renamed{ $src->{schema_name} // '' }{ $src->{index_name} };
    # Skip when the owning table is itself being dropped this pass; the
    # DROP TABLE already removes this index (karr k32).
    next if $dropped_table{ $src->{table_key} };
    if (my @constraint = _constraint($src->{index_info}, $src->{index_name})) {
      my @reasons = _drop_reasons($src, 0, $fk);
      push @constrained, [ $src, @reasons ] if @reasons;
    }
    else {
      # an index without a constraint that a foreign key stands on
      my @reasons = _drop_reasons($src, 0, $fk);
      push @bound, [ $src, @reasons ] if @reasons;
    }
    my @binds = _new_keys_bind($src, $source_fks, $target_fks);
    push @bound, [ $src, @binds ] if @binds;
    push @ops, $class->new(action => 'drop', %$src);
  }

  _refuse_constraint(@constrained);
  _refuse_bound(@bound);

  return @ops;
}


sub as_sql {
  my ($self) = @_;
  my @table =
    DBIO::PostgreSQL::Introspect->key_names($self->table_key, table_name => $self);
  # A key without a schema -- a model built by hand -- leaves the name alone.
  my @schema = @table > 1 ? $table[0] : ();

  my $action = $self->action // '';
  my $info   = $self->index_info // {};

  if ($action eq 'rename') {
    DBIO::PostgreSQL::Diff::NoStatement->throw($self, 'index ' . _name($self), 'it has no name to rename from')
      unless defined $self->renamed_from && length $self->renamed_from;
    return sprintf 'ALTER TABLE %s RENAME CONSTRAINT %s TO %s;',
      quote_qualified(@table), quote_ident($self->renamed_from), quote_ident($self->index_name)
      if defined $self->via && $self->via eq 'constraint';
    return sprintf 'ALTER INDEX %s RENAME TO %s;',
      quote_qualified(@schema, $self->renamed_from), quote_ident($self->index_name);
  }
  elsif ($action eq 'create' && defined $self->via) {
    # A key of the table: the constraint, not the index behind it
    my ($name, $type) = _constraint($info, $self->index_name);
    my $object = 'constraint ' . _name($self);
    DBIO::PostgreSQL::Diff::NoStatement->throw($self, $object, 'the class knows no such way to create it')
      unless $self->via eq 'constraint' || $self->via eq 'using_index';
    DBIO::PostgreSQL::Diff::NoStatement->throw($self, $object,
      'its index_info says no PRIMARY KEY or UNIQUE constraint stands behind it')
      unless defined $type && ($type eq 'p' || $type eq 'u');

    return sprintf 'ALTER TABLE %s ADD CONSTRAINT %s %s USING INDEX %s%s;',
      quote_qualified(@table), quote_ident($name), $CONSTRAINT_KIND{$type}, quote_ident($self->index_name),
      _timing($info, $type)
      if $self->via eq 'using_index';

    my @columns = @{ $info->{columns} // [] };
    DBIO::PostgreSQL::Diff::NoStatement->throw($self, $object,
      'its index_info has no columns to name, or one without a name, as an expression has none')
      if !@columns || grep { !defined || !length } @columns;
    return sprintf 'ALTER TABLE %s %s;', quote_qualified(@table), _add_constraint_sql($info, $name, $type);
  }
  elsif ($action eq 'create') {
    # Use the full definition from introspection if available
    my $def = $info->{definition};
    return join "\n", "$def;", _partition_sql([ grep { defined } $self->schema_name, $self->index_name ], $self->partitions // [])
      if defined $def && $def =~ /\S/;

    # The columns are not the index: unique, predicate, access method, order
    # and operator class stand only in the definition.
    DBIO::PostgreSQL::Diff::NoStatement->throw(
      $self, 'index ' . _name($self),
      'its index_info has no definition, and columns do not stand in for it: that the index is unique, its predicate, access method, order and operator class are in the definition only',
    );
  }
  elsif ($action eq 'drop') {
    # An index behind a constraint is dropped with the constraint: the server
    # refuses DROP INDEX for it.
    my ($constraint) = _constraint($info, $self->index_name);
    return sprintf 'ALTER TABLE %s DROP CONSTRAINT %s;', quote_qualified(@table), quote_ident($constraint)
      if defined $constraint;
    return sprintf 'DROP INDEX %s;', quote_qualified(@schema, $self->index_name);
  }
  DBIO::PostgreSQL::Diff::NoStatement->throw($self, 'index ' . _name($self));
}


sub summary {
  my ($self) = @_;
  return sprintf '  ~%s: %s -> %s (on %s)', (defined $self->via ? 'constraint' : 'index'),
    $self->renamed_from // '', $self->index_name, $self->table_key
    if ($self->action // '') eq 'rename';
  my $prefix = $self->action eq 'create' ? '+' : '-';
  my $kind   = ($self->action eq 'create' ? defined $self->via : _constraint($self->index_info // {}, $self->index_name))
    ? 'constraint' : 'index';
  return sprintf '  %s%s: %s (on %s)', $prefix, $kind, $self->index_name, $self->table_key;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Diff::Index - Diff operations for PostgreSQL indexes

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents an index-level diff operation: C<CREATE INDEX> or C<DROP INDEX>,
and for an index that stands behind a PRIMARY KEY or UNIQUE constraint the
constraint: C<ALTER TABLE ... ADD CONSTRAINT> and C<DROP CONSTRAINT> -- the
server refuses C<DROP INDEX> for such an index. When an index definition
changes, it generates a C<DROP> followed by a C<CREATE>. The full definition
string from C<pg_get_indexdef> is used for comparison, so partial indexes,
expression indexes, and storage parameters are all detected correctly; the
constraint behind the index, which the string does not say, is compared beside
it.

=head1 ATTRIBUTES

=head2 table_key

The C<schema.table> key for the table this index belongs to. It is where the
model files the table, and what L</summary> prints; it is not SQL.

=head2 schema_name

The schema of that table -- and of the index: an index lives in the schema of
its table.

=head2 table_name

The name of that table. L</as_sql> writes names from C<schema_name>,
C<table_name> and C<index_name>, each quoted for itself -- the key cannot be
taken apart again, a schema or a table may have a dot in its name. L</diff>
takes both from the index entry, or from the C<tables> sections. An operation
built by hand without them falls back to the key
(L<DBIO::PostgreSQL::Introspect/key_names>).

=head2 index_name

The index name.

=head2 index_info

Index metadata hashref (C<definition>, C<access_method>, C<columns>, etc.).

=head2 replaced

True on the C<drop> of a changed index: the index is not removed, the
C<create> that follows puts it back with its new definition. It tells
L<DBIO::PostgreSQL::Diff> to leave the two together instead of moving the
drop to the removals (L<DBIO::PostgreSQL::Diff/ORDER OF OPERATIONS>).

=head2 via

What a C<create> writes: undefined for the index from its definition, C<constraint> for C<ALTER TABLE ... ADD CONSTRAINT
PRIMARY KEY|UNIQUE (columns)>, C<using_index> for C<ALTER TABLE ... ADD CONSTRAINT
PRIMARY KEY|UNIQUE USING INDEX name>, which puts the constraint on the index
that is there. L</diff> sets it; an operation built by hand without it writes
the index.

=head2 renamed_from

On a C<rename>: the name the index has in the database. C<index_name> is the
name it gets, the one of the constraint that is put on it. With L</via>
C<constraint> on a C<rename> it is the name of the constraint (and of its
index) that is renamed: C<ALTER TABLE ... RENAME CONSTRAINT>.

=head2 partitions

On a C<create> of an index of a partitioned table: the indexes to put at its
partitions, a list of hashes C<schema_name>, C<table_name>, C<index_name>,
C<definition> (the text of the index at that partition) and C<partitions> (the
same, for a partition that is itself partitioned; its definition is C<ON
ONLY>). L</as_sql> writes them behind the index.

=head1 METHODS

=head2 diff

    my @ops = DBIO::PostgreSQL::Diff::Index->diff(
      $source, $target, $source_tables, $target_tables,
      $source_foreign_keys, $target_foreign_keys);

Compares index sets across all tables. An index is identified by its schema
and its name -- PostgreSQL keeps index names unique per schema, not per
database, so two schemas may each have an C<orders_created_idx> (every tenant
schema of a multi-tenant layout does) and the two are different indexes.
Within a schema the name alone identifies it, whichever table it is on. A
changed definition produces a drop-then-create pair.

The optional C<$source_tables> / C<$target_tables> hashrefs are the C<tables>
sections of the two models (threaded in by L<DBIO::PostgreSQL::Diff> via its
aux-section wiring). They are used to detect tables that are being dropped in
this same diff pass: C<DROP TABLE> removes that table's own
indexes, so no standalone C<DROP INDEX> is emitted for them. The
same holds for a materialized view, which is filed among the tables: C<DROP
MATERIALIZED VIEW> takes its indexes. Left
in, such a drop comes ahead of the table's (L<DBIO::PostgreSQL::Diff/ORDER OF
OPERATIONS>) and fails for every index that carries a constraint -- the
primary key's first of all -- with C<cannot drop index ... because constraint
... requires it>. When these
arguments are absent (e.g. direct unit-test calls) the set is empty and no
drops are suppressed, preserving the original two-argument behaviour.

B<The index of a constraint.> The model says which index a constraint stands
behind: C<constraint_name> and C<constraint_type> (C<p>, C<u> or C<x>) of its
entry (L<DBIO::PostgreSQL::Introspect::Indexes/fetch>). The diff takes that
index away as C<ALTER TABLE schema.table DROP CONSTRAINT name;>, and the
summary says C<-constraint:>. A unique index no constraint stands on stays a
C<DROP INDEX>. A changed index of a constraint goes the same way when the
target has the name as an index: the constraint is dropped and the index of
the target created.

B<The constraint of a key is created as a constraint>.
C<pg_get_indexdef> writes the same text for the index of a PRIMARY KEY or
UNIQUE constraint and for a unique index no constraint stands on, so a
constraint created from that text would be an index, and the comparison by
definition would never find it missing. Where the target says a constraint
stands behind the index, the diff writes the constraint:

    ALTER TABLE schema.t ADD CONSTRAINT name PRIMARY KEY (a, b);
    ALTER TABLE schema.t ADD CONSTRAINT name UNIQUE [NULLS NOT DISTINCT] (a)
      [INCLUDE (...)] [WITH (...)];

(C<via> C<constraint>, the summary says C<+constraint:>). The columns are
written in the order of the key. Besides the definition, the comparison looks
at the kind of constraint behind the index, the key columns in their order,
the INCLUDE columns and the storage parameters (ADR 0003, addendum
2026-10-20). A UNIQUE constraint also carries its timing: the model keys
C<deferrable> and C<initially_deferred> of the entry
(C<pg_constraint.condeferrable>, C<condeferred>) are compared, and the
constraint is written C<DEFERRABLE INITIALLY IMMEDIATE> or C<DEFERRABLE
INITIALLY DEFERRED> behind the column list, INCLUDE and WITH, also in the
C<USING INDEX> form. A primary key's timing is not read. A class declares it
with L<DBIO::PostgreSQL::Result/pg_unique_options>. A plain C<RENAME
CONSTRAINT> keeps the timing; a constraint of the database that has the
target's definition under another name but another timing is not renamed, it
is dropped (C<replaced>) and the target's created. A constraint that differs
from the database's under its name is dropped and added again, as one change
(the C<drop> is C<replaced>); the target's plain index of a database's
constraint is the way back, and stays an index, never a second primary key.

B<The database that has the key only as an index> -- what an upgrade made
before this -- is repaired in place. The source has the same index, the target
a constraint on it:

    ALTER TABLE schema.t ADD CONSTRAINT name PRIMARY KEY USING INDEX name;

(C<via> C<using_index>), no second index, no rebuild, the index keeps its name
and its oid. The form without C<USING INDEX> fails with C<relation "name"
already exists>. Measured on PostgreSQL 18.6, the server takes this for an
index that is unique and btree, without predicate or expression, with the
default sort order and valid, on a table that is not partitioned and has no
primary key of another name; INCLUDE columns and NULLS NOT DISTINCT are kept;
a primary key over a nullable column sets it NOT NULL. The constraint takes
its name from the index: a constraint named otherwise would rename the index.

So these cases are B<refused>, with C<refusing to diff: ...>, no statement,
and the C<ALTER TABLE> that settles it:

=over 4

=item * the constraint to create is an EXCLUDE constraint, whose elements are
not in the model; the message names C<ADD CONSTRAINT n EXCLUDE (...)>. A key
with an expression, a sort order or an operator class cannot be a PRIMARY KEY
or UNIQUE constraint either.

=item * the table has a primary key of the database under another name than
the one of the target and with another definition. The diff creates before it
drops, and the server takes one primary key per table (C<multiple primary
keys>). The message names the C<DROP CONSTRAINT> to run first. The same name is
no case: it is dropped and added again; the same definition under another name
is renamed.

=item * the index of the database is one C<USING INDEX> does not take
(not unique, not btree, partial, an expression, a sort order, not valid, on a
partitioned table, named otherwise than the constraint). The message names
C<DROP INDEX> and the C<ADD CONSTRAINT> that put it right.

=item * foreign keys of other tables point at the constraint
(C<referenced_by>) and are still there when C<DROP CONSTRAINT> runs, so it
would fail. The message names C<ALTER TABLE other DROP CONSTRAINT fk> for
each. A key is not there any more when the target model declares foreign keys
(the optional fifth and sixth argument, the C<foreign_keys> sections) and the
key is not in it, or is a key to other columns: the diff drops it
(L<DBIO::PostgreSQL::Diff::ForeignKey>), the drops of the keys come ahead of
the drops of the indexes, and the constraint goes without a refusal. That
holds for a constraint that goes, not for one that is dropped and added again:
the first half of such a change stands ahead of the keys'
(L<DBIO::PostgreSQL::Diff/ORDER OF OPERATIONS>), so a key that points at it is
refused whatever the target does with the key. Without the sections -- a model
built by hand that says nothing of foreign keys -- every key that points at a
constraint to drop is refused. A key of a table the target drops, or one the
source model does not list (the copy at a partition), cannot be shown to be
gone before the constraint is, and is refused as well.

=item * an index to create and one to drop, on the same table, whose names
differ only in upper and lower case, when the one to drop stands behind a
constraint (L<DBIO::PostgreSQL::Diff::CaseOnly>). This is where the index of
a primary key ends up once its table has been renamed from C<useraccount> to
C<UserAccount>: it is still called C<useraccount_pkey>. The message names both
and the way out, C<ALTER INDEX public.useraccount_pkey RENAME TO
"UserAccount_pkey">, which renames the constraint with the index.

=back

B<The index under another name>. The database has a unique index
that no constraint stands on, the target a PRIMARY KEY or UNIQUE constraint on
the same table with the same definition but for the index's name -- a database
an older upgrade made, or one made by hand, where the index is called
C<parent_code_uidx> and the target's constraint C<parent_code_key>. A second
index would leave the foreign keys on the old one, and the old one could not be
dropped (C<cannot drop index ... because other objects depend on it>), so the
diff renames the one that is there and puts the constraint on it:

    ALTER INDEX schema.parent_code_uidx RENAME TO parent_code_key;
    ALTER TABLE schema.parent ADD CONSTRAINT parent_code_key UNIQUE USING INDEX parent_code_key;

(an operation of the action C<rename>, then the C<create> of L</via>
C<using_index>; the summary says C<~index: old -E<gt> new>). The reasons that
refuse C<USING INDEX> above hold here as well, but for the name. An index
serves one constraint, and an index the target keeps under its own name is not
taken. Any other index -- a unique one no constraint stands on included -- is
created under the one name and dropped under the other, as any index that is
renamed.

B<The name is taken, or the constraint has another name>.
If the target's name is held by another index of the database -- one that is
no key of the same shape, say a nonunique index C<parent_code_key> beside the
unique C<parent_code_uidx> -- that index is dropped first and the rename above
follows; the old index is not dropped after the key was put on it. If the
database has the constraint itself under another name, of the same kind and
definition (C<parent_code_uniq> against C<parent_code_key>, a primary key
C<parent_id_pk> against C<parent_pkey>), it is renamed with its index and keys:

    ALTER TABLE schema.parent RENAME CONSTRAINT parent_code_uniq TO parent_code_key;

(a C<rename> of L</via> C<constraint>; the summary says C<~constraint: old
-E<gt> new>), where C<ADD> and C<DROP> would fail on the foreign keys that
stand on it.

B<An index the run drops while a key stands on it> is refused ahead of the
apply: a foreign key of the database on an index that is not renamed or kept,
and a foreign key the target creates on the columns of such an index -- the
server binds a new key to the first (the oldest) unique index over its columns,
not to the one the target adds, and cannot drop that one at the end of the run.
The message names the index, the key and the statement that settles it (drop
the key, or the index, and diff again).

An index that is new, and a target index no constraint stands on, is created
as the index.

B<The index of a partitioned table>. C<pg_get_indexdef> writes it
C<CREATE INDEX name ON ONLY schema.p USING ...>, and an index made from that
text is invalid (C<indisvalid> false) until every partition has an index
attached to it. So the diff writes the text, and then, for each partition of
the table that both models have (C<partition_of> in the C<tables> section of
the source, where the statements run; a partition the target drops gets none),
the same index at the partition and C<ALTER INDEX ... ATTACH PARTITION>:

    CREATE INDEX p_tag ON ONLY public.p USING btree (tag);
    CREATE INDEX p1_tag_idx ON public.p1 USING btree (tag);
    ALTER INDEX public.p_tag ATTACH PARTITION public.p1_tag_idx;

A partition that is partitioned itself gets C<ON ONLY>, its own partitions
(deeper first) and then its attach. The name of a partition's index is the one
the server gives an index it names itself, C<partition_columns_idx> (an
expression is C<expr>), shortened to 63 bytes by the server's rule (the longer
of table and column part loses a character at a time); a name the schema
already holds in the source model, or that this run has given, gets a number
(C<_idx1>, C<_idx2>), as the server numbers. The copies the server made of an
index at partitions are not in the model, so a name one of them holds is
reserved from the names the copies of the indexes of the source would have
(the same rule), not from what the catalog holds; where the catalog differs
the server refuses the C<CREATE INDEX> for the existing name. The copies are
not compared (L<DBIO::PostgreSQL::Introspect::Indexes>), and a changed index is
dropped, which takes its copies, and created again. A PRIMARY KEY or UNIQUE
B<constraint> is created by C<ALTER TABLE ... ADD CONSTRAINT>, which the server
carries down to the partitions itself.

An index to create -- a new one or a changed one -- that the target model has
no C<definition> for is B<refused> as well
(L<DBIO::PostgreSQL::Diff::NoStatement>), whether or not the model has its
C<columns>. The definition is what the diff writes an index from and compares
it by. The columns are not the index: that it is unique, its predicate, its
access method, the order and the operator class of each column would be lost,
and a unique partial index would come back as a plain one. C<pg_get_indexdef>
gives no definition for an index another session dropped while the model was
read, and the model then still has its columns. An index only the source
lacks the definition of is dropped and created like any other whose
definition differs, and a C<drop> needs none.

=head2 as_sql

Returns the SQL for this operation. For C<create>, the full
C<pg_get_indexdef> definition string of its C<index_info> -- or, when L</via>
is set, the constraint: C<ALTER TABLE schema.table ADD CONSTRAINT name PRIMARY
KEY (a, b);> (C<constraint>) or C<... PRIMARY KEY USING INDEX name;>
(C<using_index>), written from the C<constraint_name>, C<constraint_type> and
the C<columns> of the C<index_info>; dies without them
(L<DBIO::PostgreSQL::Diff::NoStatement/throw>). For C<rename>, C<ALTER INDEX
schema.old RENAME TO new;>. For C<drop>,
returns C<DROP INDEX schema.name;> -- schema-qualified, because an unqualified
C<DROP INDEX> looks only along the search path and reports an index in any
other schema as not existing -- or, for the index of a constraint,
C<ALTER TABLE schema.table DROP CONSTRAINT name;>.

A definition from C<pg_get_indexdef> is the server's own text and is written
as given. Every name this method writes itself is an identifier by the
server's rule (L<DBIO::PostgreSQL::Util/quote_ident>).

A C<create> without a definition dies, whether or not its C<index_info> has
C<columns>: the columns are not the index (that it is unique, its predicate,
its access method, the order and the operator class of each column stand in the
definition only), and L</diff> builds no such operation either
(L<DBIO::PostgreSQL::Diff::NoStatement/throw>). So does an
C<action> this class does not know; no placeholder is written.

=head2 summary

Returns a one-line description such as C<+index: idx_users_tags (on auth.users)>.
A constraint -- created (L</via>) or dropped -- reads C<+constraint: users_pkey
(on public.users)>, C<-constraint: ...>; an index that is renamed
C<~index: old -E<gt> new (on public.users)>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
