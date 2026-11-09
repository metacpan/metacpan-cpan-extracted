use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::MSSQL::DDL qw(_mssql_column_type);
use DBIO::MSSQL::Diff::Table;
use DBIO::MSSQL::Diff::Column;
use DBIO::Diff::Compare qw(changed_column_fields);

# --- karr k17: legacy 'decimal' alias must not drop precision/scale ---
is(_mssql_column_type({ data_type => 'decimal', size => [10, 2] }),
  'numeric(10,2)', 'decimal with [precision,scale] size renders numeric(10,2)');

# --- regression: bare numeric (no size) still renders unchanged ---
is(_mssql_column_type({ data_type => 'numeric' }),
  'numeric', 'numeric with no size stays bare numeric');

# --- regression: decimal with only precision (no scale) ---
is(_mssql_column_type({ data_type => 'decimal', size => [10] }),
  'numeric(10)', 'decimal with precision-only size renders numeric(10)');

# --- smoke check: char/varchar size-append branch untouched ---
is(_mssql_column_type({ data_type => 'varchar', size => 255 }),
  'nvarchar(255)', 'varchar with size still maps to sized nvarchar');

# --- karr k27: the char-family length branch must READ an arrayref size ---
#
# The guard on that branch (DDL.pm:275) is `defined $size && $size > 0`, which
# is right about the value it was written for -- MSSQL reports the (max)
# variants as size -1 -- and blind to the shape. A reference numifies to its
# address, which is always positive, so an arrayref passed the guard and then
# stringified into the type name: nvarchar(ARRAY(0x...)), a statement no server
# parses. The numeric branch six lines above has read arrayrefs correctly since
# karr k17; this is the same reading applied to the branch that lacked it.
#
# Every type in that regex takes exactly ONE scalar length in Transact-SQL --
# char[(n)], varchar[(n|max)], nchar[(n)], nvarchar[(n|max)], binary[(n)],
# varbinary[(n|max)] -- so the first member is the width and any further member
# can name nothing for them.

is(_mssql_column_type({ data_type => 'varchar', size => [64] }),
  'nvarchar(64)', 'varchar reads the length out of a [length] arrayref');

is(_mssql_column_type({ data_type => 'nvarchar', size => [64] }),
  'nvarchar(64)', 'nvarchar reads it too -- the branch, not one spelling');

is(_mssql_column_type({ data_type => 'nchar', size => [10] }),
  'nchar(10)', 'nchar reads it too');

is(_mssql_column_type({ data_type => 'binary', size => [16] }),
  'binary(16)', 'binary takes one scalar length as well -- same reading');

is(_mssql_column_type({ data_type => 'varbinary', size => [16] }),
  'varbinary(16)', 'varbinary too');

# A second member names nothing on a single-width type, so it is dropped rather
# than stringified. This is the shape the ticket calls most plausible: a column
# retyped from decimal/numeric to varchar whose size => [p, s] was left behind.
is(_mssql_column_type({ data_type => 'varchar', size => [10, 2] }),
  'nvarchar(10)', 'a surplus size member is dropped, not stringified');

# A size that names no width is no size at all, so it falls where an absent
# size falls. These pin the EQUIVALENCE (arrayref == the scalar case), not the
# merit of what the fallthrough emits: bare `nvarchar` is NVARCHAR(1) in
# T-SQL, which is what a sizeless column has always produced here.
is(_mssql_column_type({ data_type => 'varchar', size => [] }),
  'nvarchar', 'an empty size arrayref is no length at all -- as if absent');

is(_mssql_column_type({ data_type => 'varchar', size => [undef] }),
  'nvarchar', '[undef] likewise names no width');

# No-regression pin for the scalar shape the guard already handled.
is(_mssql_column_type({ data_type => 'varchar' }),
  'nvarchar', 'a sizeless varchar still emits no length');

# --- karr k28: the introspected (max) marker must come back out as (max) -----
#
# The guard above suppresses the length for a non-positive size, and about that
# it is right: MSSQL reports nvarchar(max)/varbinary(max) as
# CHARACTER_MAXIMUM_LENGTH = -1, and -1 is not a length. What followed it was
# wrong. The fallthrough emits the BARE type name, and a bare char-family type
# in a Transact-SQL column definition does not mean "unbounded" -- with n
# omitted it means LENGTH 1 (1 in a column or variable definition, 30 in
# CAST/CONVERT). So every introspected (max) column was recreated as a
# one-character column: valid SQL, wrong column, and nothing says so until the
# first INSERT truncates.
#
# Two pins from karr k27 stood here and asserted "a -1 emits no length". The
# observation was right and the conclusion was wrong -- "no length" is not "no
# limit" in this dialect. What k27 was actually pinning is that the arrayref
# shape means the same as the scalar shape, and that equivalence is kept below;
# only the value both of them render changed.
#
# WHICH types may say (max) is read off the T-SQL grammar, not chosen:
# varchar [ ( n | max ) ], nvarchar [ ( n | max ) ] and varbinary [ ( n | max ) ]
# have the unbounded form; the fixed-length char [ ( n ) ], nchar [ ( n ) ] and
# binary [ ( n ) ] do not. A -1 on one of those three therefore names nothing
# that exists in the dialect, and SQL Server's own catalog cannot produce it (a
# fixed-length column always reports its real n) -- so it is refused instead of
# quietly becoming the one-character column this ticket is about.

