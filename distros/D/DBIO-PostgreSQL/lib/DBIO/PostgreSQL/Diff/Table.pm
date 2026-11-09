package DBIO::PostgreSQL::Diff::Table;
# ABSTRACT: Diff operations for PostgreSQL tables

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::PostgreSQL::Diff::CaseOnly ();
use DBIO::PostgreSQL::Diff::Dependents ();
use DBIO::PostgreSQL::Diff::ForeignKey ();
use DBIO::PostgreSQL::Diff::NoStatement ();
use DBIO::PostgreSQL::Diff::View ();
use DBIO::PostgreSQL::Introspect ();
use DBIO::PostgreSQL::Util qw(quote_ident quote_qualified);

__PACKAGE__->mk_diff_accessors(qw(schema_name table_name table_info columns));







my %KIND_LABEL = (
  r => 'table',
  v => 'view',
  m => 'materialized view',
  f => 'foreign table',
  p => 'partitioned table',
);

# An entry without a kind -- a model built by hand -- is a table.
sub _kind {
  my ($info) = @_;
  return $info->{kind} // 'r';
}

sub _kind_label {
  my ($info) = @_;
  return $KIND_LABEL{ _kind($info) } // "relation of kind '" . _kind($info) . "'";
}

sub _refuse_kind_change {
  my ($key, $old, $new) = @_;
  die join "\n",
    sprintf(
      'refusing to diff: %s is a %s in the database and a %s in the target',
      $key, _kind_label($old), _kind_label($new),
    ),
    '',
    'To make the one into the other it has to be dropped and created anew, and what',
    'it holds -- the rows of a table, the data of a materialized view -- is dropped',
    'with it. No statement was generated.',
    '',
    'Drop or rename it yourself and diff again: the diff then creates what the',
    'target has under that name.',
    '';
}

# What the model does not hold of a relation it cannot create, by kind.
my %NOT_IN_MODEL = (
  f => 'its foreign server and its options',
  p => 'how it is partitioned',
);

sub _refuse_create {
  my ($key, $info, $missing, $columns) = @_;
  my $would_be = _create_table_sql($info, $columns);
  my $what = defined $info->{partition_of}
    ? "table $key is a partition of $info->{partition_of} in the target"
    : _kind_label($info) . " $key is in the target";
  die join "\n",
    "refusing to diff: $what and not in the database, and the diff cannot create it",
    '',
    "The model holds its columns but not $missing, so all the diff",
    'could write is',
    "  $would_be",
    'which makes an ordinary table of that name. No statement was generated.',
    '',
    'Create it yourself, with the statement that declares it, and diff again.',
    '';
}

# How a relation is given another name, for the kinds whose drop takes what
# they hold. A view holds nothing: it is dropped and created (Diff::View).
my %RENAME = (
  r => 'ALTER TABLE',
  p => 'ALTER TABLE',
  f => 'ALTER FOREIGN TABLE',
  m => 'ALTER MATERIALIZED VIEW',
);

# The relations of those kinds, as DBIO::PostgreSQL::Diff::CaseOnly compares
# them: a name within its schema, among the relations of its kind. A table
# and a materialized view are no pair -- no rename makes the one the other.
sub _renamable {
  my ($tables) = @_;
  my @entries;
  for my $key (keys %$tables) {
    my $info = $tables->{$key};
    next unless $RENAME{ _kind($info) };
    my ($schema, $name) = DBIO::PostgreSQL::Introspect->key_names($key, table_name => $info);
    next unless defined $name;
    push @entries, {
      in => [ $schema, _kind($info) ], name => $name, schema => $schema, info => $info,
    };
  }
  return \@entries;
}

sub _refuse_case_only {
  my ($source, $target) = @_;
  DBIO::PostgreSQL::Diff::CaseOnly->refuse(
    "The drop takes what it holds: the rows of a table, the data of a\n"
      . 'materialized view and the indexes on it.',
    map {
      my ($old, $new) = @$_;
      my $schema = $old->{schema};
      {
        kind     => _kind_label($old->{info}),
        database => "$schema.$old->{name}",
        target   => "$schema.$new->{name}",
        rename   => sprintf('%s %s RENAME TO %s;', $RENAME{ _kind($old->{info}) },
          quote_qualified($schema, $old->{name}), quote_ident($new->{name})),
      }
    } DBIO::PostgreSQL::Diff::CaseOnly->pairs(_renamable($source), _renamable($target)),
  );
}

