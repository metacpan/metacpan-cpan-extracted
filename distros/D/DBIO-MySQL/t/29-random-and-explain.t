use strict;
use warnings;

use Test::More;

use DBIO::Test;
use DBIO::Storage::DBI;
use DBIO::MySQL::Storage;
use DBIO::MySQL::Storage::MariaDB;

# karr #33 / core karr #112 + ADR 0040 -- the two ResultSet convenience hooks
# this driver has to answer for: _random_function and _explain_query.
#
# FULLY OFFLINE. No DBI, no DSN, no server: every statement asserted below is
# one the mock storage captured instead of executing.
#
# What this file is for is NOT "RAND() renders as the string RAND()". Both
# hooks have a failure mode that is silent, and each half pins the one that
# applies:
#
#   * _random_function: a function the engine computes ONCE per statement gives
#     every row the same sort key, so ORDER BY <it> is not a shuffle and
#     nothing says so. (That is Sybase ASE's rand(), dbio-sybase karr #28.)
#     MySQL and MariaDB both document RAND() as evaluated per row -- see the
#     "Random ordering" POD section of DBIO::MySQL::Storage for the citations.
#
#   * _explain_query: ADR 0040 REMOVED the old _explain_sql string hook. A
#     driver that kept an override of it keeps a sub that looks like it decides
#     the statement while core no longer calls it at all -- dead code that
#     reads as live. This driver had exactly that, and its removal is half of
#     this ticket; the other half is that the non-override of _explain_query is
#     a decision, asserted by identity with core's method.

# --- 1. RAND(), on the class that owns the fact ---------------------------

is( DBIO::MySQL::Storage->_random_function, 'RAND()',
  'the random function is RAND() -- core RANDOM() exists on neither product' );

isnt( DBIO::MySQL::Storage->_random_function,
      DBIO::Storage::DBI->_random_function,
  '... which is not what core answers, so the override is load-bearing' );

# The spelling is shared by both server products AND both DBD drivers, so it is
# declared once on the class they all reach and inherited, not re-declared on
# the DBD::MariaDB binding (karr k28 / this dist's ADR 0001: that subclass answers "which
# DBD", never "which engine"). Identity, not equality: a second declaration
# that happens to say RAND() today is still a place where the two can drift.
is( DBIO::MySQL::Storage::MariaDB->can('_random_function'),
    DBIO::MySQL::Storage->can('_random_function'),
  'the DBD::MariaDB subclass inherits it instead of re-declaring it' );

# --- 2. what $rs->rand actually puts on the wire ---------------------------

{
  my $schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'DBIO::MySQL::Storage',
  );
  my $storage = $schema->storage;
  $storage->reset_captured;

  $schema->resultset('Artist')->rand(3)->all;

  my @q = $storage->captured_queries;
  is scalar @q, 1, '$rs->rand issues exactly one statement';

  like $q[0]{sql}, qr/ORDER BY RAND\(\)/,
    '... ordering by RAND(), which both products evaluate per row';

  # The LIMIT is what makes the ordering matter: rand(3) takes the first three
  # rows of the shuffled set, so an ordering that is not per row would return
  # the same three rows every time without erroring.
  like $q[0]{sql}, qr/ORDER BY RAND\(\) LIMIT \?/,
    '... and taking the first N of it, MySQL LimitXY style';

  unlike $q[0]{sql}, qr/\bRANDOM\(\)/,
    '... with no trace of the inherited RANDOM() either product would reject';
}

# --- 3. the removed string hook is gone on both sides ----------------------
#
# Pinned on core AND on both driver classes. A reappearance on core would mean
# the ADR 0040 removal was reverted; on a driver class it would mean somebody
# wrote an override that is never called.

ok !DBIO::Storage::DBI->can('_explain_sql'),
  'core has no _explain_sql -- ADR 0040 removed the string hook';

ok !DBIO::MySQL::Storage->can('_explain_sql'),
  '... and this driver carries no dead override of it (karr #33)';

ok !DBIO::MySQL::Storage::MariaDB->can('_explain_sql'),
  '... nor does the DBD::MariaDB subclass';

# --- 4. and the plan operation is core's, taken unchanged ------------------
#
# Same shape as the _exists_value_sql assertion in t/27: a non-override is a
# decision, and identity is how it is asserted. A private override producing
# the same statement today would still be an undocumented divergence -- and it
# is exactly where an executing EXPLAIN ANALYZE / MariaDB ANALYZE could enter.

is( DBIO::MySQL::Storage->can('_explain_query'),
    DBIO::Storage::DBI->can('_explain_query'),
  'the driver does not override _explain_query -- it takes the base operation' );

is( DBIO::MySQL::Storage::MariaDB->can('_explain_query'),
    DBIO::Storage::DBI->can('_explain_query'),
  '... and neither does the DBD::MariaDB subclass' );

# --- 5. the statement a MySQL resultset actually issues for a plan ---------

for my $case (
  [ 'DBIO::MySQL::Storage',          'through DBD::mysql'   ],
  [ 'DBIO::MySQL::Storage::MariaDB', 'through DBD::MariaDB' ],
) {
  my ($storage_type, $label) = @$case;

  my $schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => $storage_type,
  );
  my $storage = $schema->storage;
  my $rs = $schema->resultset('Artist')->search({ name => 'foo', rank => 13 });

  # one row of MySQL's / MariaDB's tabular plan output
  $storage->mock(qr/^EXPLAIN /, [ [ 1, 'SIMPLE', 'artist', 'ALL', undef, undef, 3, 'Using where' ] ]);
  $storage->reset_captured;

  my $plan = $rs->explain;

  is_deeply $plan,
    [ [ 1, 'SIMPLE', 'artist', 'ALL', undef, undef, 3, 'Using where' ] ],
    "explain returns the plan rows the statement produced ($label)";

  my @q = $storage->captured_queries;
  is scalar @q, 1, "... having issued exactly one statement ($label)";

  like $q[0]{sql}, qr/^EXPLAIN SELECT /,
    "... a plain EXPLAIN of the resultset's SELECT ($label)";

  # THE negative of this half. MySQL spells the executing form EXPLAIN ANALYZE
  # (8.0.18+), MariaDB spells it ANALYZE <statement>; either one RUNS the query
  # being explained. Asked in every spelling, because the point is the side
  # effect, not a particular word.
  unlike $q[0]{sql}, qr/\bANALY[SZ]E\b/i,
    "... which does NOT execute the query it plans ($label)";

  unlike $q[0]{sql}, qr/^\s*\(/,
    "... with the parens as_query wraps its output in stripped off ($label)";

  # The binds are the proof the operation went down the storage's statement
  # path at all: the mock captures nothing else, so a hook reaching for
  # $self->dbh would leave this empty (ADR 0040's routing rule, which this
  # driver keeps by not overriding).
  is_deeply
    [ map { ref $_ eq 'ARRAY' ? $_->[1] : $_ } @{ $q[0]{bind} } ],
    [ 'foo', 13 ],
    "... and the query's bind values reached it through _execute_rendered ($label)";

  # Backticks, i.e. the statement really was rendered by this driver's maker
  # and not by a bare core storage that happened to answer the same hook.
  like $q[0]{sql}, qr/`artist`/,
    "... rendered with MySQL quoting ($label)";
}

done_testing;
