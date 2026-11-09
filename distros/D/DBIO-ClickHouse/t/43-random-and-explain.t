use strict;
use warnings;

use Test::More;

# The two driver hooks core k112 rolled out, answered for ClickHouse:
# _random_function (overridden -- rand()) and _explain_query (deliberately NOT
# overridden -- core's bare EXPLAIN is right here). Both halves are in one file
# because the interesting claim is the same one twice: what this engine needs
# is not what core's default assumes, EXCEPT where it is, and both of those are
# decisions that have to be pinned or they rot.
#
# Offline. _random_function is a static class fact by contract, and the EXPLAIN
# half runs against the fake storage, which is what makes the statement itself
# assertable without a server -- there is no in-memory ClickHouse, and
# DBD::MariaDB does not connect to a stock one anyway (karr k15).
#
# EVERY ENGINE FACT BELOW IS FROM THE CLICKHOUSE DOCUMENTATION, NOT FROM A
# RUNNING SERVER. Nothing here was verified live; see the POD sections
# RANDOM ORDERING and QUERY PLANS in DBIO::ClickHouse::Storage, which say so
# in the same words.

use DBIO::Test ':DiffSQL';
use DBIO::ClickHouse::Storage;
use DBIO::Storage::DBI ();

my $schema = DBIO::Test->init_schema(
  storage_type => 'DBIO::ClickHouse::Storage',
  no_deploy    => 1,
);

my $storage = $schema->storage;
my $artist  = $schema->resultset('Artist');
my $COLS    = '`me`.`artistid`, `me`.`name`, `me`.`rank`, `me`.`charfield`';

# ===========================================================================
# _random_function -- overridden
# ===========================================================================
#
# Read off DBIO::ClickHouse::Storage directly, not off the storage init_schema
# built: that one is a hybrid with core's fake storage in its MRO, so an answer
# arriving from the base class would be indistinguishable from ours.

is(DBIO::ClickHouse::Storage->_random_function, 'rand()',
  '_random_function is rand()');

isnt(DBIO::ClickHouse::Storage->can('_random_function'),
     DBIO::Storage::DBI->can('_random_function'),
  'the driver really overrides the hook rather than answering by accident');

# Core's default names a function this engine does not have. ClickHouse's
# random functions are rand/rand32, rand64, randCanonical, randConstant and
# the distribution family -- no `random`. So the inherited default is an
# outage, not a wrong result; the assertion records WHICH way it fails.
isnt(DBIO::ClickHouse::Storage->_random_function,
     DBIO::Storage::DBI->_random_function,
  "core's inherited RANDOM() is not a ClickHouse function -- the default "
. 'would throw an unknown-function error, not sort wrongly');

# The choice that could have been silently wrong, and the whole reason this
# hook needed checking rather than filling in: ClickHouse ALSO has
# randConstant(), documented as "a single random value that remains constant
# across all rows in the current query execution". Ordering by that is a
# non-shuffle -- same rows, same order, every time, no error anywhere. rand()
# is the per-row one (a regular function, and random numbers are the
# documented exception to constant folding). A future edit that "modernised"
# this hook onto the constant variant would produce a green suite everywhere
# else in this dist; here it does not.
unlike(DBIO::ClickHouse::Storage->_random_function, qr/randConstant/,
  '... and it is not randConstant(), which is per QUERY and would silently '
. 'stop shuffling');

# randCanonical() would also be defensible -- it is the Float64 in [0,1) that
# RANDOM() means elsewhere -- and is rejected only because the value is never
# observed (core drops this string into an order_by literal and nothing else)
# while it would put a 22.11 floor under $rs->rand. Pinned so the reasoning
# has to be revisited, not just re-typed, if someone switches.
unlike(DBIO::ClickHouse::Storage->_random_function, qr/randCanonical/,
  '... and not randCanonical(), whose Float64 nothing at the call site can '
. 'see and which would cost a 22.11 version floor');

# The other half: the string has to land in the statement as an ORDER BY
# expression. This is what would catch core changing how ResultSet::rand
# consumes the hook.
my $LIMIT = [ { sqlt_datatype => 'integer' } ];

is_same_sql_bind(
  $artist->rand(3)->as_query,
  "( SELECT $COLS FROM `artist` `me` ORDER BY rand() LIMIT ? )",
  [ [ $LIMIT->[0] => 3 ] ],
  '$rs->rand(3) orders by rand() and limits',
);

