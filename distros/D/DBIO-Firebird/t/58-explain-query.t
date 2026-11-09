use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Optional::Dependencies ();
use DBIO::Test;
use DBIO::Test::Schema;
use DBIO::Storage::DBI;
use DBIO::Firebird::Storage;
use DBIO::Firebird::Storage::InterBase;

# karr #17 / core ADR 0011 and ADR 0040 -- the two driver-spelling hooks this
# driver inherited, both of them wrong here, and wrong in different ways:
#
#   _random_function  -- core answers RANDOM(). Neither Firebird nor InterBase
#                        has such a function; both spell it RAND(). Loud on
#                        arrival, but only because the engine cannot resolve
#                        the name.
#   _explain_query    -- core issues "EXPLAIN <query>". Firebird has no EXPLAIN
#                        token at all (Appendix C of the 5.0 Language
#                        Reference, which lists every keyword reserved and
#                        non-reserved), so that is a parse error. And the
#                        spelling is the smaller half: there is NO STATEMENT to
#                        get a plan with on this engine. The plan is an
#                        attribute of the PREPARED statement
#                        (isc_dsql_sql_info / isc_info_sql_get_plan), so the
#                        query is prepared, nothing is executed, and the plan
#                        is read off the handle. That is the shape core karr
#                        #139 built _prepare_rendered for (ADR 0040 section 6),
#                        naming this engine.
#
# WHAT IS AND IS NOT PROVEN HERE. Everything above the SKIP block is offline --
# no DBI, no DSN, no server. It proves what this driver puts on the wire, that
# the one thing it does issue goes through the storage's statement path as a
# PREPARE and not as an execute, and that the plan the caller gets back is the
# handle's answer wrapped as ADR 0040 section 2 prescribes. It cannot prove
# that Firebird accepts RAND(), that RAND() is re-evaluated per row, or that
# ib_plan answers on a live handle. The first two come from the Firebird
# Language Reference and the engine's own tracker (sourced in the DESCRIPTION
# of DBIO::Firebird::Storage::Common); the third from the XS of both DBDs. The
# SKIP block at the end is where a server checks all three.

# The mock's statement handle carries the DBI methods every driver has, and
# ib_plan is not one of them: it is a private XSUB of DBD::Firebird and
# DBD::InterBase, reached through DBI's func(). Supplying it here is not
# scaffolding around the assertion, it IS one -- the driver only gets a plan
# out of this handle if it asks in the exact form the two DBDs offer. The call
# log below is what pins that form.
#
# WHY THE CODREF FORM (karr #22 / core #148). Core karr #141 gave FakeSth a
# func() of its own, answering undef since no engine stands behind the fake
# storage, and a glob override HERE used to be the only route to a plan -- but
# DBIO::Test loads the storage class lazily, from inside init_schema, so the
# override had to be installed before that load and the call had to prove it.
# core karr #148 turned DBIO::Test::Storage::mock_func into a public seam
# registering what func() should answer, with the coderef form giving the call
# log back here. The lazy-load trap is gone with it, so no explicit pre-load
# and no guard assertion are needed any more -- the registration in section 4
# is the test.
our @FUNC_CALLS;
our $FAKE_PLAN = "PLAN (ARTIST NATURAL)\n";

# --- 1. the string hook is gone on both sides -------------------------------
#
# ADR 0040 REMOVED _explain_sql rather than deprecating it, so the migration is
# not silently safe in either direction: an override left behind on this class
# would simply never be called again, and $rs->explain would go back to core's
# bare EXPLAIN with nothing to notice.

ok !DBIO::Storage::DBI->can('_explain_sql'),
  'core has no _explain_sql -- ADR 0040 removed the string hook outright';

ok !DBIO::Firebird::Storage->can('_explain_sql'),
  '... and this driver carries no dead override of it, which would be a hook '
. 'nobody calls claiming a behaviour the code no longer has';

