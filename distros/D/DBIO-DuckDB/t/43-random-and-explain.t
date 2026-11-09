#!/usr/bin/env perl
# t/43-random-and-explain.t — the two hooks core karr #112 put on the
# driver-determination list, answered for DuckDB: _random_function and — under
# the name ADR 0040 gave it — _explain_query. Neither is overridden here, and
# this file is why that is a decision rather than an omission (karr #11).
#
# Offline: in-memory DuckDB only, no DSN, no server, no DBIO_TEST_* anything.
#
# A NON-OVERRIDE CANNOT BE ASSERTED BY ITS VALUE ALONE. "_random_function is
# RANDOM()" stays green whether this driver inherits it, copies it into a
# private override, or core changes its mind about it. So each half pins three
# separate things: the value, the identity of the code that answers (core's,
# not a copy), and the engine fact the inheritance rests on — and the engine
# probes are built from the hook's own return value rather than from a literal,
# so a changed default is measured against this engine instead of being
# asserted twice.
#
# NAMING: karr #112 shipped the second hook as _explain_sql, a string. Core
# karr #138 / ADR 0040 REMOVED that — not deprecated, not aliased — and put
# _explain_query, which owns the whole operation and returns rows, in its slot.
# Part B asserts the old name is gone on both sides.
#
# Every engine fact below was measured on libduckdb v1.5.3 through DBD::DuckDB
# 0.16, and is re-measured on each run against whatever libduckdb is loaded.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use DBI;

use DBIO::DuckDB::Test;
use DBIO::DuckDB::Storage;
use DBIO::Storage::DBI;
use DBIO::Storage::Statistics;

my $schema  = DBIO::DuckDB::Test->init_schema;
my $storage = $schema->storage;
my $rs      = $schema->resultset('Artist');

note 'libduckdb ' . $storage->duckdb_version;

# ===========================================================================
# A. _random_function — inherited, and RANDOM() is what DuckDB has
# ===========================================================================

is(DBIO::DuckDB::Storage->_random_function, 'RANDOM()',
  '_random_function answers RANDOM() on this driver');

is(DBIO::DuckDB::Storage->can('_random_function'),
   DBIO::Storage::DBI->can('_random_function'),
  '... and it is core\'s own sub answering, not a private override that '
. 'happens to return the same string today');

my $func = $storage->_random_function;

# The engine half. Driven off $func: if core's default ever became a spelling
# DuckDB does not have, these do not merely disagree with a literal, they fail
# against the database — which is the fact this file is here to check.

my @vals;
lives_ok {
  @vals = @{ $storage->dbh->selectcol_arrayref("SELECT $func FROM range(8)") }
} "the engine accepts the spelling the hook returns -- SELECT $func";

is(scalar(keys %{ { map { ($_ => 1) } @vals } }), 8,
  "... and $func is evaluated PER ROW: eight rows, eight distinct values. A "
. 'query-constant random would order by the same number in every row, which '
. 'is a non-shuffle with no error anywhere');

# Twelve independent runs of an eight-row ORDER BY. All twelve landing on the
# same permutation has probability (1/8!)**11, so this is a stable assertion
# about the engine and not a coin flip.
my %orders;
$orders{ join ',',
  @{ $storage->dbh->selectcol_arrayref("SELECT range FROM range(8) ORDER BY $func") }
}++ for 1 .. 12;

cmp_ok(scalar keys %orders, '>', 1,
  "... and ORDER BY $func really permutes the result set");

# Which way the wrong choice would fail. DuckDB has no RAND() — the MySQL /
# MariaDB spelling, and the other half of the family's split — so inheriting
# is not "either would do": the alternative is an outage, and a loud one,
# which is core's stated reason for having no capability flag beside this hook.
throws_ok { $storage->dbh->do('SELECT RAND()') }
  qr/rand does not exist/i,
  'the other spelling in this family, RAND(), is not a DuckDB function at '
. 'all -- and it fails by naming itself, so the missing-override failure mode '
. 'here is loud rather than a silently wrong ordering';

# The caller-visible path: $rs->rand drops the hook's return value into an
# order_by literal.
my ($rand_sql) = @{ ${ $rs->rand(2)->as_query } };

like($rand_sql, qr/ORDER BY \Q$func\E/,
  'DBIO::ResultSet::rand puts exactly that spelling into the ORDER BY');

is(scalar(() = $rs->rand(2)->all), 2,
  '... and the statement runs on DuckDB, returning the asked-for row count');

# Three artists in the standard fixture; twenty draws all landing on the same
# one has probability 3 * (1/3)**20, about 3e-9.
my %picked;
for (1 .. 20) {
  my ($row) = $rs->rand(1)->all;
  $picked{ $row->artistid }++;
}

cmp_ok(scalar keys %picked, '>', 1,
  '... and successive $rs->rand(1) calls do not keep returning the same row');

# ===========================================================================
# B. _explain_query — inherited, and the bare EXPLAIN is right on DuckDB
# ===========================================================================

ok(!DBIO::Storage::DBI->can('_explain_sql'),
  'core has no _explain_sql -- ADR 0040 removed the string hook karr #112 '
. 'shipped, so the name this ticket was written against no longer exists');

ok(!DBIO::DuckDB::Storage->can('_explain_sql'),
  '... and this driver carries no dead override of it, which would claim a '
. 'behaviour nothing calls');