is_same_sql_bind(
  $artist->search_rs({ name => 'x' })->rand->as_query,
  "( SELECT $COLS FROM `artist` `me` WHERE ( `name` = ? ) ORDER BY rand() "
. 'LIMIT ? )',
  [ [ { dbic_colname => 'name', sqlt_datatype => 'varchar', sqlt_size => 100 }
      => 'x' ],
    [ $LIMIT->[0] => 1 ] ],
  '... and it composes with a WHERE clause and the default amount of 1',
);

# ===========================================================================
# _explain_query -- deliberately NOT overridden
# ===========================================================================
#
# ADR 0040 replaced the string hook _explain_sql with _explain_query($sql,
# \@bind), which owns the WHOLE operation and returns the plan as rows. It
# names ClickHouse as one of the engines core's base implementation fits. That
# claim was checked here (against the EXPLAIN documentation) and holds, so the
# right answer for this driver is to override NOTHING -- which is a decision
# with no code to point at, and therefore exactly the kind that needs a test.

is(DBIO::ClickHouse::Storage->can('_explain_query'),
   DBIO::Storage::DBI->can('_explain_query'),
  'the driver does NOT override _explain_query -- ClickHouse takes core\'s '
. 'base implementation, and this pins that as a decision rather than an '
. 'oversight');

# Why the base fits, stated once so the next reader does not have to re-derive
# it: ClickHouse's EXPLAIN takes an optional TYPE
# (AST | SYNTAX | QUERY TREE | PLAN | PIPELINE | ANALYZE | ESTIMATE |
# TABLE OVERRIDE), and omitting it means PLAN -- the query execution plan, one
# String row per plan line in a single column named `explain`. So all four of
# ADR 0040's assumptions hold: ONE statement, EXECUTED with the query's own
# binds, RETURNING rows, and those rows ARE the plan.
#
# The plan rows below are shaped like real ClickHouse output. Their contents
# are engine-specific by ADR 0040 section 2 and nothing asserts on them beyond
# "they came back", which is the promise $rs->explain actually makes.
my @PLAN = (
  ['Expression ((Project names + Projection))'],
  ['  Filter ((WHERE + Change column names to column identifiers))'],
  ['    ReadFromMergeTree (default.artist)'],
);

$storage->mock(qr/^EXPLAIN /, [ @PLAN ]);

my $explained = $artist->search_rs({ name => 'Caterwauler McCrae' })->explain;

is_deeply($explained, [ @PLAN ],
  '$rs->explain hands back the plan as an arrayref of row arrayrefs');

my @captured = $storage->captured_queries;

is(scalar @captured, 1,
  'obtaining the plan is exactly ONE statement on this engine -- no session '
. 'setting to set, no second query to read a plan table');

like($captured[0]{sql}, qr/^EXPLAIN \s+ SELECT \s/x,
  'and it is a BARE EXPLAIN: no type token, because on ClickHouse the type '
. 'you get by omitting it is PLAN -- the one type that answers what '
. '$rs->explain promises');

# The negative half of the same claim. Each of these would be accepted by the
# engine and would answer a different question -- AST/SYNTAX dump the parsed
# query, PIPELINE the processor graph, ESTIMATE a row/mark/part count,
# ANALYZE actually RUNS the query. A future override reaching for one of them
# has to delete this line to get a green suite.
unlike($captured[0]{sql},
  qr/^EXPLAIN \s+ (?:AST|SYNTAX|QUERY \s+ TREE|PIPELINE|ANALYZE|ESTIMATE|TABLE)\b/xi,
  '... and specifically not one of the other EXPLAIN types, which answer '
. 'other questions (ANALYZE would even run the query)');

is_deeply([ map { $_->[1] } @{ $captured[0]{bind} } ],
  [ 'Caterwauler McCrae' ],
  'the explained query keeps its own bind values -- they travel as the '
. '[ \\%attrs, $value ] pairs the statement path takes, unwrapped by nobody');

# ADR 0040 section 3 makes routing through the storage's statement path a
# contract requirement with no engine-named exceptions, and the fake storage
# is where core said a driver can assert it offline: _execute_rendered is the
# ONLY point at which a statement is recorded here at all. Inheriting the base
# satisfies that by construction -- which is precisely what this assertion is
# for, because the moment someone adds an override reaching for $self->dbh,
# the count above drops to zero and the plan still comes back from the real
# server. It cannot be caught by looking at the return value.
is($captured[0]{op}, 'select',
  '... and the statement went through _execute_rendered (it was captured at '
. 'all), which is what a $self->dbh bypass would silently lose: tracing and '
. 'therefore redact_bind_value, dbh_do retry, NoBindVars interpolation, and '
. 'the read handler on a replicated storage');

done_testing;