is(_mssql_column_type({ data_type => 'nvarchar', size => -1 }),
  'nvarchar(max)', 'the introspected -1 renders the unbounded form');

is(_mssql_column_type({ data_type => 'varchar', size => -1 }),
  'nvarchar(max)', 'varchar maps to nvarchar and keeps the (max)');

is(_mssql_column_type({ data_type => 'varbinary', size => -1 }),
  'varbinary(max)', 'varbinary has the unbounded form too');

is(_mssql_column_type({ data_type => 'NVARCHAR', size => -1 }),
  'NVARCHAR(max)', 'the branch is case-insensitive, so the (max) test has to be');

# karr k27's equivalence, restated at the value it now produces: wrapping the
# marker in an arrayref does not change what the marker means.
is(_mssql_column_type({ data_type => 'nvarchar', size => [-1] }),
  'nvarchar(max)', 'the marker inside an arrayref means the same thing');

# The fixed-length types have no (max) form. There is no correct rendering for
# a -1 on them -- bare would be a 1-character column, "(max)" would not parse --
# so the renderer refuses rather than picking one. Same choice, and the same
# lane, as DBIO::MSSQL::Adapter::to_native croaking on a base type it has no
# native for.
throws_ok { _mssql_column_type({ data_type => 'nchar', size => -1 }) }
  qr/nchar/, 'nchar has no (max) form -- the -1 is refused, not turned into NCHAR(1)';

throws_ok { _mssql_column_type({ data_type => 'binary', size => -1 }) }
  qr/binary/, 'binary likewise';

# Zero and the other negatives are neither the marker nor a length (T-SQL n
# starts at 1), so they name nothing either. They are deliberately NOT folded
# in with an absent size: the caller stated a width here, and a stated width
# that cannot exist is a defect, not a default.
throws_ok { _mssql_column_type({ data_type => 'nvarchar', size => 0 }) }
  qr/\bnvarchar\b/, 'a zero length names nothing -- refused, not silently NVARCHAR(1)';

throws_ok { _mssql_column_type({ data_type => 'nvarchar', size => -2 }) }
  qr/-2/, 'a negative that is not the marker is refused too';

# An ABSENT size is the one case that keeps falling through to the bare type:
# the caller prescribed nothing, so there is no stated intent to misrepresent
# and the dialect default may stand. [] and [undef] name no width, so they land
# here as well (karr k27), and so does a column info without the key at all.
is(_mssql_column_type({ data_type => 'nvarchar', size => undef }),
  'nvarchar', 'an explicit undef size is an absent size, not a bad one');

# The base-type path already spelled the unbounded types out (Adapter's
# text -> nvarchar(max), blob -> varbinary(max)). Pinning it here because the
# point of the fix is that the two paths now AGREE: what the adapter deploys is
# what introspection reads back and what the diff re-renders.
is(_mssql_column_type({ data_type => 'text' }),
  'nvarchar(max)', 'base type text still renders the unbounded string type');

is(_mssql_column_type({ data_type => 'blob' }),
  'varbinary(max)', 'base type blob still renders the unbounded binary type');

