use strict;
use warnings;
use Test::More;
use Test::Exception;
use DBIO::Test;

use DBIO::Storage::DBI;
use DBIO::Sybase::Storage;
use DBIO::Sybase::Storage::ASE;

# karr k28 -- the two driver hooks core rolled out under karr k112, pinned
# offline. Both halves are here because the ticket covers both, but only one
# of them is an implementation:
#
#   _random_function  -- NEWID(). Core answers RANDOM(), which ASE has no such
#                        function for. The interesting part is not that the
#                        default is wrong but that the OBVIOUS fix, RAND(), is
#                        wrong too -- and silently so.
#   _explain_query    -- NOT implemented, and section 4 is why. ASE emits its
#                        query plan as server MESSAGES rather than as a
#                        rowset, which the seam has no outlet for. Blocked on
#                        core karr k140; see DBIO::Sybase::Storage::ASE's
#                        QUERY PLANS section.
#
# WHAT IS AND IS NOT PROVEN HERE. All of it is offline -- no DBI, no DSN, no
# server. It proves which function name this driver puts in the ORDER BY, that
# the name reaches the executed statement, and where the declaration lives. It
# cannot prove that ASE shuffles well when it gets there. The engine facts
# come from the SAP ASE 16.0 Reference Manual: Building Blocks (rand, rand2,
# newid) and its Transact-SQL Functions list.

# --- 1. the hook ------------------------------------------------------------

is( DBIO::Sybase::Storage::ASE->_random_function, 'NEWID()',
  'Sybase ASE spells the random function NEWID()' );

isnt( DBIO::Sybase::Storage::ASE->_random_function,
      DBIO::Storage::DBI->_random_function,
  '... and not core\'s RANDOM(), which is absent from ASE\'s Transact-SQL '
. 'function list altogether -- the inherited default died naming a function '
. 'the server could not find' );

# The reason NEWID() and not the word the engine's own manual leads with.
# ASE has rand(), but the rand2 entry defines itself by the contrast: "Unlike
# rand, it is computed for each returned row when it is used in the select
# list". So ORDER BY rand() gives every row the SAME sort key -- no ordering
# at all, and no error either. Pinned as a refusal of a specific wrong answer,
# because it is the one a later author will reach for: it is what MySQL
# answers, it is what the ticket guessed, and it is the only ASE function with
# "random" in its description.
isnt( DBIO::Sybase::Storage::ASE->_random_function, 'RAND()',
  'specifically NOT RAND(): ASE does not compute it per row, so ordering by '
. 'it would sort every row by one value -- a silent non-shuffle where the '
. 'broken default was at least loud' );

isnt( DBIO::Sybase::Storage::ASE->_random_function, 'RAND2()',
  '... and not RAND2() either, which IS per row but is documented out of this '
. 'position: "The behavior of rand2 in places other than the select list is '
. 'currently undefined", and DBIO::ResultSet::rand uses an order_by' );

is( DBIO::Sybase::Storage::ASE::NoBindVars->_random_function, 'NEWID()',
  'the NoBindVars class answers the same' )
  if eval { require DBIO::Sybase::Storage::ASE::NoBindVars; 1 };

# --- 2. it is an ASE fact, so it must not reach the MSSQL path --------------
#
# The same cross-repo hazard t/52 and t/53 pin for their hooks.
# DBIO::MSSQL::Storage::Sybase is @ISA (DBIO::Sybase::Storage,
# DBIO::MSSQL::Storage) under c3, so the shared sp_server_info dispatcher
# linearises AHEAD of the MSSQL half: anything declared on
# DBIO::Sybase::Storage answers for Microsoft SQL Server out of THIS
# distribution.
#
# This hook is the case where that is easiest to get wrong, because both
# engines happen to answer NEWID() and moving the declaration up would look
# like harmless deduplication. It is not: the two answers are a coincidence of
# two independently documented engine facts, and dbio-mssql owns its own.

isnt( DBIO::Sybase::Storage::ASE->can('_random_function'),
      DBIO::Storage::DBI->can('_random_function'),
  'the ASE class does override the hook' );

is( DBIO::Sybase::Storage->can('_random_function'),
    DBIO::Storage::DBI->can('_random_function'),
  '... and the shared DBD::Sybase dispatcher deliberately does not, even '
. 'though the answer would coincide today' );

