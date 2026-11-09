#!/usr/bin/env perl
# t/45-numeric-bind-precision.t — karr #16: a numeric bind must reach DuckDB as
# the column's own type, not as a DOUBLE.
#
# Offline: in-memory DuckDB only, no DSN, no server, no DBIO_TEST_* anything.
#
# THE DEFECT THIS FILE EXISTS FOR IS SILENT. DBD::DuckDB decides the libduckdb
# bind function from the *value* when no DBI bind attribute is supplied, and its
# numeric branch is duckdb_bind_double — so 9007199254740993 is stored as
# 9007199254740992 and nothing is thrown. Two adjacent BIGINT keys collapse onto
# one double, which makes find() on such a key answer with the wrong row. That
# is data loss, not a cast: no error, no warning, wrong number.
#
# So every assertion below is a ROUND TRIP through the engine — value in, value
# read back out — and never "the method returned the constant I expected". A
# bind attribute that DBD::DuckDB ignored would satisfy the latter and lose the
# data anyway.
#
# WHY THE ATTRIBUTE IS A *STRING* TYPE (and why the integer family is left
# alone) is measured in part F. Both halves of that choice are guarded there,
# because both are load-bearing and neither is obvious from the code.
#
# Every engine fact below was measured on libduckdb v1.5.3 through DBD::DuckDB
# 0.16, and is re-measured on each run against whatever libduckdb is loaded.
# Where the loaded engine cannot carry a fact at all -- one type name in part H
# exists only from libduckdb 1.5 -- the run says so in place of measuring it,
# rather than dropping the name in silence.

use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::DuckDB::Test;
use DBIO::DuckDB::Storage;
use DBIO::DuckDB::DDL;

# --- result classes for the numeric types under test -----------------------
#
# The shared test schema has no column wider than an INTEGER, and this file is
# about binds rather than DDL, so the tables are created with plain SQL and the
# sources registered onto the connected schema instance.