# --- end-to-end: both consumers of _mssql_column_type ------------------------
# Diff::Table is the deploy path -- it renders column info straight from
# introspection, so it is where a foreign loader's arrayref would arrive.
{
  my @ops = DBIO::MSSQL::Diff::Table->diff(
    {},
    { widget => { table_name => 'widget' } },
    { widget => [
        { column_name => 'id',    data_type => 'int',       is_pk => 1, not_null => 1 },
        { column_name => 'label', data_type => 'varchar',   size => [64] },
        { column_name => 'token', data_type => 'varbinary', size => [16] },
      ] },
  );
  my $sql = $ops[0]->as_sql;
  like($sql, qr/label nvarchar\(64\)/,
    'Diff::Table: an arrayref length reaches CREATE TABLE as a length');
  like($sql, qr/token varbinary\(16\)/,
    'Diff::Table: varbinary too');
  unlike($sql, qr/ARRAY\(0x/,
    'Diff::Table: no stringified reference anywhere in the statement');
}

# install_ddl is the desired-state path.
{
  package DDLSizeTest::MSSQL::Schema;
  use DBIO 'Schema', -ms;
}
{
  package DDLSizeTest::MSSQL::Schema::Result::Widget;
  use DBIO 'Core', -ms;

  __PACKAGE__->table('widget');
  __PACKAGE__->add_columns(
    id    => { data_type => 'int', is_auto_increment => 1 },
    label => { data_type => 'varchar',   size => [64] },
    token => { data_type => 'varbinary', size => [16] },
  );
  __PACKAGE__->set_primary_key('id');
}
DDLSizeTest::MSSQL::Schema->register_class(
  Widget => 'DDLSizeTest::MSSQL::Schema::Result::Widget');

my $ddl = DBIO::MSSQL::DDL->install_ddl('DDLSizeTest::MSSQL::Schema');
like($ddl, qr/label nvarchar\(64\)/,
  'install_ddl: varchar reads an arrayref length instead of stringifying it');
like($ddl, qr/token varbinary\(16\)/,
  'install_ddl: varbinary does too -- the whole branch, not just varchar');
unlike($ddl, qr/ARRAY\(0x/,
  'install_ddl: no stringified reference reaches the script');

# --- core karr k147 / ADR 0043: a missing is_nullable key means NOT NULL ------
# The columns above carry no is_nullable key at all. core's canonical_column
# turns an absent is_nullable into not_null=1, so the DDL renderer must emit
# NOT NULL for them too -- the old `defined && !` guard silently deployed them
# as nullable.
like($ddl, qr/label nvarchar\(64\) NOT NULL/,
  'install_ddl: a column with no is_nullable key deploys as NOT NULL');

# --- karr k28 end-to-end: the deploy path, which produces the -1 itself ------
# DBIO::MSSQL::Deploy introspects the live database and the temp database and
# diffs the two models, so BOTH sides carry the introspected shape --
# data_type 'nvarchar', size -1 for a (max) column, straight out of
# DBIO::MSSQL::Introspect::Columns (size = CHARACTER_MAXIMUM_LENGTH). A table
# present in the temp database and missing live is rendered from that model by
# Diff::Table, which is where the (max) columns of the template were losing
# their length.
{
  my @ops = DBIO::MSSQL::Diff::Table->diff(
    {},
    { doc => { table_name => 'doc' } },
    { doc => [
        { column_name => 'id',   data_type => 'int',       is_pk => 1, not_null => 1 },
        { column_name => 'body', data_type => 'nvarchar',  size => -1 },
        { column_name => 'blob', data_type => 'varbinary', size => -1 },
      ] },
  );
  my $sql = $ops[0]->as_sql;
  like($sql, qr/body nvarchar\(max\)/,
    'Diff::Table: an introspected (max) column is recreated as (max)');
  like($sql, qr/blob varbinary\(max\)/,
    'Diff::Table: varbinary(max) too');
  unlike($sql, qr/body nvarchar[^(]/,
    '... and never bare, which the server would read as a 1-character column');
}

# Diff::Column ADD is the same rendering on the incremental path.
{
  my @ops = DBIO::MSSQL::Diff::Column->diff(
    { doc => [ { column_name => 'id', data_type => 'int' } ] },
    { doc => [ { column_name => 'id',   data_type => 'int' },
               { column_name => 'body', data_type => 'nvarchar', size => -1 } ] },
    { doc => { table_name => 'doc' } },
    { doc => { table_name => 'doc' } },
  );
  is(scalar @ops, 1, 'Diff::Column: one column to add');
  like($ops[0]->as_sql, qr/ADD body nvarchar\(max\)/,
    'Diff::Column: ADD COLUMN renders the unbounded form as well');
}

# Why it matters past the single statement: the two models are compared field
# by field (DBIO::Diff::Compare::changed_column_fields reads `size` order-
# preservingly), so a (max) column that was deployed as a 1-character column
# reports size 1 against the target's -1 on every later run. Rendering (max)
# here is what closes the round trip -- the column is right the first time
# instead of drifting and being repaired later. (When it was written this note
# also recorded that Diff::Column could not repair it either, because ALTER
# COLUMN fired only on a differing data_type; that second gap is karr k30 and
# is fixed -- see t/57-diff-column-alter.t.)
is_deeply(
  [ changed_column_fields(
      { column_name => 'body', data_type => 'nvarchar', size => -1 },
      { column_name => 'body', data_type => 'nvarchar', size => -1 } ) ],
  [],
  'a (max) column introspected on both sides is not a change');

is_deeply(
  [ changed_column_fields(
      { column_name => 'body', data_type => 'nvarchar', size => 1 },
      { column_name => 'body', data_type => 'nvarchar', size => -1 } ) ],
  ['size'],
  'deployed as 1 character it differs from the target on every run -- the drift this fix prevents');

done_testing;