SKIP: {
  skip 'DBIO::MSSQL not installed (not a dependency)', 2
    unless eval { require DBIO::MSSQL::Storage::Sybase; 1 };

  isnt( DBIO::MSSQL::Storage::Sybase->can('_random_function'),
        DBIO::Sybase::Storage::ASE->can('_random_function'),
    'MSSQL-over-DBD::Sybase does not resolve the hook to the ASE override' );

  is( DBIO::MSSQL::Storage::Sybase->can('_random_function'),
      DBIO::MSSQL::Storage->can('_random_function'),
    '... it resolves to whatever DBIO::MSSQL::Storage says, which is that '
  . 'distribution\'s answer about its own engine' );
}

# --- 3. end to end: the name reaches the executed statement -----------------

my $schema = DBIO::Test->init_schema(
  storage_type => 'DBIO::Sybase::Storage::ASE',
  no_deploy    => 1,
  quote_names  => 1,
);
my $storage = $schema->storage;

is( $storage->_random_function, 'NEWID()',
  'a live storage answers it too -- the hook is a static class fact, so no '
. 'connection was needed to get here' );

# as_query rather than ->all is what every other test in this repo asserts on,
# and it cannot be used for this one. ASE paginates through the GenericSubQ
# limit dialect, which refuses an ORDER BY that is not over a column of the
# main source -- and a random function never is. Stated as an assertion rather
# than a comment so that the day it stops throwing (a driver improvement, not
# a failure of this hook) somebody is told, and can assert the rendered SQL
# directly instead of going through the mock below.
throws_ok { $schema->resultset('Artist')->rand(3)->as_query }
  qr/Generic Subquery Limit/,
  'the un-executed rendering of $rs->rand throws on the limit dialect, not on '
. 'the random function -- which is why the assertion below runs the query';

$storage->mock(qr/\[artist\]/, [ [ 1, 'a', 0, undef ] ]);
$storage->reset_captured;

my @rows = $schema->resultset('Artist')->rand(3)->all;

my @captured = $storage->captured_queries;

is scalar @captured, 1, '$rs->rand issues exactly one statement';

is $captured[0]{sql}, join("\n",
  'SET ROWCOUNT 3',
  'SELECT [me].[artistid], [me].[name], [me].[rank], [me].[charfield]'
  . ' FROM [artist] [me]  ORDER BY NEWID()',
  'SET ROWCOUNT 0',
),
  '... with NEWID() in the ORDER BY, inside the SET ROWCOUNT wrap '
. '_prep_for_execute puts a rows-without-offset limit in on this engine';

unlike $captured[0]{sql}, qr/RANDOM\(\)|\bRAND2?\(\)/,
  '... and none of the three function names that would not have shuffled';

is_deeply $captured[0]{bind}, [],
  '... carrying no binds: the function is an order_by literal, not a value';

# --- 4. the other half of karr k28: _explain_query is IMPLEMENTED -----------
#
# The tripwire this section used to be fired: ASE now overrides _explain_query
# (and _execute_sth, the seam the plan arrives on) through the server-message
# seam core karr k140 built (ADR 0040 section 7). The real assertions moved to
# t/55-explain-query.t; what stays here is the cross-repo boundary -- the
# override lives on ::ASE, not on the shared DBD::Sybase dispatcher, where
# ASE's "set showplan on" would answer for Microsoft SQL Server, whose setting
# is spelled SET SHOWPLAN_ALL ON (dbio-mssql t/56 pins the far side).

ok !DBIO::Storage::DBI->can('_explain_sql'),
  'core has no _explain_sql -- ADR 0040 removed the string hook';

ok !DBIO::Sybase::Storage::ASE->can('_explain_sql'),
  '... and this driver carries no dead override of it';

isnt( DBIO::Sybase::Storage::ASE->can('_explain_query'),
      DBIO::Storage::DBI->can('_explain_query'),
  'Sybase ASE overrides _explain_query -- the server-message seam (core karr '
. 'k140) gives the plan an outlet; see t/55-explain-query.t' );

isnt( DBIO::Sybase::Storage::ASE->can('_execute_sth'),
      DBIO::Storage::DBI->can('_execute_sth'),
  '... and _execute_sth, the seam the plan arrives on' );

is( DBIO::Sybase::Storage->can('_explain_query'),
    DBIO::Storage::DBI->can('_explain_query'),
  '... and nothing was put on the shared dispatcher in the meantime, where '
. 'ASE\'s "set showplan on" would answer for Microsoft SQL Server, whose '
. 'setting is spelled SET SHOWPLAN_ALL ON (dbio-mssql t/56 pins the far side)' );

is( DBIO::Sybase::Storage->can('_execute_sth'),
    DBIO::Storage::DBI->can('_execute_sth'),
  '... nor for _execute_sth' );

done_testing;