# --- 2. _random_function ----------------------------------------------------
#
# Static class fact: string out, no $dbh, no version probe. The storage below
# is built from a dbi:Firebird: DSN and never connects. A schema always has a
# driver (core ADR 0067), and DBIO::Test::Schema is shared by the driver suites
# and keeps none in its class, so each connect here declares the storage of
# the DBD it names on a clone -- the answer is that driver's rather than the
# base one arrived at by accident.

{
  my $schema  = DBIO::Test::Schema->clone(storage_type => '+DBIO::Firebird::Storage')
    ->connect('dbi:Firebird:db=/nonexistent.fdb');
  my $storage = $schema->storage;

  is (
    $storage->_random_function,
    'RAND()',
    'the random-number function is RAND(). Core answers RANDOM(), which is '
  . 'right on PostgreSQL and SQLite and is not a function Firebird has at all '
  . '-- Appendix C of the 5.0 Language Reference has no RANDOM in any form, so '
  . 'the server has nothing to resolve the name to',
  );

  is (
    ref $storage,
    'DBIO::Firebird::Storage',
    '... answered by the declared storage, which stands as declared',
  );

  isnt (
    DBIO::Firebird::Storage->can('_random_function'),
    DBIO::Storage::DBI->can('_random_function'),
    '... and it is a real override, by coderef identity rather than by the '
  . 'inherited string happening to look right',
  );

  is (
    $storage->can('_random_function'),
    DBIO::Firebird::Storage::Common->can('_random_function'),
    '... declared on Storage::Common, because RAND() is a fact about the SQL '
  . 'both engines speak rather than about either DBD: the internal function '
  . 'since Firebird 2.1, and the ib_udf external function of the same name '
  . 'before that and on InterBase',
  );

  ok (
    ! $storage->connected,
    'none of the above opened a connection',
  );
}

{
  my $schema  = DBIO::Test::Schema
    ->clone(storage_type => '+DBIO::Firebird::Storage::InterBase')
    ->connect('dbi:InterBase:db=/nonexistent.gdb');
  my $storage = $schema->storage;

  is (
    $storage->_random_function,
    'RAND()',
    'the DBD::InterBase transport gets the same answer through '
  . 'Storage::Common -- which is the point of putting it there: the InterBase '
  . 'external function library is where ib_udf\'s rand() came from in the '
  . 'first place, and neither DBD can be left behind by an edit to the other',
  );

  is (
    ref $storage,
    'DBIO::Firebird::Storage::InterBase',
    '... from its own storage class, the one declared for DBD::InterBase',
  );

  ok (! $storage->connected, '... without connecting either');
}

# --- 3. what $rs->rand() actually builds ------------------------------------

{
  my $schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'DBIO::Firebird::Storage',
  );

  my ($sql, @bind) = @{ ${
    $schema->resultset('Artist')->search({ name => 'foo' })->rand(3)->as_query
  } };

  like (
    $sql,
    qr/ORDER BY RAND\(\)/,
    'rand() orders by the function the storage named',
  );

  unlike (
    $sql,
    qr/\bRANDOM\s*\(/,
    '... and nowhere by the RANDOM() core answers with by default',
  );

  # Not decoration: rand() adds `rows`, and on this engine that is FIRST rather
  # than LIMIT (DBIO::Firebird::SQLMaker). Unlike Oracle's ROWNUM dialect there
  # is no wrapping subquery at all here -- FIRST and the ORDER BY are clauses of
  # ONE select -- so the row count cannot end up applied to an unsorted
  # intermediate result. That is worth pinning rather than assuming, because it
  # is the difference between three random rows and three arbitrary rows in a
  # random order.
  like (
    $sql,
    qr/^\(SELECT FIRST \?.*ORDER BY RAND\(\)\)$/s,
    '... in the same single statement as the FIRST row count, with no '
  . 'limit-dialect subquery between the two',
  );

  is_deeply (
    [ map { ref $_ eq 'ARRAY' ? $_->[1] : $_ } @bind ],
    [ 3, 'foo' ],
    '... with the row count bound first, since FIRST stands before the WHERE '
  . 'clause in the statement',
  );
}

