use strict;
use warnings;
use Test::More;
use DBI;

eval { require DBD::SQLite; 1 } or plan skip_all => 'DBD::SQLite required';

use DBIO::SQLite::Introspect ();
use DBIO::SQLite::Storage ();
use DBIO::SQLite::DDL ();

# karr k29 -- what this test is for.
#
# DBIO::Introspect::Base folds primary-key membership into is_nullable: is_pk
# alone makes a column is_nullable => 0. It does that as a statement about
# DBIO's model (core ADR 0038), not as a claim about any engine, and it names
# a driver override of table_columns_info as the escape for an engine where
# the claim is false. SQLite is such an engine, and not marginally so: a
# PRIMARY KEY on a rowid table stores NULL, repeatedly, and the NULLs do not
# even collide with one another. SQLite's own documentation calls this a bug
# it kept on purpose (lang_createtable.html, "The PRIMARY KEY").
#
# What makes it worth a driver override rather than a footnote is where
# is_nullable goes: DBIO::Generate writes it into the regenerated result class
# and DBIO::SQLite::DDL turns is_nullable => 0 into NOT NULL. Report a key
# column full of NULLs as NOT NULL and the round trip does not merely describe
# the database inaccurately -- it emits a table that refuses the rows it was
# generated from. The last section of this file is that round trip.
#
# So the invariant every case below is checked against is not "is_nullable is
# still 1" but:
#
#     if the engine stored a NULL in this column when we asked it to,
#     introspection MUST report is_nullable => 1 for it -- and if the engine
#     refused or transformed the NULL, it MUST report 0.
#
# Each case establishes the left-hand side by running the INSERT, in this same
# run, against this same libsqlite. Nothing here freezes a return value.

my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '',
  { RaiseError => 0, PrintError => 0 });

my $storage = DBIO::SQLite::Storage->new;
$storage->_dbh($dbh);

# table, DDL, the column under test, an INSERT that offers NULL for it, and
# why the engine behaves the way it does.
my @cases = (
  { table => 'text_pk_rowid',
    ddl   => 'CREATE TABLE text_pk_rowid (name TEXT, note TEXT, PRIMARY KEY (name))',
    col   => 'name',
    ins   => q{INSERT INTO text_pk_rowid (name, note) VALUES (NULL, 'x')},
    why   => 'a non-INTEGER PRIMARY KEY on a rowid table -- SQLite stores the NULL' },

  { table => 'int_pk_alias',
    ddl   => 'CREATE TABLE int_pk_alias (id INTEGER PRIMARY KEY, note TEXT)',
    col   => 'id',
    ins   => q{INSERT INTO int_pk_alias (id, note) VALUES (NULL, 'x')},
    why   => 'the rowid alias -- NULL is the "assign a rowid" token, an integer is stored' },

  { table => 'int_pk_desc',
    ddl   => 'CREATE TABLE int_pk_desc (id INTEGER PRIMARY KEY DESC, note TEXT)',
    col   => 'id',
    ins   => q{INSERT INTO int_pk_desc (id, note) VALUES (NULL, 'x')},
    why   => 'DESC defeats the alias -- PRAGMA table_info still says type=INTEGER pk=1' },

  { table => 'int_short_pk',
    ddl   => 'CREATE TABLE int_short_pk (id INT PRIMARY KEY, note TEXT)',
    col   => 'id',
    ins   => q{INSERT INTO int_short_pk (id, note) VALUES (NULL, 'x')},
    why   => 'INT has INTEGER affinity but only the exact type INTEGER is the alias' },

  { table => 'composite_pk',
    ddl   => 'CREATE TABLE composite_pk (a TEXT, b TEXT, PRIMARY KEY (a, b))',
    col   => 'a',
    ins   => q{INSERT INTO composite_pk (a, b) VALUES (NULL, 'x')},
    why   => 'a composite key on a rowid table is an index like any other' },

  { table => 'without_rowid',
    ddl   => 'CREATE TABLE without_rowid (name TEXT PRIMARY KEY, note TEXT) WITHOUT ROWID',
    col   => 'name',
    ins   => q{INSERT INTO without_rowid (name, note) VALUES (NULL, 'x')},
    why   => 'WITHOUT ROWID keys are implicitly NOT NULL and PRAGMA reports notnull=1' },

  { table => 'pk_declared_not_null',
    ddl   => 'CREATE TABLE pk_declared_not_null (name TEXT NOT NULL PRIMARY KEY, note TEXT)',
    col   => 'name',
    ins   => q{INSERT INTO pk_declared_not_null (name, note) VALUES (NULL, 'x')},
    why   => 'the DDL declared the attribute, so the engine enforces it' },

  { table => 'plain_column',
    ddl   => 'CREATE TABLE plain_column (id INTEGER PRIMARY KEY, note TEXT)',
    col   => 'note',
    ins   => q{INSERT INTO plain_column (note) VALUES (NULL)},
    why   => 'an ordinary column, unaffected by any of this' },

  { table => 'plain_not_null',
    ddl   => 'CREATE TABLE plain_not_null (id INTEGER PRIMARY KEY, note TEXT NOT NULL)',
    col   => 'note',
    ins   => q{INSERT INTO plain_not_null (note) VALUES (NULL)},
    why   => 'an ordinary NOT NULL column' },
);

