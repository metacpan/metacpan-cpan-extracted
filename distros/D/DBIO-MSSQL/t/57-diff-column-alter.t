#!/usr/bin/env perl
# t/57-diff-column-alter.t -- DBIO::MSSQL::Diff::Column, action => 'alter'
# (karr k30 + karr k31, one block, one decision).
#
# Offline. Every statement here is judged against the Transact-SQL grammar in
# the ALTER TABLE reference, not against a server: no SQL Server was available
# when this was written and nothing below claims to have been executed. What a
# live run would add is named in DBIO::MSSQL::Diff::Column's POD.
#
# THE FORM, and why it is one statement rather than three
#
#   ALTER COLUMN column_name
#       [ type_schema_name. ] type_name [ ( { precision [, scale] | max | ... } ) ]
#       [ COLLATE collation_name ] [ NULL | NOT NULL ] [ SPARSE ]
#
# The type is not optional in that production, so the old
# "ALTER COLUMN a NOT NULL" (no type) is not a statement SQL Server can parse.
# Microsoft says so twice over: "If you specify NULL or NOT NULL with ALTER
# COLUMN, you must also specify new_data_type [(precision [, scale ])]. If the
# data type, precision, and scale aren't changing, specify the current column
# values." And in the other direction: "ANSI_NULL defaults are always on for
# ALTER COLUMN; if not specified, the column is nullable" -- so leaving the
# nullability off an ALTER COLUMN does not preserve it, it DROPS it. Type and
# nullability therefore belong in one statement, always both written.
#
# Once they are one statement, the trigger has to be the RENDERED type
# (_mssql_column_type: length, precision, (max) included) rather than the bare
# data_type string, which is karr k30: INFORMATION_SCHEMA reports the length in
# CHARACTER_MAXIMUM_LENGTH, so nvarchar(64) -> nvarchar(128) is 'nvarchar' on
# both sides, fell through every branch, and left as_sql returning "".

use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::MSSQL::Diff::Column;
use DBIO::Diff::Compare qw(changed_column_fields);

# Every case goes through ->diff rather than a hand-built op: the two bugs are
# both a disagreement between what the comparator DETECTS and what as_sql
# RENDERS, and only the full path can sample that.
sub alter_sql {
  my ($old, $new) = @_;
  my @ops = DBIO::MSSQL::Diff::Column->diff(
    { t => [ { column_name => 'a', %$old } ] },
    { t => [ { column_name => 'a', %$new } ] },
    { t => {} }, { t => {} },
  );
  return (\@ops, @ops == 1 ? $ops[0]->as_sql : undef);
}

# --- A. karr k31 (1)+(2): type and nullability in ONE valid statement -------

# (2) The claim t/50-diff.t used to pin, restated against the grammar: a
# nullability-only drift still produces exactly one ALTER COLUMN that makes the
# column NOT NULL -- now spelling out the unchanged type, which is precisely
# what "specify the current column values" asks for.
{
  my ($ops, $sql) = alter_sql(
    { data_type => 'int', not_null => 0 },
    { data_type => 'int', not_null => 1 },
  );
  is(scalar @$ops, 1, 'nullability drift -> one alter op');
  is($ops->[0]->action, 'alter', '... an alter');
  is($sql, 'ALTER TABLE t ALTER COLUMN a int NOT NULL;',
    'nullability-only change repeats the current type -- the grammar requires it');
}

{
  my (undef, $sql) = alter_sql(
    { data_type => 'int', not_null => 1 },
    { data_type => 'int', not_null => 0 },
  );
  is($sql, 'ALTER TABLE t ALTER COLUMN a int NULL;',
    '... and the other direction is explicit too, never an omitted NULL');
}

# (1) A type change must carry the nullability along. Left off, "ANSI_NULL
# defaults are always on for ALTER COLUMN" silently turns a NOT NULL column
# nullable -- a data-model change nobody asked for.
{
  my (undef, $sql) = alter_sql(
    { data_type => 'int',    not_null => 1 },
    { data_type => 'bigint', not_null => 1 },
  );
  is($sql, 'ALTER TABLE t ALTER COLUMN a bigint NOT NULL;',
    'a type change keeps NOT NULL in the same statement');
}

# The same, with the target NOT prescribing not_null at all. core's
# changed_column_fields skips a scalar field the target leaves undef ("the
# desired state did not prescribe it"), so as_sql has to read it the same way:
# fall back to the LIVE value instead of defaulting to nullable.
{
  my (undef, $sql) = alter_sql(
    { data_type => 'int',    not_null => 1 },
    { data_type => 'bigint' },
  );
  is($sql, 'ALTER TABLE t ALTER COLUMN a bigint NOT NULL;',
    'a target that does not prescribe nullability keeps the live one, not NULL');
}