is(DBIO::DuckDB::Storage->can('_explain_query'),
   DBIO::Storage::DBI->can('_explain_query'),
  'the driver does not override _explain_query -- it takes core\'s whole base '
. 'operation, EXPLAIN through _execute_rendered');

my $filtered = $rs->search({ name => 'Caterwauler McCrae' });

my (undef, @explained_bind) = @{ ${ $filtered->as_query } };
is(scalar @explained_bind, 1,
  'the query about to be explained carries a bind value -- without one the '
. 'bind assertions below would pass vacuously');

my $plan = $filtered->explain;

is(ref $plan, 'ARRAY', 'explain returns rows');
is(scalar @$plan, 1, '... one row on DuckDB');
is(scalar @{ $plan->[0] }, 2, '... of two columns (explain_key, explain_value)');

is($plan->[0][0], 'physical_plan',
  '... keyed physical_plan: DuckDB answers a bare EXPLAIN with the plan it '
. 'would execute, so nothing has to be asked for to get one');

like($plan->[0][1], qr/\bartist\b/,
  '... and the plan names the table, so it describes this query rather than '
. 'echoing the statement');

like($plan->[0][1], qr/Filters/,
  '... including the pushed-down filter -- which also shows DuckDB PREPARES a '
. 'parameterised EXPLAIN, the thing core\'s default relies on when it hands '
. 'the query\'s bind list straight through');

unlike($schema->resultset('Artist')->explain->[0][1], qr/Filters/,
  'the unfiltered resultset plans without that filter -- the two plans differ, '
. 'so the plan tracks the query');

# --- the statement really travelled the storage's statement path ------------
#
# ADR 0040 section 3 requires it of every driver, and an inheriting driver has
# it for free -- but only for as long as it keeps inheriting. A future override
# reaching for $self->dbh would return an identical-looking plan and pass
# everything above, while dropping tracing (and therefore redact_bind_value,
# ADR 0025), dbh_do retry and, on a replicated storage, the read handler. The
# trace exists only because the EXPLAIN went through _execute_rendered.
{
  my @traced;

  $storage->debugobj(DBIO::Storage::Statistics->new);
  $storage->debugcb(sub { push @traced, $_[1] });
  $storage->debug(2);

  $filtered->explain;

  $storage->debug(0);
  $storage->debugcb(undef);

  is(scalar @traced, 1,
    'the EXPLAIN reached _query_start -- it went through _execute_rendered '
  . 'and not past the storage to $self->dbh, which would have traced nothing');

  like($traced[0] // '', qr/^EXPLAIN \s+ SELECT\b/x,
    '... and the statement DuckDB was handed is the bare prefix form');

  unlike($traced[0] // '', qr/\bANALYZE\b/i,
    '... with NO ANALYZE (see the measurement below for what that would cost)');

  like($traced[0] // '', qr/Caterwauler \s McCrae/x,
    '... carrying the query\'s own bind value, the caller\'s data, which is '
  . 'exactly where redact_bind_value must get its chance at it (ADR 0025); '
  . 'trace level 2 carries the values, level 1 the statement alone (core k401)');
}

# --- why the absent ANALYZE matters on DuckDB, measured --------------------
#
# DuckDB has EXPLAIN ANALYZE and it does not merely add timings: it RUNS the
# query. So "core's default is missing the interesting variant" is the wrong
# reading, and an override adding it would give $rs->explain side effects.
# Measured on a scratch database so the schema above stays untouched.

my $probe = DBI->connect('dbi:DuckDB:dbname=:memory:', '', '',
  { RaiseError => 1, PrintError => 0, AutoCommit => 1 });

$probe->do('CREATE SEQUENCE volatile_seq START 1');
$probe->do('CREATE TABLE three (id INTEGER)');
$probe->do('INSERT INTO three VALUES (1), (2), (3)');
$probe->do('CREATE TABLE written (a INTEGER)');

sub seq_last {
  return scalar $probe->selectrow_array(
    q{SELECT last_value FROM duckdb_sequences() WHERE sequence_name = 'volatile_seq'});
}

$probe->selectall_arrayref(q{EXPLAIN SELECT nextval('volatile_seq') FROM three});
is(seq_last(), undef,
  'a plain EXPLAIN does not run the query: the sequence in it was never '
. 'advanced');

$probe->do('EXPLAIN INSERT INTO written VALUES (1)');
is(scalar $probe->selectrow_array('SELECT count(*) FROM written'), 0,
  '... and an explained INSERT inserts nothing');

my $analyzed = $probe->selectall_arrayref(
  q{EXPLAIN ANALYZE SELECT nextval('volatile_seq') FROM three});

is($analyzed->[0][0], 'analyzed_plan',
  'EXPLAIN ANALYZE answers under a different key -- it is a different '
. 'operation, not a formatting option');

is(seq_last(), 3,
  '... because it EXECUTED the query: three rows, three nextval calls, the '
. 'sequence advanced');

$probe->do(q{EXPLAIN ANALYZE INSERT INTO written VALUES (1)});
is(scalar $probe->selectrow_array('SELECT count(*) FROM written'), 1,
  '... and an explained-and-analyzed INSERT really writes the row. This is '
. 'what core\'s ANALYZE-free default is protecting, and what an override '
. 'adding timings here would spend');

$probe->disconnect;

done_testing;
