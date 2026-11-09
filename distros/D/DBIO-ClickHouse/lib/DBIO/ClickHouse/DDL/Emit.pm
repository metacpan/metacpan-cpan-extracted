package DBIO::ClickHouse::DDL::Emit;
# ABSTRACT: Single source of ClickHouse DDL statement shape

use strict;
use warnings;

use Carp ();
use DBIO::Exception ();

our $VERSION = '0.900004';

use Exporter 'import';

our @EXPORT_OK = qw(
  quote_ident quote_string column_def index_def
  engine_clause partition_by_clause primary_key_clause order_by_clause
  settings_clause create_table create_view drop_view drop_table
  split_table_name
  alter_table_add_column alter_table_modify_column alter_table_drop_column
  alter_table_remove_default
  alter_table_add_index alter_table_drop_index
  create_database drop_database
);



sub quote_ident {
  my ($name) = @_;
  $name =~ s/([\\`])/\\$1/g;
  return "`$name`";
}


sub quote_string {
  my ($value) = @_;
  $value =~ s/([\\'])/\\$1/g;
  return "'$value'";
}


sub column_def {
  my (%a) = @_;
  my $def = sprintf '%s %s', quote_ident($a{name}), ($a{type} // 'String');
  $def .= " DEFAULT $a{default}" if defined $a{default};
  return $def;
}


sub index_def {
  my ($info) = @_;

  my $def = sprintf 'INDEX %s %s TYPE %s',
    quote_ident($info->{index_name}),
    ($info->{expr} // ''),
    ($info->{type_full} // $info->{type} // 'minmax');

  $def .= " GRANULARITY $info->{granularity}" if defined $info->{granularity};

  return $def;
}


sub engine_clause {
  my ($engine) = @_;
  return sprintf 'ENGINE = %s', $engine // 'MergeTree';
}


sub partition_by_clause {
  my ($expr) = @_;
  return "PARTITION BY $expr";
}


sub primary_key_clause {
  my (@key) = @_;
  return sprintf 'PRIMARY KEY (%s)', _key_list(@key);
}


sub order_by_clause {
  my (@key) = @_;
  return 'ORDER BY tuple()' unless @key;
  return sprintf 'ORDER BY (%s)', _key_list(@key);
}

sub _key_list {
  return join ', ', map { ref $_ eq 'SCALAR' ? $$_ : quote_ident($_) } @_;
}


sub settings_clause {
  my ($settings) = @_;
  return undef unless ref $settings eq 'HASH' && keys %$settings;
  return sprintf 'SETTINGS %s', join ', ',
    map { sprintf '%s = %s', $_, _setting_value($settings->{$_}) }
    sort keys %$settings;
}

sub _setting_value {
  my ($value) = @_;
  return $$value if ref $value eq 'SCALAR';
  return 'NULL'  unless defined $value;
  return $value  if $value =~ /\A-?(?:[0-9]+(?:\.[0-9]+)?)\z/;
  return quote_string($value);
}


sub create_table {
  my (%a) = @_;
  my $sql = sprintf "CREATE TABLE%s %s (\n%s\n)",
    ($a{if_not_exists} ? ' IF NOT EXISTS' : ''),
    (defined $a{database} ? quote_ident($a{database}) . '.' : '') . quote_ident($a{name}),
    join ",\n", map { "  $_" } @{ $a{columns} // [] };
  my @clauses = grep { defined && length } @{ $a{clauses} // [] };
  $sql .= "\n" . join "\n", @clauses if @clauses;
  return "$sql;";
}


sub create_view {
  my (%a) = @_;
  return sprintf 'CREATE %sVIEW%s %s AS %s;',
    ($a{or_replace} ? 'OR REPLACE ' : ''),
    ($a{if_not_exists} && !$a{or_replace} ? ' IF NOT EXISTS' : ''),
    (defined $a{database} ? quote_ident($a{database}) . '.' : '') . quote_ident($a{name}),
    $a{definition};
}


sub drop_view {
  my (%a) = @_;
  return sprintf 'DROP VIEW%s %s;',
    ($a{if_exists} ? ' IF EXISTS' : ''),
    (defined $a{database} ? quote_ident($a{database}) . '.' : '') . quote_ident($a{name});
}


sub split_table_name {
  my ($name) = @_;
  return (undef, $name) unless defined $name && !ref $name && $name =~ /\./;
  my @parts = split /\./, $name, -1;
  DBIO::Exception->throw("DBIO::ClickHouse: table '$name' is refused: a table "
    . 'or view name is name or database.name, with both halves given and one dot')
    unless @parts == 2 && length $parts[0] && length $parts[1];
  return @parts;
}


sub drop_table {
  my (%a) = @_;
  return sprintf 'DROP TABLE%s %s;',
    ($a{if_exists} ? ' IF EXISTS' : ''),
    quote_ident($a{name});
}


sub alter_table_add_column {
  my (%a) = @_;
  return _alter_table($a{table},
    "ADD COLUMN" . ($a{if_not_exists} ? ' IF NOT EXISTS' : '') . " $a{definition}");
}


sub alter_table_modify_column {
  my (%a) = @_;
  for my $forbidden (qw(if_exists if_not_exists)) {
    Carp::croak("alter_table_modify_column does not accept $forbidden - "
      . 'ClickHouse has no MODIFY COLUMN IF [NOT] EXISTS guard; '
      . 'see t/38-ddl-if-exists-live.t for the negative-space verification')
      if exists $a{$forbidden};
  }
  return _alter_table($a{table}, "MODIFY COLUMN $a{definition}");
}


sub alter_table_remove_default {
  my (%a) = @_;
  return _alter_table($a{table}, 'MODIFY COLUMN ' . quote_ident($a{name}) . ' REMOVE DEFAULT');
}


sub alter_table_drop_column {
  my (%a) = @_;
  return _alter_table($a{table},
    'DROP COLUMN' . ($a{if_exists} ? ' IF EXISTS' : '') . ' ' . quote_ident($a{name}));
}


sub alter_table_add_index {
  my (%a) = @_;
  # $a{definition} comes from index_def() and begins with "INDEX `name` ..."
  # so the guard has to slot in after the INDEX keyword. Strip the leading
  # INDEX here once rather than duplicate it under either condition.
  my ($rest) = $a{definition} =~ /\AINDEX\s+(.*)\z/s;
  return _alter_table($a{table},
    'ADD INDEX' . ($a{if_not_exists} ? ' IF NOT EXISTS' : '') . " $rest");
}


sub alter_table_drop_index {
  my (%a) = @_;
  return _alter_table($a{table},
    'DROP INDEX' . ($a{if_exists} ? ' IF EXISTS' : '') . ' ' . quote_ident($a{name}));
}

sub _alter_table {
  my ($table, $action) = @_;
  return sprintf 'ALTER TABLE %s %s;', quote_ident($table), $action;
}


sub create_database {
  my (%a) = @_;
  return sprintf 'CREATE DATABASE %s', quote_ident($a{name});
}


sub drop_database {
  my (%a) = @_;
  return sprintf 'DROP DATABASE %s%s',
    ($a{if_exists} ? 'IF EXISTS ' : ''), quote_ident($a{name});
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ClickHouse::DDL::Emit - Single source of ClickHouse DDL statement shape

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

The ClickHouse DDL string templates -- column and data-skipping-index
definitions, the MergeTree engine clauses (C<ENGINE> / C<PARTITION BY> /
C<PRIMARY KEY> / C<ORDER BY> / C<SETTINGS>), and every statement wrapper this
driver emits (C<CREATE TABLE>, C<CREATE VIEW>, C<DROP TABLE>, the
C<ALTER TABLE> column and index forms, C<CREATE> / C<DROP DATABASE>) -- live
here so that every producer of ClickHouse DDL agrees on syntax char-for-char:

=over 4

=item * L<DBIO::ClickHouse::DDL> renders the desired schema from DBIO Result
classes (C<column_info> hashrefs plus C<clickhouse_table> options).

=item * The C<DBIO::ClickHouse::Diff::*> renderers render C<CREATE> / C<DROP> /
C<ALTER> statements from an introspected model.

=item * L<DBIO::ClickHouse::Deploy> issues the scratch-database
C<CREATE DATABASE> / C<DROP DATABASE> pair.

=back

Each caller owns the field-extraction adapter for its own input shape (DBIO
metadata vs introspected model) and feeds normalized pieces here. These
functions are pure: identifiers and string literals are quoted, nothing else
is interpreted. Clauses are returned B<without> indentation; L</create_table>
indents the column body and appends the engine clauses one per line.

=head2 Fragments are passed in pre-rendered

The statement wrappers take an already-rendered C<definition> rather than the
pieces to build one -- L</create_table> takes a list of L</column_def> results,
L</alter_table_add_index> takes an L</index_def> result. That is what lets the
same fragment appear in two statements without a second copy of its syntax: a
skipping index is rendered once by L</index_def> and lands both inside a
C<CREATE TABLE> body and after an C<ALTER TABLE ... ADD>.

=head2 Statement termination

The table-level statements end in a semicolon, because they are collected into
a DDL script -- L<DBIO::ClickHouse::DDL/install_ddl> joins them with a blank
line, C<< $diff->as_sql >> with a newline. L</create_database> and
L</drop_database> do not: they never appear in such a script. They are the two
statements L<DBIO::ClickHouse::Deploy> issues on their own, around one.

=head2 Why this module quotes its own identifiers

Every other DBIO driver reaches for C<DBIO::SQL::Util::_quote_ident>, which
leaves simple identifiers bare and falls back to ANSI double quotes. This
module deliberately does B<not>: ClickHouse quotes with the backtick (the
MySQL-wire character this driver already pins via C<sql_quote_char>, see
C<docs/adr/0001-mysql-wire-protocol-transport.md>), and C<SHOW CREATE TABLE>
-- the round-trip source the diff layer will compare against -- backtick-quotes
B<every> identifier unconditionally. Emitting the same shape keeps the
desired-state DDL and the server's own rendering comparable.

=head2 Clause order

L</create_table> emits the engine clauses in the order C<SHOW CREATE TABLE>
prints them: C<ENGINE>, C<PARTITION BY>, C<PRIMARY KEY>, C<ORDER BY>,
C<SETTINGS>. The caller assembles the list; this module just joins it.

=head1 METHODS

=head2 quote_ident

    quote_ident($name);

Backtick-quotes an identifier unconditionally, escaping embedded backslashes
and backticks with a backslash (ClickHouse's escape convention).

=head2 quote_string

    quote_string($value);

Single-quotes a string literal, escaping embedded backslashes and single
quotes with a backslash.

=head2 column_def

    column_def(name => $n, type => $t, default => $sql);

Renders C<< `name` Type [DEFAULT $sql] >>. C<default> is emitted verbatim --
the caller is responsible for quoting/escaping it. Pass C<undef> for no
default.

There is deliberately no C<not_null> argument: ClickHouse columns are B<NOT
NULL by default> and nullability is part of the type (C<Nullable(T)>), not a
separate column constraint. The type string handed in already carries it.

=head2 index_def

    index_def($index_info);

Renders one data-skipping index definition B<without> any surrounding
statement:

    INDEX `name` expr TYPE minmax GRANULARITY 4

This is the shape ClickHouse uses in both places a skipping index can appear --
inline in the C<CREATE TABLE> body (L<DBIO::ClickHouse::Diff::Table>) and after
C<ALTER TABLE ... ADD> (L</alter_table_add_index>) -- so both render through
this one function rather than each keeping a copy of the syntax.

Unlike the other renderers here this one takes the model hashref itself
(C<index_name>, C<expr>, C<type_full> / C<type>, C<granularity>), because the
introspected model is the shape it is fed: L<DBIO::ClickHouse::DDL> builds the
same keys from a canonical index declaration, so a declared index and an
introspected one render alike.

C<expr> is emitted verbatim -- it is an expression, not an identifier. C<TYPE>
uses C<type_full> when present, so that a parameterized type keeps its
arguments (C<set(100)>, not C<set>), and falls back to the bare C<type>.
C<GRANULARITY> is omitted when the info carries none, leaving the server
default.

=head2 engine_clause

    engine_clause('MergeTree');
    engine_clause('ReplacingMergeTree(version)');

Renders C<ENGINE = ...>. The engine string is emitted verbatim so that
parameterized engines work. Defaults to C<MergeTree> when C<undef>.

=head2 partition_by_clause

    partition_by_clause('toYYYYMM(ts)');

Renders C<PARTITION BY ...>. The argument is an B<expression> and is emitted
verbatim -- unlike the key lists below, it is not quoted as an identifier,
because a partition key is almost always a function call.

=head2 primary_key_clause

    primary_key_clause(@key);

Renders C<PRIMARY KEY (...)>. See L</order_by_clause> for how entries are
rendered.

In ClickHouse a C<PRIMARY KEY> is only meaningful as a prefix of the sorting
key; when it equals the sorting key it is omitted entirely and C<ORDER BY>
alone defines it.

=head2 order_by_clause

    order_by_clause(@key);
    order_by_clause();                       # ORDER BY tuple()
    order_by_clause('ts', \'cityHash64(id)');

Renders the MergeTree sorting key as C<ORDER BY (...)>. Plain strings are
quoted as column identifiers; SCALAR refs are emitted verbatim as raw SQL
expressions. An empty key list renders C<ORDER BY tuple()>, ClickHouse's
spelling for "no sorting key".

The tuple form is used even for a single-column key: it is always valid and
keeps the rendering uniform.

=head2 settings_clause

    settings_clause({ index_granularity => 8192 });

Renders C<SETTINGS name = value, ...> with the setting names sorted for
deterministic output. Numeric-looking values are emitted bare, SCALAR refs
verbatim, everything else as a quoted string literal.

Returns C<undef> when there is nothing to emit, so the caller can push the
result into its clause list unconditionally-ish (C<< push ... if defined >>).

=head2 create_table

    create_table(
      name          => $table,
      columns       => \@column_defs,
      clauses       => \@engine_clauses,
      if_not_exists => 0|1,
    );

Wraps the (unindented) column definitions in a C<CREATE TABLE>, indenting each
by two spaces, then appends the engine clauses one per line. Undefined or
empty clauses are dropped, so a caller may pass the result of
L</settings_clause> straight through.

Pass C<database =E<gt> $db> to write the table into that database
(C<CREATE TABLE `db`.`name`>; see L</split_table_name>).

Pass C<if_not_exists =E<gt> 1> to render C<CREATE TABLE IF NOT EXISTS>; the
diff layer routes that through L<DBIO::Diff::Op/should_emit_if_exists> on
storage that declares the F12 capability, so a re-applied migration no-ops
instead of erroring on the partial-failure path. The capability flag is the
single source of truth -- this function does not inspect the engine.

=head2 create_view

    create_view(name => $view, definition => $select_sql, if_not_exists => 0|1,
                or_replace => 0|1, database => $db);

Renders C<CREATE VIEW `name` AS $select_sql;>, or C<CREATE VIEW IF NOT EXISTS
`name` AS ...;> when asked. C<or_replace> renders C<CREATE OR REPLACE VIEW>,
the form the diff replaces a changed view with (the server swaps the
definition in one statement; it does not combine with C<IF NOT EXISTS>, and
C<or_replace> wins). The definition is emitted verbatim. C<database> writes the
view into that database (C<CREATE VIEW `db`.`name`>, see L</split_table_name>).

=head2 drop_view

    drop_view(name => $view, if_exists => 0|1, database => $db);

Renders C<< DROP VIEW `name`; >>, or C<< DROP VIEW IF EXISTS `name`; >> when
asked, gated by the diff layer on the same capability as the table forms. A
materialized view is dropped with the same statement, which is why the diff
never emits it for one (L<DBIO::ClickHouse::Diff::View>).

=head2 split_table_name

    my ($database, $table) = split_table_name('other.t');   # ('other', 't')
    my ($database, $table) = split_table_name('t');          # (undef, 't')

Splits the name a source gives its table at its dot: C<database.table> to
ClickHouse, as the SQLMaker reads it; a view's name is read the same
way. A name without a dot is the
table alone. Throws a L<DBIO::Exception> for a name with more than one dot or
an empty half (C<.t>, C<db.>), which names nothing.

=head2 drop_table

    drop_table(name => $table, if_exists => 0|1);

Renders C<< DROP TABLE `name`; >>, or C<< DROP TABLE IF EXISTS `name`; >> when
asked.

Note: the only caller (L<DBIO::ClickHouse::Diff::Table>) knows at diff time
that the live model carries this table, and the guard is written all the same:
a multi-statement migration that dropped this table on its first apply, then
failed on a downstream statement, re-runs as a no-op only when the second-pass
C<DROP TABLE IF EXISTS> swallows the "unknown table" error. The diff layer
gates it on the F12 capability exactly as CREATE TABLE does above.

=head2 alter_table_add_column

    alter_table_add_column(
      table         => $table,
      definition    => column_def(...),
      if_not_exists => 0|1,
    );

Renders C<< ALTER TABLE `t` ADD COLUMN `c` Type; >>, or the C<IF NOT EXISTS>
form when asked. The definition arrives pre-rendered (see
L</Fragments are passed in pre-rendered>), so a column added by a diff is
spelled exactly as the same column would be inside a fresh C<CREATE TABLE>.

The guard is gated on the F12 capability, the same as
L</create_table>'s C<IF NOT EXISTS>. C<ALTER TABLE ... ADD COLUMN IF NOT
EXISTS> is a B<silent no-op when the column already exists with a different
type> -- not a repair -- so a partial-failure reapply on a manually-modified
column leaves a stale type. The diff layer therefore sets the flag only on
this engine's capability bit, not unconditionally; the actual reapply safety
net on a real type change is the follow-up C<MODIFY COLUMN>, which (see
L</alter_table_modify_column>) does B<not> accept the flag at all.

=head2 alter_table_modify_column

    alter_table_modify_column(table => $table, definition => column_def(...));

Renders C<< ALTER TABLE `t` MODIFY COLUMN `c` Type; >>. Restating the
definition is how ClickHouse changes a column; the server accepts the statement
synchronously and converts the data as a background mutation.

B<No C<IF EXISTS> / C<IF NOT EXISTS> argument.> ClickHouse has no guard form
for C<ALTER TABLE ... MODIFY COLUMN> -- t/38 verifies this by negative space,
and L<DBIO::ClickHouse::Diff::Column/HOW IT LINKS INTO PARTIAL-FAILURE
REAPPLY> documents why the diff layer never asks for one. An unexpected
C<if_exists> / C<if_not_exists> argument is treated as a programming error.

=head2 alter_table_remove_default

    alter_table_remove_default(table => $table, name => $column);

Renders C<< ALTER TABLE `t` MODIFY COLUMN `c` REMOVE DEFAULT; >>. A column's
default cannot be dropped by restating its definition without one -- the
server keeps the old expression then -- and C<REMOVE DEFAULT> takes no type
beside it, so a type change is a statement of its own. Rows keep the value
they were written with; only what an insert leaves out changes.

=head2 alter_table_drop_column

    alter_table_drop_column(
      table     => $table,
      name      => $column,
      if_exists => 0|1,
    );

Renders C<< ALTER TABLE `t` DROP COLUMN `c`; >>, or the C<IF EXISTS> form
when asked. The flag routes through the F12 capability probe
(L<DBIO::ClickHouse::Diff::Column/DIFF AS SQL>) on the same path as
L</drop_table>'s guard.

=head2 alter_table_add_index

    alter_table_add_index(
      table         => $table,
      definition    => index_def($info),
      if_not_exists => 0|1,
    );

Renders C<< ALTER TABLE `t` ADD INDEX `i` expr TYPE ...; >>, or the C<IF NOT
EXISTS> form when asked. The C<INDEX> keyword comes from L</index_def> --
this function only wraps it -- which is what makes the added index
char-identical to the one a C<CREATE TABLE> would carry inline.

=head2 alter_table_drop_index

    alter_table_drop_index(
      table     => $table,
      name      => $index,
      if_exists => 0|1,
    );

Renders C<< ALTER TABLE `t` DROP INDEX `i`; >>, or the C<IF EXISTS> form when
asked.

Note: in ClickHouse C<ALTER TABLE ... DROP INDEX> is a B<data mutation>, not
pure DDL -- the server accepts the statement synchronously but the actual
deletion runs in the background. Interactions with C<mutations_sync> belong to
the applier; this function renders the SQL.

=head2 create_database

    create_database(name => $name);

Renders C<< CREATE DATABASE `name` >>. No C<ENGINE> clause, so the database
gets the server default (C<Atomic> on any supported version). Unterminated;
see L</Statement termination>.

=head2 drop_database

    drop_database(name => $name, if_exists => 1);

Renders C<< DROP DATABASE `name` >>, prefixed with C<IF EXISTS> when asked.
L<DBIO::ClickHouse::Deploy> always asks: its cleanup runs unconditionally,
including on the path where the C<CREATE> is the statement that failed.
Unterminated; see L</Statement termination>.

=head2 The ALTER TABLE forms

The five C<alter_table_*> functions below are what a ClickHouse schema change
looks like once the table exists. There is no C<CREATE INDEX> and no
C<ALTER INDEX> in this engine, and no way to touch a column outside
C<ALTER TABLE>, so every post-creation change routes through one of them. Each
returns one complete, terminated statement.

They are B<DDL>. ClickHouse also spells its row-level update and delete
C<ALTER TABLE ... UPDATE> / C<ALTER TABLE ... DELETE>, but those are
asynchronous B<data> mutations rendered by L<DBIO::ClickHouse::SQLMaker> from a
resultset's condition -- a different input, a different execution path, and
nothing in common with these beyond the two leading keywords.

=head1 SEE ALSO

=over 4

=item * L<DBIO::ClickHouse::DDL> - the desired-state producer feeding this module

=item * L<DBIO::ClickHouse::Diff> - the diff renderers feeding this module

=item * L<DBIO::ClickHouse::Deploy> - the scratch-database lifecycle

=item * L<DBIO::ClickHouse::Result> - the C<clickhouse_table> options this module renders

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