# --- B. karr k30: a size/precision drift is detected, so it must render ------

{
  my ($ops, $sql) = alter_sql(
    { data_type => 'nvarchar', size => 64 },
    { data_type => 'nvarchar', size => 128 },
  );
  is_deeply([ changed_column_fields(
      { column_name => 'a', data_type => 'nvarchar', size => 64 },
      { column_name => 'a', data_type => 'nvarchar', size => 128 }) ],
    ['size'], 'the comparator calls a pure length drift a change');
  is(scalar @$ops, 1, '... so diff produces an op');
  like($sql, qr/\S/, '... and the op renders a statement, not the empty string');
  is($sql, 'ALTER TABLE t ALTER COLUMN a nvarchar(128) NULL;',
    'nvarchar(64) -> nvarchar(128): the rendered type is the trigger');
}

{
  my (undef, $sql) = alter_sql(
    { data_type => 'numeric', size => [10, 2], not_null => 1 },
    { data_type => 'numeric', size => [12, 4], not_null => 1 },
  );
  is($sql, 'ALTER TABLE t ALTER COLUMN a numeric(12,4) NOT NULL;',
    'numeric(10,2) -> numeric(12,4): precision/scale drift renders too');
}

# The (max) round trip from karr k28, now from the other side: a column that
# reached the server as a one-character column has to be widened back.
{
  my (undef, $sql) = alter_sql(
    { data_type => 'nvarchar', size => 1 },
    { data_type => 'nvarchar', size => -1 },
  );
  is($sql, 'ALTER TABLE t ALTER COLUMN a nvarchar(max) NULL;',
    'the (max) marker renders as (max) in an ALTER, as it does in a CREATE');
}

# The converse, which is the whole point of comparing the RENDERED type: two
# spellings of the same native type are not a change. 'varchar' maps to
# nvarchar on this driver, so a target saying varchar(64) against a live
# nvarchar(64) must not produce a phantom ALTER.
{
  my ($ops) = alter_sql(
    { data_type => 'nvarchar', size => 64 },
    { data_type => 'varchar',  size => 64 },
  );
  is(scalar @$ops, 1, 'the comparator still sees the two spellings as a change');
  is($ops->[0]->as_sql, '',
    '... but nothing is emitted, because the rendered type is identical');
}

# --- C. the desired-state fallback is per FIELD, not per hashref ------------
#
# A target that prescribes a type but no size must not lose the live size: bare
# nvarchar in a column definition is NOT "unbounded", it is nvarchar(1). This is
# the karr k28 failure mode reached through the alter branch.
{
  my (undef, $sql) = alter_sql(
    { data_type => 'nvarchar', size => 64, not_null => 0 },
    { data_type => 'nvarchar',            not_null => 1 },
  );
  is($sql, 'ALTER TABLE t ALTER COLUMN a nvarchar(64) NOT NULL;',
    'an unprescribed size keeps the live length -- never a bare nvarchar(1)');
}

# ... and a target that prescribes only a size keeps the live type.
{
  my (undef, $sql) = alter_sql(
    { data_type => 'varbinary', size => 16 },
    {                           size => 32 },
  );
  is($sql, 'ALTER TABLE t ALTER COLUMN a varbinary(32) NULL;',
    'an unprescribed data_type keeps the live type, not the nvarchar default');
}

# --- D. karr k31 (3): a DEFAULT is a named CONSTRAINT in T-SQL ---------------
#
# <table_constraint> ::= [ CONSTRAINT constraint_name ]
#                        { ... | DEFAULT constant_expression FOR column_name }
# and DROP [ CONSTRAINT ] [ IF EXISTS ] constraint_name. The ANSI/PostgreSQL
# "ALTER COLUMN a SET DEFAULT x" / "DROP DEFAULT" the old code emitted does not
# exist in this dialect at all.

{
  my (undef, $sql) = alter_sql(
    { data_type => 'int' },
    { data_type => 'int', default_value => '((0))' },
  );
  is($sql, 'ALTER TABLE t ADD CONSTRAINT DF_t_a DEFAULT ((0)) FOR a;',
    'a new default is an ADD CONSTRAINT ... DEFAULT ... FOR column');
  unlike($sql, qr/ALTER COLUMN/,
    '... and nothing else: type and nullability did not move');
  unlike($sql, qr/SET DEFAULT/, '... no ANSI SET DEFAULT anywhere');
}

# Replacing one needs the LIVE constraint name, which is why
# DBIO::MSSQL::Introspect::Columns now reports default_constraint_name.
{
  my (undef, $sql) = alter_sql(
    { data_type => 'int', default_value => '((0))',
      default_constraint_name => 'DF__t__a__3B75D760' },
    { data_type => 'int', default_value => '((1))' },
  );
  is($sql, join("\n",
      'ALTER TABLE t DROP CONSTRAINT DF__t__a__3B75D760;',
      'ALTER TABLE t ADD CONSTRAINT DF_t_a DEFAULT ((1)) FOR a;'),
    'a replaced default drops the live constraint by name, then adds the new one');
}