for my $c (@cases) {
  my ($table, $col) = ($c->{table}, $c->{col});
  $dbh->do($c->{ddl}) or die "DDL failed for $table: " . $dbh->errstr;

  # Ask the engine twice. Twice, because for a rowid-table PRIMARY KEY the
  # second NULL is the surprising part: it does not collide with the first.
  $dbh->do($c->{ins}) for 1 .. 2;

  my ($stored_nulls) = $dbh->selectrow_array(
    qq{SELECT count(*) FROM "$table" WHERE "$col" IS NULL});
  my $expected = $stored_nulls ? 1 : 0;

  is($stored_nulls, ($expected ? 2 : 0),
    "$table.$col: engine stored " . ($expected ? 'both NULLs' : 'no NULL') . " -- $c->{why}");

  my $intro = DBIO::SQLite::Introspect->new(dbh => $dbh);
  my $info  = $intro->table_columns_info($table);
  is($info->{$col}{is_nullable}, $expected,
    "$table.$col: introspect reports is_nullable => $expected, matching what the engine did with it");

  # The ticket's other half: the live PRAGMA path in the storage class and the
  # introspect path must not answer differently about the same column, or the
  # driver contradicts itself depending on which door the caller came through.
  my $live = $storage->_dbh_columns_info_for($dbh, $table);
  is($live->{$col}{is_nullable}, $expected,
    "$table.$col: live columns_info_for agrees with introspect");
}

# The key columns are still the key columns. Reporting a key as nullable is a
# statement about NULL, not a retraction of the key -- table_pk_info must be
# untouched, or this fix would have traded one wrong answer for another.
{
  my $intro = DBIO::SQLite::Introspect->new(dbh => $dbh);
  is_deeply($intro->table_pk_info('text_pk_rowid'), ['name'],
    'a nullable key column is still reported as the primary key');
  is_deeply($intro->table_pk_info('composite_pk'), ['a', 'b'],
    'composite key order is unaffected');
}

# ---------------------------------------------------------------------------
# The round trip this exists for: introspect a table whose key holds NULLs,
# regenerate a result class from exactly what introspection reported (this is
# what DBIO::Generate feeds to add_columns), emit DDL from it -- and then put
# the original rows into the result. Before karr k29 this section failed on
# "NOT NULL constraint failed", which is the whole point: the driver described
# the database in a way that could not hold the database.
# ---------------------------------------------------------------------------

my $intro = DBIO::SQLite::Introspect->new(dbh => $dbh);
my $cols  = $intro->table_columns_info('text_pk_rowid');
my $pk    = $intro->table_pk_info('text_pk_rowid');

{
  package RT29::Result::Thing;
  use base 'DBIO::Core';
  package RT29::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
}
RT29::Result::Thing->table('text_pk_rowid');
RT29::Result::Thing->add_columns(%$cols);

# Telling the truth here makes core complain, and that complaint is the point,
# not a side effect to be silenced: DBIO::ResultSource::set_primary_key warns
# that a key column which can be NULL breaks Row-object operations. It is
# right -- core ADR 0038 says as much -- and it is the first moment anyone
# learns that this foreign table cannot serve as a DBIO source. Under the old
# answer the warning never fired, because the driver had already told core the
# column was NOT NULL; the problem surfaced later as data that would not load.
my @warnings;
{
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };
  RT29::Result::Thing->set_primary_key(@$pk);
}
like(($warnings[0] // ''), qr/'name'.+is_nullable.+set to true/s,
  'core warns that a NULL-capable key column is unusable as a row identity')
  or diag explain \@warnings;

RT29::Schema->register_class(Thing => 'RT29::Result::Thing');

my $ddl = DBIO::SQLite::DDL->install_ddl(
  RT29::Schema->connect('dbi:SQLite:dbname=:memory:'));

unlike($ddl, qr/\bNOT\s+NULL\b/,
  'regenerated DDL declares no NOT NULL -- the source table declares none either')
  or diag $ddl;

my $redeployed = DBI->connect('dbi:SQLite:dbname=:memory:', '', '',
  { RaiseError => 0, PrintError => 0 });
$redeployed->do($_) or die $redeployed->errstr
  for grep { /\S/ } split /;\s*/, $ddl;

ok(defined $redeployed->do(q{INSERT INTO text_pk_rowid (name, note) VALUES (NULL, 'x')}),
  'the regenerated schema accepts the very row the introspected database holds')
  or diag $redeployed->errstr;

# And the loop closes: introspecting the redeployed table gives back what we
# introspected from the original. A round trip that only "runs" is not enough
# -- it has to arrive where it started.
is_deeply(
  DBIO::SQLite::Introspect->new(dbh => $redeployed)->table_columns_info('text_pk_rowid'),
  $cols,
  'introspecting the redeployed table reproduces the original column info');

done_testing;