# --- 4. _explain_query: the operation with no statement in it ---------------
#
# The mock storage is the whole instrument here: _prepare_rendered and
# _execute_rendered are the ONLY points at which it sees a statement at all, so
# anything the override issues past those seams is captured nowhere, traced
# nowhere and redacted nowhere. That is what makes the assertions below a test
# of ADR 0040 section 3's rule and not just of one SQL string.

{
  my $schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'DBIO::Firebird::Storage',
  );
  my $storage = $schema->storage;

  # The instrument: register what the fake statement handle answers for
  # ib_plan. Core's FakeSth::func answers undef for every driver's private
  # function; without this registration the assertions below would report a
  # driver that cannot get a plan out of a handle that never offered one --
  # because core never offered one. The coderef form returns the call log, so
  # the "exactly once" assertion below has its own witness independent of the
  # return value.
  $storage->mock_func( ib_plan => sub {
    my ($sth, $name, @args) = @_;
    push @FUNC_CALLS, [ $name, @args ];
    return $FAKE_PLAN;
  });

  # ADR 0025: the redactor is an observable only the traced path can produce.
  # A driver reaching for $self->dbh would print the raw value -- or, far more
  # likely, print nothing at all, there being no trace.
  my $default_redactor = $storage->redact_bind_value;
  $storage->redact_bind_value(sub {
    my ($colname, $value) = @_;
    return defined $colname && $colname eq 'name' ? '[redacted]' : $value;
  });

  # Trace level 2 carries the bind values (core karr k401); level 1 is the
  # statement alone and the redactor has nothing to act on.
  my @traced;
  $storage->debugcb(sub { push @traced, $_[1] });
  $storage->debug(2);
  $storage->reset_captured;
  @FUNC_CALLS = ();

  my $plan = $schema->resultset('Artist')
    ->search({ name => 'secret' })->explain;

  $storage->debug(0);
  $storage->debugcb(undef);
  $storage->redact_bind_value($default_redactor);

  is_deeply (
    $plan,
    [ [ "PLAN (ARTIST NATURAL)\n" ] ],
    'explain answers with the handle\'s plan wrapped as ONE row of ONE column. '
  . 'Firebird\'s plan is a single opaque string and this driver does not '
  . 'invent columns to spread it over -- ADR 0040 section 2: the return type '
  . 'is rows, their contents were never portable',
  );

  is_deeply (
    \@FUNC_CALLS,
    [ [ 'ib_plan' ] ],
    '... obtained by asking the prepared handle for ib_plan through DBI\'s '
  . 'func(), exactly once. That is the form both DBDs offer it in '
  . '(DBD::Firebird 1.39 Firebird.xs, DBD::InterBase 0.48 InterBase.xs); the '
  . '$sth->{ib_plan} attribute core\'s POD spells exists in neither DBD\'s '
  . 'dbd_st_FETCH_attrib and would have answered undef',
  );

  my @captured = $storage->captured_queries;

  is (
    scalar @captured,
    1,
    'the storage layer saw the statement. ADR 0040 section 3 makes that a '
  . 'requirement of the contract with no engine-named exceptions, and this is '
  . 'where it is checkable: a statement issued past the seam is captured '
  . 'nowhere at all',
  );

  is (
    $captured[0]{op},
    'prepare',
    '... as a PREPARE and not as an execute. On this engine nothing runs: the '
  . 'plan is an attribute of the prepared statement, which is why core built '
  . '_prepare_rendered (ADR 0040 section 6) instead of writing Firebird an '
  . 'exception from the routing rule. op is the one observable that separates '
  . 'the two seams on a storage which never executes anything anyway',
  );

  like (
    $captured[0]{sql},
    qr/^SELECT /,
    'the statement prepared is the QUERY ITSELF -- there is no EXPLAIN '
  . 'spelling to get wrong here, and core\'s inherited prefix would have been '
  . 'a Token unknown parse error',
  );

  unlike (
    $captured[0]{sql},
    qr/EXPLAIN/i,
    '... with no trace of the word core would have prefixed',
  );

  unlike (
    $captured[0]{sql},
    qr/^\s*\(/,
    '... and with the parentheses as_query wraps its output in stripped off '
  . 'by core before the hook ever saw it',
  );

  is_deeply (
    [ map { ref $_ eq 'ARRAY' ? $_->[1] : $_ } @{ $captured[0]{bind} } ],
    [ 'secret' ],
    '... carrying the explained query\'s own bind values: preparing a '
  . 'statement with placeholders means supplying them, and these are the '
  . 'caller\'s real data, which is the whole reason the seam has to be the '
  . 'traced one',
  );

  # The trace is the second, independent witness, and the one carrying ADR
  # 0025. Neither line can exist without the storage's statement path.
  ok (
    scalar( grep { /^SELECT / } @traced ),
    'the statement reached the traced path -- _prepare_rendered runs '
  . '_query_start / _query_end exactly as _execute_rendered does',
  );

  ok (
    scalar( grep { /\[redacted\]/ } @traced ),
    'redact_bind_value (ADR 0025) got its chance at the explained query\'s '
  . 'bind values',
  );

  ok (
    ! scalar( grep { /secret/ } @traced ),
    '... and the raw value never reached the trace sink. This is the '
  . 'observable that a $self->dbh bypass cannot fake: it would have skipped '
  . 'the hook entirely',
  );
}