# What a table is among the others: a partition, a table that inherits, or
# neither. The parents are named in sorted order -- their order is that of
# the columns and nothing a statement changes.
sub _belongs_to {
  my ($info) = @_;
  return "a partition of $info->{partition_of}" if defined $info->{partition_of};
  my @parents = sort @{ $info->{inherits} // [] };
  return 'a table that inherits from ' . join(', ', @parents) if @parents;
  return 'a table of its own';
}

# A model read from the catalog says of every table what it belongs to. One
# built by hand that has neither key says nothing, and is not asked.
sub _says_what_it_belongs_to {
  my ($info) = @_;
  return exists $info->{partition_of} || exists $info->{inherits};
}

sub _refuse_parent_change {
  my ($key, $old, $new) = @_;
  die join "\n",
    sprintf('refusing to diff: table %s is %s in the database and %s in the target',
      $key, _belongs_to($old), _belongs_to($new)),
    '',
    'The diff has no statement that makes the one into the other: a partition is',
    'attached with its bounds, which the model does not hold, and a table that is',
    'made to inherit needs the columns of the other first.',
    'No statement was generated.',
    '',
    'Do it yourself -- ALTER TABLE ... ATTACH PARTITION or DETACH PARTITION, ALTER',
    'TABLE ... INHERIT or NO INHERIT -- and diff again.',
    '';
}

sub _refuse_create_inheriting {
  my ($key, $info, $columns) = @_;
  my $parents = join ', ', @{ $info->{inherits} };
  die join "\n",
    "refusing to diff: table $key inherits from $parents in the target and is not in the database, and the diff cannot create it",
    '',
    'The diff has no statement for a table that inherits. All it could write is',
    '  ' . _create_table_sql($info, $columns),
    'which makes an ordinary table of that name, with the columns it has from',
    "$parents as its own. No statement was generated.",
    '',
    'Create it yourself, with the statement that declares it -- CREATE TABLE ...',
    'INHERITS (...) -- and diff again.',
    '';
}

# How a table is kept (pg_class.relpersistence), as a reader calls it.
my %PERSISTENCE = (
  p => 'logged',
  u => 'unlogged',
  t => 'temporary',
);

sub _persistence_label {
  my ($persistence) = @_;
  return $PERSISTENCE{$persistence} // "of the persistence '$persistence'";
}

# The persistences the diff writes, and the word ALTER TABLE has for each.
my %SET_PERSISTENCE = (
  p => 'LOGGED',
  u => 'UNLOGGED',
);

sub _refuse_persistence_create {
  my ($key, $info) = @_;
  die join "\n",
    sprintf('refusing to diff: %s %s is %s in the target',
      _kind_label($info), $key, _persistence_label($info->{persistence})),
    '',
    'The diff creates logged and unlogged tables. A temporary table belongs to the',
    'session that made it, and no model read from the catalog has one.',
    'No statement was generated.',
    '',
    'Take it out of the target model and diff again.',
    '';
}

sub _refuse_persistence_change {
  my ($key, $old, $new) = @_;
  die join "\n",
    sprintf('refusing to diff: %s %s is %s in the database and %s in the target',
      _kind_label($new), $key, map { _persistence_label($_->{persistence}) } $old, $new),
    '',
    'PostgreSQL has ALTER TABLE ... SET LOGGED and SET UNLOGGED for an ordinary',
    'table and for a partition, between those two, and for nothing else: a',
    'partitioned table and a materialized view are not unlogged.',
    'No statement was generated.',
    '',
    'Nothing the diff can write changes that. Where the server lets you, change',
    'it yourself and diff again.',
    '';
}

# The tables a change of persistence is written for, in the order the server
# takes: going to UNLOGGED the table that holds a foreign key goes ahead of
# the one it references, going to LOGGED the referenced one goes ahead. Each
# step takes the first table by name that has nothing left ahead of it, so
# without a key the order is that of the names. A key between tables that go
# the other ways, or to a table that does not change, asks for nothing.
sub _persistence_order {
  my ($source, $target, $foreign_keys) = @_;

  my %to;
  for my $key (keys %$target) {
    next unless exists $source->{$key};
    my ($old, $new) = ($source->{$key}, $target->{$key});
    next unless defined $old->{persistence} && defined $new->{persistence}
      && $old->{persistence} ne $new->{persistence};
    $to{$key} = $new->{persistence};
  }

  # %ahead: what has to be changed before the table, by key.
  my %ahead = map { $_ => {} } keys %to;
  for my $holder (keys %to) {
    for my $fk (@{ $foreign_keys->{$holder} // [] }) {
      my $referenced = DBIO::PostgreSQL::Introspect->qualified_key(
        $fk->{remote_schema}, $fk->{remote_table});
      next if $referenced eq $holder || !exists $to{$referenced};
      next if $to{$referenced} ne $to{$holder};
      if ($to{$holder} eq 'u') { $ahead{$referenced}{$holder} = 1 }
      else                     { $ahead{$holder}{$referenced} = 1 }
    }
  }

  my @order;
  my %left = %ahead;
  while (%left) {
    my ($next) = sort grep { !%{ $left{$_} } } keys %left;
    unless (defined $next) {
      my @cycle = sort keys %left;
      die join "\n",
        sprintf(
          'refusing to diff: %s reference each other and are to be %s',
          join(', ', @cycle), $SET_PERSISTENCE{ $to{ $cycle[0] } }),
        '',
        'PostgreSQL does not change a table to unlogged while it references a logged',
        'one, nor to logged while it references an unlogged one, so with keys in',
        'both directions no order of ALTER TABLE ... SET LOGGED / SET UNLOGGED is',
        'taken. No statement was generated.',
        '',
        'Drop one of the foreign keys, diff again, and add it back afterwards.',
        '';
    }
    push @order, $next;
    delete $left{$next};
    delete $_->{$next} for values %left;
  }
  return @order;
}

# The order tables are dropped in: one that inherits from another goes ahead of
# it, and so does one whose foreign key points at another, since the server
# does not drop a table while something stands on it. A key in a circle of
# dropped tables is dropped by the foreign key diff and sets no order.
# Otherwise by name.
sub _drop_order {
  my ($source, $keys_between, @keys) = @_;
  my %left = map { $_ => 1 } @keys;
  my %children;
  for my $key (@keys) {
    $children{$_}{$key} = 1 for grep { $left{$_} } @{ $source->{$key}{inherits} // [] };
  }
  $children{ $_->{referenced} }{ $_->{holder} } = 1 for grep { !$_->{cyclic} } @$keys_between;
  my @order;
  while (%left) {
    my ($next) = sort grep { !grep { $left{$_} } keys %{ $children{$_} // {} } } keys %left;
    ($next) = sort keys %left unless defined $next;
    push @order, $next;
    delete $left{$next};
  }
  return @order;
}

sub diff {
  my ($class, $source, $target, $source_cols, $target_cols, $source_fks, $target_fks, $source_dependents) = @_;
  my @ops;

  _refuse_case_only($source, $target);

  for my $key (sort keys %$target) {
    next unless exists $source->{$key};
    my ($old, $new) = ($source->{$key}, $target->{$key});
    _refuse_kind_change($key, $old, $new) if _kind($old) ne _kind($new);
    _refuse_parent_change($key, $old, $new)
      if _says_what_it_belongs_to($old) && _says_what_it_belongs_to($new)
        && _belongs_to($old) ne _belongs_to($new);
  }

  for my $key (sort keys %$target) {
    next if exists $source->{$key};
    my $t = $target->{$key};
    next if DBIO::PostgreSQL::Diff::View->is_view($t);

    my $missing = defined $t->{partition_of} ? 'the bounds of the partition'
                : $NOT_IN_MODEL{ _kind($t) };
    _refuse_create($key, $t, $missing, $target_cols->{$key}) if $missing;
    _refuse_create_inheriting($key, $t, $target_cols->{$key}) if @{ $t->{inherits} // [] };
    _refuse_persistence_create($key, $t)
      unless $SET_PERSISTENCE{ $t->{persistence} // 'p' };

    push @ops, $class->new(
      action      => 'create',
      schema_name => $t->{schema_name},
      table_name  => $t->{table_name},
      table_info  => $t,
      columns     => $target_cols->{$key} // [],
    );
  }

  # How a table both have is kept. A target that does not say -- a model
  # built by hand -- asks for nothing. The order is that of the foreign keys
  # the database has (_persistence_order).
  for my $key (_persistence_order($source, $target, $source_fks // {})) {
    my ($old, $new) = ($source->{$key}, $target->{$key});

    _refuse_persistence_change($key, $old, $new)
      unless _kind($new) eq 'r' && $SET_PERSISTENCE{ $new->{persistence} };

    push @ops, $class->new(
      action      => 'set_persistence',
      schema_name => $new->{schema_name},
      table_name  => $new->{table_name},
      table_info  => $new,
    );
  }

  my @dropped;
  for my $key (sort keys %$source) {
    next if exists $target->{$key};
    my $t = $source->{$key};
    next if DBIO::PostgreSQL::Diff::View->is_view($t);

    # A partition goes with the partitioned table it belongs to.
    my $parent = $t->{partition_of};
    next if defined $parent && exists $source->{$parent} && !exists $target->{$parent};

    push @dropped, $key;
  }

  # What stands on a table outside the model is named, not left to the server.
  DBIO::PostgreSQL::Diff::Dependents->refuse(map { {
    object     => _kind_label($source->{$_}) . " $_",
    dependents => ($source_dependents // {})->{tables}{$_},
  } } @dropped);

  my @between = DBIO::PostgreSQL::Diff::ForeignKey->dropped_together($source_fks, $source, $target);
  for my $key (_drop_order($source, \@between, @dropped)) {
    my $t = $source->{$key};
    push @ops, $class->new(
      action      => 'drop',
      schema_name => $t->{schema_name},
      table_name  => $t->{table_name},
      table_info  => $t,
    );
  }

  return @ops;
}


sub qualified_name {
  my ($self) = @_;
  return $self->schema_name . '.' . $self->table_name;
}


sub _identity_kind {
  return DBIO::PostgreSQL::Introspect->identity_kind(@_);
}

sub _column_def {
  my ($col) = @_;
  my $def = quote_ident($col->{column_name}) . ' ' . ($col->{data_type} // 'text');

  # NOT NULL
  $def .= ' NOT NULL' if $col->{not_null};

  # Generated columns: default_value is the expression they are computed
  # from, not a default
  if (my $generated = DBIO::PostgreSQL::Introspect->generated_kind($col->{generated})) {
    return $def . sprintf ' GENERATED ALWAYS AS (%s) %s', $col->{default_value}, $generated;
  }

  # Default value
  if (defined $col->{default_value} && $col->{default_value} ne '') {
    $def .= sprintf ' DEFAULT %s', $col->{default_value};
  }

  # Identity
  my $kind = DBIO::PostgreSQL::Introspect->identity_kind($col->{identity});
  $def .= " GENERATED $kind AS IDENTITY" if $kind;

  return $def;
}

# CREATE TABLE for a table entry of the model and its columns.
sub _create_table_sql {
  my ($info, $columns) = @_;
  return sprintf 'CREATE %sTABLE %s (%s);',
    ( ($info->{persistence} // '') eq 'u' ? 'UNLOGGED ' : '' ),
    quote_qualified(@{$info}{qw( schema_name table_name )}),
    join ', ', map { _column_def($_) } @{ $columns // [] };
}

sub as_sql {
  my ($self) = @_;
  my $info   = $self->table_info // {};
  my $object = 'table ' . join('.', grep { defined } $self->schema_name, $self->table_name);

  if ($self->action eq 'create') {
    return _create_table_sql(
      { %$info, schema_name => $self->schema_name, table_name => $self->table_name },
      $self->columns,
    );
  }
  elsif ($self->action eq 'set_persistence') {
    my $to = $SET_PERSISTENCE{ $info->{persistence} // '' }
      or DBIO::PostgreSQL::Diff::NoStatement->throw(
        $self, $object, q{its table_info does not say whether the table is to be logged ('p') or unlogged ('u')},
      );
    return sprintf 'ALTER TABLE %s SET %s;',
      quote_qualified($self->schema_name, $self->table_name), $to;
  }
  elsif ($self->action eq 'drop') {
    my $table = quote_qualified($self->schema_name, $self->table_name);
    return sprintf 'DROP FOREIGN TABLE %s;', $table
      if _kind($info) eq 'f';
    return sprintf 'DROP TABLE %s;', $table;
  }
  DBIO::PostgreSQL::Diff::NoStatement->throw($self, $object);
}


sub summary {
  my ($self) = @_;
  return sprintf '  ~table: %s (%s)', $self->qualified_name,
    _persistence_label(($self->table_info // {})->{persistence} // '')
    if $self->action eq 'set_persistence';
  return sprintf '  %stable: %s',
    ($self->action eq 'create' ? '+' : '-'), $self->qualified_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Diff::Table - Diff operations for PostgreSQL tables

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents a table-level diff operation: C<CREATE TABLE ...> (with full
column definitions for new tables), C<DROP TABLE>, or C<ALTER TABLE
... SET LOGGED> / C<SET UNLOGGED> for a table that is kept differently.
Instances are produced by L</diff> and consumed by L<DBIO::PostgreSQL::Diff>.

Diff::Column handles column ADDs for existing tables only; new tables get
their full column list inlined in the CREATE TABLE statement produced here.

The C<tables> section of the model holds every kind of relation, told apart by
C<kind> (L<DBIO::PostgreSQL::Introspect::Tables>). This class creates ordinary
tables only (C<r>, and what a model built by hand gives no kind). Views and
materialized views are L<DBIO::PostgreSQL::Diff::View>'s. A foreign table, a
partitioned table, a partition and a table that inherits can be dropped here
but not created: see L</diff>.

=head1 ATTRIBUTES

=head2 schema_name

PostgreSQL schema containing the table.

=head2 table_name

The table name.

=head2 table_info

Hashref of table metadata from introspection (C<kind>, C<rls_enabled>, etc.).

=head2 columns

ArrayRef of column hashrefs for new tables (populated when C<action> is
C<create>), so that C<as_sql> can emit a complete CREATE TABLE with all
column definitions rather than an empty shell.

=head1 METHODS

=head2 diff

    my @ops = DBIO::PostgreSQL::Diff::Table->diff(
        $source, $target, $source_cols, $target_cols, $source_foreign_keys,
        $target_foreign_keys, $source_outside_dependents);

Compares two table hashrefs (keyed by C<schema.table>) and returns operations
for tables present only in target (create) or only in source (drop).
For new tables, passes column metadata so C<as_sql> can emit a complete
CREATE TABLE with full column definitions (types, nullability, defaults,
identity). Diff::Column only handles ALTER for existing tables.

Views and materialized views are passed over; L<DBIO::PostgreSQL::Diff::View>
creates and drops them.

A table is dropped with C<DROP TABLE> and a foreign table with C<DROP FOREIGN
TABLE>, neither with C<CASCADE>: what the model holds on the table (its indexes,
triggers, policies, its own constraints and the sequences its columns own) goes
with it, the foreign keys that point at it from kept tables and the views that
read it are dropped by the diff ahead of it
(L<DBIO::PostgreSQL::Diff/ORDER OF OPERATIONS>), and a table that inherits from
it, or whose foreign key points at it, is dropped first (the keys of tables
that point at each other, in a circle, are dropped ahead of them:
L<DBIO::PostgreSQL::Diff::ForeignKey/dropped_together>). A partition that goes together with the partitioned table
it belongs to gets no statement: the C<DROP TABLE> of that table takes its
partitions, and one for a partition after it would name a table that is gone.

What stands on the table and is not in the model -- the view or materialized view
of a schema outside C<pg_schemas> that reads it, a foreign key of a table
outside them, a partition or inheriting table there -- is read into the
C<outside_dependents> section (the seventh argument, the section of the
source model) and B<refused>: the diff dies with C<refusing to diff: ...>,
naming each such object, and no statement is written
(L<DBIO::PostgreSQL::Diff::Dependents>). A dependent nobody could name, such
as a policy of another table that reads this one, stops the C<DROP TABLE>
itself; the transaction C<apply> runs in leaves the database as it was.

An ordinary table is created C<UNLOGGED> where the target has it so
(C<persistence> C<u>), and one both sides have that is logged on the one and
unlogged on the other gets an operation of the action C<set_persistence>:
C<ALTER TABLE ... SET UNLOGGED> or C<SET LOGGED>. PostgreSQL takes that for an
ordinary table and for a partition. A target entry that has no C<persistence>
-- a model built by hand -- asks for nothing. The statements come in the order
of the foreign keys the database has (the fifth argument, the C<foreign_keys>
section of the source model): going to C<UNLOGGED> the table that holds a key
before the table it references, going to C<LOGGED> the referenced one first --
PostgreSQL refuses the statement in the other order. Tables not tied by a key
stay in the order of their names. Two tables that reference each other and
change together have no order the server takes, and the diff is refused with
a statement-less message naming them and the way out (drop one key, diff
again, add it back).

These are refused, with C<refusing to diff: ...> and no statement:

=over 4

=item * a table to create whose name differs only in upper and lower case from
one to drop in the same schema -- C<UserAccount> in the target, C<useraccount>
in the database (L<DBIO::PostgreSQL::Diff::CaseOnly>). The two are most likely
one table, and C<DROP TABLE> takes its rows. The message names both, for every
such table at once, and the way out: C<ALTER TABLE public.useraccount RENAME
TO "UserAccount">. The same holds for a foreign table, a partitioned table and
a materialized view (C<ALTER FOREIGN TABLE>, C<ALTER MATERIALIZED VIEW>), each
among its own kind; this is asked ahead of everything else, so such a table is
not answered with "cannot create it". A view is not asked about: it holds
nothing, and L<DBIO::PostgreSQL::Diff::View> drops and creates it.

=item * a relation that is of one kind in the source and of another in the
target -- a table where the target has a view of that name, a view where it
has a materialized view. Making one into the other means dropping it, and with
a table its rows.

=item * a foreign table or a partitioned table that only the target has. The
model holds the columns of such a table, but not the server and options of the
one or the partitioning of the other; C<CREATE TABLE> with those columns makes
an ordinary table of that name.

=item * a partition that only the target has, for the same reason: the model
does not hold its bounds.

=item * a table that only the target has and that inherits from others
(C<inherits>). The diff has no statement for it; C<CREATE TABLE> with its
columns makes an ordinary table that has the inherited columns as its own.
Writing it right takes more than C<INHERITS (...)>: a default or a C<NOT NULL>
the table has of its own on an inherited column can only be given in the
statement by defining the column again, and a column defined again stays
behind when the table above drops it.

=item * a table that is a partition, or inherits, on the one side and not on
the other, or of another table. Attaching a partition needs its bounds, and a
table that is made to inherit needs the columns first. A model that has
neither C<partition_of> nor C<inherits> for the table says nothing, and is not
asked.

=item * a relation that is logged on the one side and unlogged on the other
and is no ordinary table -- PostgreSQL 18 has no unlogged partitioned table
and no unlogged materialized view, and no statement that makes one -- and a
table to create that is temporary, which no model read from the catalog has.

=back

These refusals about partitions and inheritance stay as they are until a
result class can declare them: no key of L<DBIO::PostgreSQL::Result> names a
partitioned table, its bounds or the tables a table inherits from, so the
diff has nothing to build such a table from.

=head2 qualified_name

    my $fqn = $op->qualified_name;  # 'auth.users'

Returns the schema-qualified table name as a reader sees it: the two names
joined with a dot, unquoted. It is what L</summary> prints and is not SQL --
L</as_sql> quotes each name for itself
(L<DBIO::PostgreSQL::Util/quote_qualified>).

=head2 as_sql

Returns the SQL for this operation. For C<create>, emits a complete
CREATE TABLE with all column definitions inline (type, nullability,
default, identity, generation). A default that calls a sequence is written as
the catalog has it; the sequence is created ahead of the table and given to
its column behind it (L<DBIO::PostgreSQL::Diff::Sequence>,
L<DBIO::PostgreSQL::Diff::SequenceOwner>). Diff::Column handles column ADDs for existing
tables, C<CREATE UNLOGGED TABLE> for an unlogged one. For C<set_persistence>,
C<ALTER TABLE ... SET LOGGED> or C<SET UNLOGGED>, as the C<persistence> of its
C<table_info> says. For C<drop>, C<DROP TABLE ...>, or C<DROP FOREIGN
TABLE ...> for a foreign table, each without C<CASCADE>.

Schema, table and column names are written as identifiers by the server's
rule (L<DBIO::PostgreSQL::Util/quote_ident>), so a Mixed-Case or reserved
name reaches the object it names. Column types and defaults come from the
catalog (C<format_type>, C<pg_get_expr>) and are written as given.

A generated column is written C<GENERATED ALWAYS AS (expr) STORED> or, for a
virtual one (PostgreSQL 18), C<... VIRTUAL>
(L<DBIO::PostgreSQL::Introspect/generated_kind>). The catalog keeps its
expression where it keeps a default, so the model has it in C<default_value>;
it is not a default and is not written as one.

For an C<action> this class does not know it dies
(L<DBIO::PostgreSQL::Diff::NoStatement/throw>), and for a C<set_persistence>
whose C<table_info> names neither of the two.

=head2 summary

Returns a one-line description such as C<+table: auth.users>, or C<~table:
auth.sessions (unlogged)> for a table that is kept differently.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