# Without the name there is no correct statement to emit -- and the wrong one
# would be accepted-looking SQL that drops nothing. Refuse instead.
{
  throws_ok {
    alter_sql(
      { data_type => 'int', default_value => '((0))' },
      { data_type => 'int', default_value => '((1))' },
    );
  } qr/default_constraint_name/,
    'a default that must be replaced but has no known constraint name croaks';
}

# A default the target no longer declares is dropped by its live name (core
# karr k367, karr k83); a live DEFAULT NULL is none and renders nothing.
{
  my (undef, $sql) = alter_sql(
    { data_type => 'int', default_value => '((0))',
      default_constraint_name => 'DF_t_a' },
    { data_type => 'int' },
  );
  is($sql, 'ALTER TABLE t DROP CONSTRAINT DF_t_a;',
    'a removed default is a DROP CONSTRAINT by the live name');

  (undef, $sql) = alter_sql(
    { data_type => 'int', not_null => 0, default_value => '((0))',
      default_constraint_name => 'DF_old' },
    { data_type => 'bigint', not_null => 0 },
  );
  is($sql, join("\n",
      'ALTER TABLE t DROP CONSTRAINT DF_old;',
      'ALTER TABLE t ALTER COLUMN a bigint NULL;'),
    'removed default and retype: the drop comes first');

  throws_ok {
    alter_sql({ data_type => 'int', default_value => '((0))' }, { data_type => 'int' });
  } qr/default_constraint_name/, 'a removed default without a known constraint name croaks';

  (undef, $sql) = alter_sql(
    { data_type => 'int', default_value => '(NULL)', default_constraint_name => 'DF_n' },
    { data_type => 'bigint' },
  );
  unlike($sql, qr/DROP CONSTRAINT/, 'a live DEFAULT NULL is no default: nothing to drop');
}

# Ordering matters when both move: SQL Server refuses ALTER COLUMN on a column
# that is "associated with a default definition" when the data type changes, so
# the drop has to come first and the add last.
{
  my (undef, $sql) = alter_sql(
    { data_type => 'int', not_null => 1, default_value => '((0))',
      default_constraint_name => 'DF_old' },
    { data_type => 'bigint', not_null => 1, default_value => '((1))' },
  );
  is($sql, join("\n",
      'ALTER TABLE t DROP CONSTRAINT DF_old;',
      'ALTER TABLE t ALTER COLUMN a bigint NOT NULL;',
      'ALTER TABLE t ADD CONSTRAINT DF_t_a DEFAULT ((1)) FOR a;'),
    'drop the default, retype, re-add -- the only order the engine accepts');
}

# --- E. nothing renderable is better than something wrong -------------------

# No data_type on either side and a nullability change: there is no "current
# column value" to repeat, and the renderer's bare-nvarchar default would
# silently retype the column to a one-character string.
{
  throws_ok {
    alter_sql({ not_null => 0 }, { not_null => 1 });
  } qr/\bt\.a\b/,
    'a nullability change with no type known anywhere croaks, naming the column';
}

# A stated width that cannot exist reaches the same wall _mssql_column_type
# already put up for CREATE TABLE (karr k28), with the column named.
{
  throws_ok {
    alter_sql({ data_type => 'nvarchar', size => 64 },
              { data_type => 'nvarchar', size => 0 });
  } qr/\bt\.a\b/,
    'an unrenderable desired type croaks with the column, not a bare nvarchar';
}

# --- F. the invariant both tickets are really about -------------------------
#
# has_changes must never be true while apply() has nothing to run: core splits
# the returned string into statements, so an empty string is a diff that reports
# work and does none, and never converges.
{
  my @drifts = (
    [ { data_type => 'nvarchar', size => 64 },       { data_type => 'nvarchar', size => 128 } ],
    [ { data_type => 'numeric', size => [10, 2] },   { data_type => 'numeric', size => [12, 4] } ],
    [ { data_type => 'nvarchar', size => 1 },        { data_type => 'nvarchar', size => -1 } ],
    [ { data_type => 'int', not_null => 0 },         { data_type => 'int', not_null => 1 } ],
    [ { data_type => 'int' },                        { data_type => 'bigint' } ],
    [ { data_type => 'int' },                        { data_type => 'int', default_value => '((7))' } ],
  );
  for my $d (@drifts) {
    my ($old, $new) = @$d;
    my ($ops, $sql) = alter_sql($old, $new);
    next unless @$ops;
    like($sql, qr/\S/,
      "a detected change on $old->{data_type} renders at least one statement");
  }
}

done_testing;