{
  package DBIOTest::NumBind::Result::BigKey;
  use strict;
  use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table('nb_bigkey');
  __PACKAGE__->add_columns(
    id      => { data_type => 'bigint' },
    payload => { data_type => 'varchar', size => 32 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package DBIOTest::NumBind::Result::Wide;
  use strict;
  use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table('nb_wide');
  __PACKAGE__->add_columns(
    id  => { data_type => 'integer' },
    amt => { data_type => 'decimal', size => [ 38, 10 ] },
    huge => { data_type => 'hugeint',  is_nullable => 1 },
    ubig => { data_type => 'ubigint',  is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package DBIOTest::NumBind::Result::Counter;
  use strict;
  use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table('nb_counter');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer' },
    n  => { data_type => 'integer' },
  );
  __PACKAGE__->set_primary_key('id');
}

my $schema  = DBIO::DuckDB::Test->init_schema(no_populate => 1);
my $storage = $schema->storage;
my $dbh     = $storage->dbh;

note 'libduckdb ' . $storage->duckdb_version;

# nb_bigkey carries no PRIMARY KEY *constraint* although its result class
# declares the key: a constraint would turn the collapse of two keys onto one
# double into a duplicate-key error, i.e. into the loud failure this defect
# precisely is not. The corruption is what has to be visible here.
$dbh->do('CREATE TABLE nb_bigkey (id BIGINT, payload VARCHAR)');
$dbh->do('CREATE TABLE nb_wide (id INTEGER PRIMARY KEY, amt DECIMAL(38,10), '
       . 'huge HUGEINT, ubig UBIGINT)');
$dbh->do('CREATE TABLE nb_counter (id INTEGER PRIMARY KEY, n INTEGER)');

$schema->register_class(BigKey  => 'DBIOTest::NumBind::Result::BigKey');
$schema->register_class(Wide    => 'DBIOTest::NumBind::Result::Wide');
$schema->register_class(Counter => 'DBIOTest::NumBind::Result::Counter');

# 2**53 is the last integer a double can still count in steps of one. One above
# it is the smallest value that proves a double was involved.
my $EXACT   = '9007199254740993';    # 2^53 + 1
my $ROUNDED = '9007199254740992';    # what a double turns it into

# ===========================================================================
# A. The premise — DBD::DuckDB picks the bind function from the value
# ===========================================================================
#
# Pinned as a fact, not as background prose: if DBD::DuckDB ever types its own
# numeric binds, THIS is the test that goes red and says the override below has
# become removable. Nothing else in the file could tell us.

$dbh->do('CREATE TABLE nb_premise (v BIGINT)');
{
  my $sth = $dbh->prepare('INSERT INTO nb_premise VALUES (?)');
  $sth->bind_param(1, $EXACT);       # no attribute: DBD chooses
  $sth->execute;
}
is($dbh->selectrow_array('SELECT CAST(v AS VARCHAR) FROM nb_premise'), $ROUNDED,
  "premise: with NO bind attribute DBD::DuckDB still routes $EXACT through a "
. 'double and stores it as ' . $ROUNDED . ' -- silently. The driver has to '
. 'supply the type; if this line ever fails, upstream fixed it');

{
  my $sth = $dbh->prepare('SELECT typeof(?)');
  $sth->bind_param(1, 3);
  $sth->execute;
  is(($sth->fetchrow_array)[0], 'DOUBLE',
    '... and the reason is visible in the engine: an unattributed 3 arrives '
  . 'as DOUBLE');
}

# ===========================================================================
# B. BIGINT beyond 2^53 survives a round trip through a DBIO result
# ===========================================================================

my $bk = $schema->resultset('BigKey');

# Neighbour first, so that a scan which matches both rows reaches the WRONG one
# first and part C cannot pass by accident.
$bk->create({ id => $ROUNDED, payload => 'rounded' });
$bk->create({ id => $EXACT,   payload => 'exact'   });

is($dbh->selectrow_array(
    "SELECT CAST(id AS VARCHAR) FROM nb_bigkey WHERE payload = 'exact'"),
  $EXACT,
  "create() stores $EXACT unchanged in a BIGINT column");

is($dbh->selectrow_array('SELECT COUNT(DISTINCT id) FROM nb_bigkey'), 2,
  '... and the two neighbouring keys stay two distinct values -- through a '
. 'double they collapse onto one and the table silently holds a duplicate');

# ===========================================================================
# C. find() on such a key answers with the right row
# ===========================================================================
#
# The consequence that makes this a correctness bug rather than a storage
# detail: the WHERE side goes through the same bind. With a double both rows
# above match, and find() hands back whichever one the scan reached first.

my $found = $bk->find($EXACT);
ok($found, "find($EXACT) returns a row");
is($found && $found->payload, 'exact',
  "... and it is THE row keyed $EXACT, not its neighbour $ROUNDED");

is($found && "" . $found->id, $EXACT,
  '... and the key read back out of it is the key that went in');

is(scalar $bk->search({ id => $EXACT })->count, 1,
  "search on $EXACT matches exactly one row -- a double-widened comparison "
. 'matches both');

# ===========================================================================
# D. DECIMAL keeps the digits it was declared for
# ===========================================================================
#
# Same mechanism, different loss: a DECIMAL(38,10) carries far more significant
# digits than a double's ~15, so the fractional tail is what disappears.

my $AMOUNT = '12345678901234567.1234567891';

$schema->resultset('Wide')->create({ id => 1, amt => $AMOUNT });

is($dbh->selectrow_array('SELECT CAST(amt AS VARCHAR) FROM nb_wide WHERE id = 1'),
  $AMOUNT,
  "DECIMAL(38,10) keeps every digit of $AMOUNT -- a double rounds the tail "
. 'away without a word');

# ===========================================================================
# E. HUGEINT / UBIGINT past the int64 range
# ===========================================================================
#
# These fail loudly today (out-of-range for the destination type) rather than
# silently, but they fail: the value never reaches a column that was declared
# wide enough to hold it.

my $HUGE = '170141183460469231731687303715884105727';   # 2^127 - 1
my $UBIG = '18446744073709551615';                      # 2^64 - 1

lives_ok { $schema->resultset('Wide')->create({ id => 2, huge => $HUGE }) }
  'HUGEINT at 2^127-1 can be inserted at all';
is($dbh->selectrow_array('SELECT CAST(huge AS VARCHAR) FROM nb_wide WHERE id = 2'),
  $HUGE, '... and arrives exact');

lives_ok { $schema->resultset('Wide')->create({ id => 3, ubig => $UBIG }) }
  'UBIGINT at 2^64-1 can be inserted at all';
is($dbh->selectrow_array('SELECT CAST(ubig AS VARCHAR) FROM nb_wide WHERE id = 3'),
  $UBIG, '... and arrives exact');

# ===========================================================================
# F. The two halves of the design choice, each guarded
# ===========================================================================
#
# F1. DuckDB has no typed 64-bit-plus bind reachable through DBD::DuckDB's
#     bind_param: the only two branches are duckdb_bind_int64 (SQL_INTEGER) and
#     duckdb_bind_varchar (everything else, which DuckDB then casts to the
#     parameter's own type -- exactly, at any width). int64 cannot carry
#     UBIGINT/HUGEINT (measured: 2^127-1 arrives as -1, silently) and truncates
#     DECIMAL, so the wide types take the string route.
#
#     Its price: a parameter DuckDB cannot type from context arrives as
#     STRING_LITERAL, and a few operator overloads are then ambiguous.
#     Measured on 1.5.3: `bigint_col * ?` and `decimal_col * ?` raise a Binder
#     Error. LOUDLY -- which is why this trade was taken over an int64 bind
#     that would answer 'abc' with a stored 0.

throws_ok { $bk->create({ id => 'not-a-number', payload => 'junk' }) }
  qr/Conversion Error|Could not convert/i,
  'garbage in a BIGINT column still RAISES rather than being coerced to 0 -- '
. 'the int64 bind would have silently stored 0 here, trading one silent '
. 'corruption for another';

# F2. The integer family (INTEGER and narrower) is deliberately NOT switched:
#     every value it can hold is exact in a double already, so it has nothing
#     to gain, while `integer_col + ?` IS one of the ambiguous overloads
#     (+(INTEGER, STRING_LITERAL) collides with +(INTEGER, DATE)). Widening the
#     type list to "all numbers" breaks the counter-increment idiom below.

$schema->resultset('Counter')->create({ id => 1, n => 10 });
lives_ok {
  $schema->resultset('Counter')->search({ id => 1 })
         ->update({ n => \[ 'n + ?', [ n => 5 ] ] });
} 'literal-bind arithmetic on an INTEGER column still resolves';
is($dbh->selectrow_array('SELECT n FROM nb_counter WHERE id = 1'), 15,
  '... and computed the right number');

# ===========================================================================
# G. Free byproduct: the cast leaves the column side of the plan
# ===========================================================================
#
# An unattributed bind makes DuckDB widen the COLUMN to match the parameter --
# `CAST(id AS DOUBLE) = 3.0` -- and a cast on the column side disables zone-map
# pruning, which on a columnar engine is the whole point of a range scan. Once
# the parameter carries the column's own type there is nothing left to widen.

my $plan = join ' ',
  map { join ' ', map { defined $_ ? $_ : '' } @$_ }
  @{ $bk->search({ id => $EXACT })->explain };

# DuckDB renders the plan into a fixed-width box, so an expression can be split
# across lines mid-token. Strip the frame and collapse the padding before
# matching, or the absence of a pattern proves only that it got word-wrapped.
$plan =~ s/[^\x20-\x7e]/ /g;
$plan =~ s/\s+/ /g;

unlike($plan, qr/CAST\s*\(\s*id\s+AS\s+DOUBLE\s*\)/i,
  'the query plan no longer casts the BIGINT column to DOUBLE to meet the '
. 'parameter (zone-map pruning survives)')
  or diag $plan;

like($plan, qr/\Q$EXACT\E/,
  "... and the filter it does carry is the exact key $EXACT, not the double "
. 'the engine had been comparing against');

# ===========================================================================
# H. The type list is a list of NAMES, so it can be wrong in silence
# ===========================================================================
#
# A spelling that no column ever carries -- a typo, or a type this engine does
# not have -- costs nothing at runtime and does nothing at all: the value keeps
# going through a double and the loss stays. So each name is checked twice:
# that the method answers for it, and that it names a type this driver can
# actually build a column out of.

my %ANSWERED = (
  # canonical
  bigint => 1, ubigint => 1, hugeint => 1, uhugeint => 1, decimal => 1,
  numeric => 1, money => 1, varint => 1,
  # aliases DuckDB resolves onto the same types
  int8 => 1, int64 => 1, long => 1, bigserial => 1, uint64 => 1,
  int128 => 1, uint128 => 1, bignum => 1, dec => 1,
  # a double carries these exactly, so they are deliberately left alone
  integer => 0, int => 0, smallint => 0, tinyint => 0, serial => 0,
  uinteger => 0, usmallint => 0, utinyint => 0,
  boolean => 0, double => 0, float => 0, real => 0,
  date => 0, timestamp => 0,
  # text and binary are bound as what they are (karr k49): not a numeric
  # concern, but the same sniffing turned '01234' into a number
  varchar => 'text', blob => 'blob',
);

for my $type (sort keys %ANSWERED) {
  my $got = $storage->bind_attribute_by_data_type($type);
  if ($ANSWERED{$type} eq 'text') {
    is($got, DBI::SQL_VARCHAR(), "'$type' binds as text");
  }
  elsif ($ANSWERED{$type} eq 'blob') {
    is($got, DBI::SQL_BLOB(), "'$type' binds as a blob");
  }
  elsif ($ANSWERED{$type}) {
    is($got, DBI::SQL_BIGINT(), "'$type' binds through the string route");
  }
  else {
    is($got, undef, "'$type' is left on DBD::DuckDB's own choice");
  }
}

is($storage->bind_attribute_by_data_type('DECIMAL(38,10)'), DBI::SQL_BIGINT(),
  'the size suffix and the casing of an introspected type name are ignored');
is($storage->bind_attribute_by_data_type(undef), undef,
  'a column with no declared data_type is not an error');

# The other half: every name that answers has to be a type this driver can
# emit. Built through the driver's OWN mapping, since that is what decides
# what a data_type turns into in DDL.
#
# ONE OF THE NAMES IS NOT ON EVERY ENGINE. DuckDB grew BIGNUM in 1.5; on 1.3
# and 1.4 the CREATE below answers "Catalog Error: Type with name BIGNUM does
# not exist". That is a fact about the engine, not about this driver, so the
# name is left out of the probe there -- but out loud, naming the version that
# would measure it, because the header of this file promises every fact is
# re-measured against whatever libduckdb is loaded, and one that could not be
# is owed the reason.
#
# ONLY THIS PROBE IS GATED. The bind-attribute loop above stays version-
# independent on purpose: bind_attribute_by_data_type answers off a name list
# with no engine to ask, and on an engine without BIGNUM no column can ever
# carry that spelling, so the entry is inert there rather than wrong.
#
# AND WHEN THE VERSION CANNOT BE READ, MEASURE. duckdb_version answers DuckDB's
# own spelling, with a leading v ("v1.5.3" -- see t/46-server-version.t, where
# that v and core's normalised "1.5.3" are pinned apart), so the parse below
# takes the v as optional and stops after major.minor. Anything it cannot read
# is doubt -- and skipping on doubt is the wrong direction for this file: the
# defect part H guards IS silence, and an unmeasured name is precisely the dead
# list entry it exists to catch. Measuring an engine we failed to identify
# costs at worst one red line quoting that engine's own error, which names the
# problem and can be gated afterwards; skipping costs the measurement and says
# nothing. So the skip fires only for a version positively read as older.

my %ADDED_IN = ( bignum => [ 1, 5 ] );   # type name -> first libduckdb with it

my $engine_version = $storage->duckdb_version;
my ($engine_maj, $engine_min) = $engine_version =~ /\Av?([0-9]+)\.([0-9]+)/;
note "libduckdb answers '$engine_version', which is not the major.minor shape "
   . 'this gate reads -- measuring every name rather than skipping one unasked'
  unless defined $engine_maj;

my $ddl_ok = 0;
my @unbuildable;
my @unmeasured;
for my $type (grep { $ANSWERED{$_} } sort keys %ANSWERED) {
  my $needs = $ADDED_IN{$type};
  if ($needs && defined $engine_maj
      && ( $engine_maj <=> $needs->[0] || $engine_min <=> $needs->[1] ) < 0) {
    my $since = "$needs->[0].$needs->[1]";
    push @unmeasured, $type;
    note "NOT MEASURED: '$type' -- DuckDB has no such type before libduckdb "
       . "$since and this engine is $engine_version, so the CREATE would fail "
       . 'on the engine rather than tell us anything about the driver. It is '
       . "measured again as soon as the suite runs against $since or newer";
    next;
  }
  my $sql_type = DBIO::DuckDB::DDL::_duckdb_column_type({ data_type => $type });
  eval { $dbh->do("CREATE OR REPLACE TABLE nb_typeprobe (v $sql_type)"); 1 }
    ? $ddl_ok++
    : push @unbuildable, "$type -> $sql_type: " . ((split /\n/, ($dbh->errstr // $@))[0] // '?');
}
is_deeply(\@unbuildable, [],
  "all $ddl_ok listed type names build a real DuckDB column -- a name that "
. 'never matches a column would leave the loss in place and say nothing'
. (@unmeasured
   ? ' (not measurable on ' . $engine_version . ', left unchecked: '
     . join(', ', @unmeasured) . ')'
   : ''));

done_testing;