# --- 5. an empty plan is not a plan -----------------------------------------
#
# Both XSUBs read isc_info_sql_get_plan into a fixed 2048-byte buffer and
# return undef when the plan does not fit. Every prepared statement HAS a plan,
# so undef is the DBD failing, not the engine answering -- and [ [ undef ] ]
# would deliver that failure as a plan row the caller cannot tell apart from a
# real one.

{
  my $schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'DBIO::Firebird::Storage',
  );
  my $storage = $schema->storage;

  # Registered undef is an ANSWER (the PLAN_BUFFER_LEN case: the XSUB's fixed
  # 2048-byte buffer did not fit the plan), not a fall-through to core's
  # undef stub. mock_func is what carries that distinction -- the handle
  # answers undef because it was told to, so the driver sees a real plan row
  # and throws.
  $storage->mock_func( ib_plan => undef );

  throws_ok {
    $schema->resultset('Artist')->search({ name => 'foo' })->explain
  } qr/PLAN_BUFFER_LEN/,
    'a handle that answers undef throws, naming the DBD\'s plan buffer -- '
  . 'rather than handing back a row whose single column is empty';

  is (
    scalar( $storage->captured_queries ),
    1,
    '... after the statement was prepared, so the failure is about the plan '
  . 'and not about the query',
  );
}

# --- 6. the control: what a bypassing driver would look like ----------------
#
# Section 4 is worth nothing if its assertions cannot fail. This is the same
# hook implemented the way karr #112 found explain() implemented -- reaching
# for the handle instead of the seam. On this engine that is the tempting one
# to get wrong, because a prepare feels harmless. It ANSWERS, so no caller can
# tell; what it does not do is appear anywhere. Core cannot detect this from
# inside a driver (ADR 0040 section 3 says so), so the driver's own suite is
# where it has to be caught, and inverting the assertion is how.

{
  package T::FbBypass::Storage;
  use base 'DBIO::Firebird::Storage';

  sub _explain_query {
    my ($self, $sql, $bind) = @_;
    # THE ANTI-PATTERN -- deliberately wrong, do not copy into the driver.
    my $sth = $self->_dbh->prepare($sql);
    return [ [ $sth->func('ib_plan') ] ];
  }
}
$INC{'T/FbBypass/Storage.pm'} = __FILE__;

{
  my $schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'T::FbBypass::Storage',
  );
  my $storage = $schema->storage;

  my @traced;
  $storage->debugcb(sub { push @traced, $_[1] });
  $storage->debug(1);
  $storage->reset_captured;

  my $plan = $schema->resultset('Artist')
    ->search({ name => 'secret' })->explain;

  $storage->debug(0);
  $storage->debugcb(undef);

  is (
    ref $plan,
    'ARRAY',
    'a bypassing override still returns the right TYPE, and here even the '
  . 'right plan -- which is why no assertion about the return value could '
  . 'catch it',
  );

  is (
    scalar( $storage->captured_queries ),
    0,
    '... and yet the storage saw no statement at all, where the real override '
  . 'gave it one. That is section 4 inverted, and it is what makes those '
  . 'assertions a test rather than a decoration',
  );

  is (
    scalar @traced,
    0,
    '... nothing traced either, so redact_bind_value never ran on the bind '
  . 'values of the caller\'s own query (ADR 0025) -- one of the four things '
  . 'routing through the storage buys, together with dbh_do retry, NoBindVars '
  . 'interpolation and the read handler of a replicated storage',
  );
}

# --- 7. live round-trip -----------------------------------------------------
#
# Everything above pins what this driver DOES. Whether the engine and the DBD
# agree with it is the one thing an offline suite cannot say, and the claims
# below are the ones executed against a server (run against Firebird 5.0.4):
# RAND() from the Language Reference, its per-row evaluation from the engine's
# own tracker (CORE4362, and FirebirdSQL/firebird#7853 for the one release that
# folded it away), ib_plan from the XS of both DBDs. RDB$DATABASE supplies the
# query, so no fixture is needed.

SKIP: {
  my ($dsn, $user, $pass) =
    @ENV{map { "DBIO_TEST_FIREBIRD_${_}" } qw/DSN USER PASS/};

  skip 'Set $ENV{DBIO_TEST_FIREBIRD_DSN}, _USER and _PASS to run the live half', 5
    unless $dsn && $user && $pass;

  skip 'Test needs '
     . DBIO::Optional::Dependencies->req_missing_for('rdbms_firebird'), 5
    unless DBIO::Optional::Dependencies->req_ok_for('rdbms_firebird');

  my $live    = DBIO::Test::Schema->clone(storage_type => '+DBIO::Firebird::Storage')
    ->connect($dsn, $user, $pass);
  my $storage = $live->storage;

  my ($rand) = $storage->dbh->selectrow_array(
    'SELECT ' . $storage->_random_function . ' FROM RDB$DATABASE'
  );

  ok (
    defined $rand && $rand >= 0 && $rand < 1,
    'Firebird runs the random function and answers a number in [0,1)',
  );

  # The claim the offline half cannot make, and the one that has bitten another
  # driver in this family: an engine that evaluates the function once per
  # statement instead of once per row sorts nothing, silently. RDB$RELATIONS is
  # the system catalogue, so it has plenty of rows and needs no fixture.
  my ($distinct) = $storage->dbh->selectrow_array(
    'SELECT COUNT(DISTINCT r) FROM (SELECT FIRST 20 ' . $storage->_random_function
  . ' AS r FROM RDB$RELATIONS)'
  );

  cmp_ok (
    $distinct, '>', 1,
    '... and a different one per row, which is what makes ORDER BY it a '
  . 'shuffle rather than a no-op with the rows in their natural order',
  );

  my $rows = $storage->_explain_query('SELECT 1 FROM RDB$DATABASE', []);

  is (ref $rows, 'ARRAY', 'the prepare-only operation returns rows');

  is (
    scalar @$rows, 1,
    '... exactly one, of one column: the plan is a single opaque string here',
  );

  like (
    $rows->[0][0],
    qr/PLAN/i,
    '... and it is Firebird\'s legacy plan text, read off the prepared '
  . 'statement with ib_plan without the query ever running',
  );
}

done_testing;
