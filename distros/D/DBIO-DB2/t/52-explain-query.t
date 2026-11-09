use strict;
use warnings;
use Test::More;

use DBIO::Optional::Dependencies ();
use DBIO::Test;
use DBIO::Test::Schema;
use DBIO::Storage::DBI;
use DBIO::DB2::Storage;

# karr k22 / core ADR 0011 and ADR 0040 -- the two driver-spelling hooks this
# driver inherited, pinned offline. Neither inherited answer is usable here:
#
#   _random_function  -- core answers RANDOM(), which the Db2 LUW SQL
#                        Reference documents nowhere. RAND() is the SYSFUN
#                        function it does document.
#   _explain_query    -- core's inherited operation is a bare EXPLAIN. DB2's
#                        statement is EXPLAIN PLAN SELECTION FOR, and it
#                        ANSWERS WITH NOTHING: it writes the plan into the
#                        EXPLAIN_* tables, so the plan is a SECOND statement.
#                        That is the shape ADR 0040 widened the seam from a
#                        string to a method for, naming this engine.
#
# WHAT IS AND IS NOT PROVEN HERE. Everything below is offline -- no DBI, no
# DSN, no server. It proves what this driver puts on the wire, that both
# statements of the two-statement operation go through the storage's statement
# path, and that the plan the caller gets back is the second statement's rows.
# It cannot prove that DB2 accepts any of it: no live server was available, and
# every spelling comes from the Db2 11.5 SQL Reference (topics: EXPLAIN
# statement, Explain tables, EXPLAIN_OPERATOR table, RAND (SYSFUN schema)).
# The SKIP block at the end is where that half gets checked.

# --- 1. the string hook is gone on both sides -------------------------------
#
# ADR 0040 REMOVED _explain_sql rather than deprecating it, so the migration is
# not silently safe in either direction: an override left behind on this class
# would simply never be called again, and $rs->explain would go back to core's
# bare EXPLAIN with nothing to notice.

ok !DBIO::Storage::DBI->can('_explain_sql'),
  'core has no _explain_sql -- ADR 0040 removed the string hook outright';

ok !DBIO::DB2::Storage->can('_explain_sql'),
  '... and this driver carries no dead override of it, which would be a hook '
. 'nobody calls claiming a behaviour the code no longer has';

# --- 2. _random_function ----------------------------------------------------
#
# Static class fact: string out, no $dbh, no version probe. The storage below
# never connects. It is the DB2 storage because the schema declares it:
# DBIO::Test::Schema is shared by every driver's suite and keeps no driver in
# its class (core ADR 0067), so this file declares DB2 on a clone, and the
# answer is this driver's rather than the base one arrived at by accident.

sub db2_schema {
  my $schema = DBIO::Test::Schema->clone;
  $schema->storage_type('+DBIO::DB2::Storage');
  return $schema->connection(@_);
}

{
  my $schema  = db2_schema('dbi:DB2:DATABASE=nonexistent');
  my $storage = $schema->storage;

  is (
    $storage->_random_function,
    'RAND()',
    'the random-number function is RAND(). Core answers RANDOM(), which is '
  . 'right on PostgreSQL and SQLite and which the Db2 LUW SQL Reference does '
  . 'not document at all, so the name resolves to no routine (SQL0440N)',
  );

  like (
    $storage->_random_function,
    qr/\(\)$/,
    '... WITH parentheses, unlike Oracle\'s DBMS_RANDOM.VALUE: this is an '
  . 'ordinary scalar function and its zero-argument form is still an '
  . 'invocation',
  );

  unlike (
    $storage->_random_function,
    qr/\(\s*\d/,
    '... and with no seed: a seed makes the sequence repeat per query (SQL '
  . 'Reference, RAND), which is a repeatable order rather than a shuffle',
  );

  is (
    ref $storage,
    'DBIO::DB2::Storage',
    '... answered by the DB2 storage the schema declared (core ADR 0067)',
  );

  isnt (
    DBIO::DB2::Storage->can('_random_function'),
    DBIO::Storage::DBI->can('_random_function'),
    '... and it is a real override, by coderef identity rather than by the '
  . 'inherited string happening to look right',
  );

  is (
    $storage->can('_explain_query'),
    DBIO::DB2::Storage->can('_explain_query'),
    'the same never-connected storage already resolves _explain_query to this '
  . 'driver\'s operation too (ADR 0040 section 5: the driver has to be known '
  . 'BEFORE its explain is chosen, not as a side effect of the first statement '
  . 'the base implementation would have run -- and declared on the schema, it '
  . 'is known from the moment the storage is built, core ADR 0067)',
  );

  isnt (
    DBIO::DB2::Storage->can('_explain_query'),
    DBIO::Storage::DBI->can('_explain_query'),
    '... and that operation is this driver\'s, not core\'s bare EXPLAIN',
  );

  ok (
    ! $storage->connected,
    'none of the above opened a connection',
  );
}

# --- 3. what $rs->rand() actually builds ------------------------------------

{
  my $schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'DBIO::DB2::Storage',
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

  # Not decoration: rand() adds `rows`, and this driver's limit dialect with no
  # offset is FETCH FIRST (ADR 0003). The sort has to be applied BEFORE the
  # row limit -- three rows off the top of a randomly ordered result, not three
  # arbitrary rows put in a random order.
  like (
    $sql,
    qr/ORDER BY RAND\(\)\s+FETCH FIRST 3 ROWS ONLY/,
    '... in the same select as the FETCH FIRST this driver limits with, and '
  . 'ahead of it, which is what makes it three RANDOM rows instead of three '
  . 'arbitrary ones in random order',
  );

  is_deeply (
    [ map { $_->[1] } @bind ],
    [ 'foo' ],
    '... with the search condition as the only bind: FETCH FIRST takes the '
  . 'row count as a literal, so nothing else joins the bind list',
  );
}

# --- 4. _explain_query: the two-statement operation -------------------------
#
# The mock storage is the whole instrument here: _execute_rendered is the ONLY
# point at which it sees a statement at all, so anything the override issues
# past the seam is captured nowhere, traced nowhere and redacted nowhere. That
# is what makes the assertions below a test of ADR 0040 section 3's rule and
# not just of the two SQL strings.

{
  my $schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'DBIO::DB2::Storage',
  );
  my $storage = $schema->storage;

  # Only the SECOND statement answers. The first one is mocked by nobody on
  # purpose: EXPLAIN PLAN SELECTION FOR returns no rows on the engine either,
  # and an implementation that tried to read its plan out of the first
  # statement would come back empty here exactly as it would there.
  $storage->mock(qr/EXPLAIN_OPERATOR/, [
    [ 1, 'RETURN', 25.4, 2, 123456 ],
    [ 2, 'FETCH',  25.4, 2, 123456 ],
    [ 3, 'IXSCAN', 13.1, 1,  61234 ],
  ]);

  # ADR 0025: the redactor is an observable only the traced path can produce.
  # A driver reaching for $self->dbh would print the raw value -- or, far more
  # likely, print nothing at all, there being no trace.
  my $default_redactor = $storage->redact_bind_value;
  $storage->redact_bind_value(sub {
    my ($colname, $value) = @_;
    return defined $colname && $colname eq 'name' ? '[redacted]' : $value;
  });

  my (@traced, @caching_while_running);
  $storage->debugcb(sub {
    push @traced, $_[1];
    # Read at the moment a statement is on the wire, which is the only moment
    # the localised flag is observable from outside.
    push @caching_while_running, $storage->disable_sth_caching;
  });
  $storage->debug(2);   # binds are traced from level 2 (core k401)
  $storage->reset_captured;

  my $plan = $schema->resultset('Artist')
    ->search({ name => 'secret' })->explain;

  $storage->debug(0);
  $storage->debugcb(undef);
  $storage->redact_bind_value($default_redactor);

  is_deeply (
    $plan->[0],
    [ 1, 'RETURN', 25.4, 2, 123456 ],
    'explain answers with the rows of the SECOND statement -- the first one '
  . 'has no plan in it to return, which is the whole reason this hook is a '
  . 'method and not a string',
  );

  is (
    scalar @$plan,
    3,
    '... all of them: one row per plan operator, passed through without '
  . 'inventing columns or folding EXPLAIN_STREAM\'s tree edges in',
  );

  my @captured = $storage->captured_queries;

  is (
    scalar @captured,
    2,
    'BOTH statements were seen by the storage layer. ADR 0040 section 3 makes '
  . 'that a requirement of the contract with no engine-named exceptions, and '
  . 'this is where it is checkable: a statement issued past _execute_rendered '
  . 'is captured nowhere at all',
  );

  like (
    $captured[0]{sql},
    qr/^EXPLAIN PLAN SELECTION FOR SELECT /,
    'first statement: EXPLAIN PLAN SELECTION FOR, not the bare EXPLAIN core '
  . 'inherits here. PLAN SELECTION is LUW\'s own spelling -- the bare PLAN is '
  . 'documented only as syntax toleration for z/OS statements',
  );

  unlike (
    $captured[0]{sql},
    qr/^\s*\(/,
    '... over the query itself, with the parentheses as_query wraps its '
  . 'output in stripped off by core before the hook ever saw it',
  );

  is_deeply (
    [ map { ref $_ eq 'ARRAY' ? $_->[1] : $_ } @{ $captured[0]{bind} } ],
    [ 'secret' ],
    '... carrying the explained query\'s own bind values: "if EXPLAIN is being '
  . 'dynamically prepared, the explainable-sql-statement can contain '
  . 'parameter markers" (SQL Reference), so they have to be supplied',
  );

  like (
    $captured[1]{sql},
    qr/^SELECT OPERATOR_ID, OPERATOR_TYPE, TOTAL_COST, IO_COST, CPU_COST /,
    'second statement: the driver\'s own, which core never rendered and knows '
  . 'nothing about. DB2 has no in-SQL formatter to call the way Oracle has '
  . 'DBMS_XPLAN -- db2exfmt and db2expln are OS commands outside DBI',
  );

  like (
    $captured[1]{sql},
    qr/FROM "SYSTOOLS"\."EXPLAIN_OPERATOR" WHERE EXPLAIN_REQUESTER = SESSION_USER/,
    '... reading the explain tables of the schema explain_table_schema names, '
  . 'SYSTOOLS by default -- where SYSPROC.SYSINSTALLOBJECTS puts them and '
  . 'where the Explain facility looks when the session schema has none',
  );

  like (
    $captured[1]{sql},
    qr/AND EXPLAIN_TIME = \(SELECT MAX\(EXPLAIN_TIME\) FROM "SYSTOOLS"\."EXPLAIN_OPERATOR" WHERE EXPLAIN_REQUESTER = SESSION_USER\) ORDER BY OPERATOR_ID$/,
    '... keyed on the newest explain of this authorization ID, in operator '
  . 'order: the explain tables are ordinary persistent tables with no session '
  . 'column, so this is the narrowest key DB2 offers',
  );

  is_deeply (
    $captured[1]{bind},
    [],
    '... with no binds of its own',
  );

  # The trace is the second, independent witness, and the one carrying ADR
  # 0025. Neither line can exist without _execute_rendered.
  ok (
    scalar( grep { /^EXPLAIN PLAN SELECTION FOR SELECT/ } @traced ),
    'the first statement reached the traced path',
  );

  ok (
    scalar( grep { /EXPLAIN_OPERATOR/ } @traced ),
    '... and so did the second one, which is the statement a driver is most '
  . 'tempted to run past the seam: it carries no user data, only everything '
  . 'else -- dbh_do retry, NoBindVars, and the read handler on a replicated '
  . 'storage',
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

  # Statement caching, which on this engine is a correctness question and not a
  # performance one: DB2 populates the explain tables when the EXPLAIN
  # statement is COMPILED, and prepare_cached returns a handle without
  # compiling again -- so a repeated explain would write no new plan and the
  # read-back would answer with whatever was explained last.
  is_deeply (
    [ @caching_while_running ],
    [ 1, 1 ],
    'statement caching was off while BOTH statements ran: the plan is written '
  . 'at compile time, so a cached prepare writes no plan at all and the '
  . 'read-back silently answers with an older one',
  );

  ok (
    ! $storage->disable_sth_caching,
    '... and the storage got its setting back afterwards -- the flag is '
  . 'localised to the operation, not switched off for the connection',
  );
}

# --- 4b. explain_table_schema is the seam for the other documented layout ---
#
# IBM documents two places for the explain tables: SYSPROC.SYSINSTALLOBJECTS
# creates them under SYSTOOLS, EXPLAIN.DDL under the current schema. The
# facility writes to the session's own schema when it has them and falls back
# to SYSTOOLS otherwise, so the read-back has to be told which -- reading the
# wrong one is quiet when that schema happens to hold somebody else's plan.

{
  my $schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'DBIO::DB2::Storage',
  );
  my $storage = $schema->storage;

  is (
    $storage->explain_table_schema,
    'SYSTOOLS',
    'the default is SYSTOOLS, IBM\'s preferred creation route and the '
  . 'facility\'s own fallback',
  );

  $storage->explain_table_schema('MYSCHEMA');
  $storage->mock(qr/EXPLAIN_OPERATOR/, [ [ 1, 'RETURN', 0, 0, 0 ] ]);
  $storage->reset_captured;

  $storage->_explain_query('SELECT 1 FROM SYSIBM.SYSDUMMY1', []);

  my @captured = $storage->captured_queries;

  like (
    $captured[1]{sql},
    qr/FROM "MYSCHEMA"\."EXPLAIN_OPERATOR" .* FROM "MYSCHEMA"\."EXPLAIN_OPERATOR" /,
    'setting it moves BOTH references in the read-back, the outer one and the '
  . 'one in the subquery that finds the newest explain',
  );

  is (
    DBIO::DB2::Storage->explain_table_schema,
    'SYSTOOLS',
    '... on this instance only: it is an inherited accessor, so a per-storage '
  . 'setting does not reach the class every other schema shares',
  );
}

# --- 5. the control: what a bypassing driver would look like ----------------
#
# Section 4 is worth nothing if its assertions cannot fail. This is the same
# hook implemented the way core k112 found explain() implemented -- reaching
# for the handle instead of the seam. It ANSWERS, so no caller can tell; what
# it does not do is appear anywhere. Core cannot detect this from inside a
# driver (ADR 0040 section 3 says so), so the driver's own suite is where it
# has to be caught, and inverting the assertion is how.

{
  package T::DB2Bypass::Storage;
  use base 'DBIO::DB2::Storage';

  sub _explain_query {
    my ($self, $sql, $bind) = @_;
    # THE ANTI-PATTERN -- deliberately wrong, do not copy into the driver.
    my $sth = $self->_dbh->prepare("EXPLAIN PLAN SELECTION FOR $sql");
    $sth->execute;
    return $sth->fetchall_arrayref;
  }
}
$INC{'T/DB2Bypass/Storage.pm'} = __FILE__;

{
  my $schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'T::DB2Bypass::Storage',
  );
  my $storage = $schema->storage;

  my @traced;
  $storage->debugcb(sub { push @traced, $_[1] });
  $storage->debug(2);   # binds are traced from level 2 (core k401)
  $storage->reset_captured;

  my $plan = $schema->resultset('Artist')
    ->search({ name => 'secret' })->explain;

  $storage->debug(0);
  $storage->debugcb(undef);

  is (
    ref $plan,
    'ARRAY',
    'a bypassing override still returns the right TYPE -- which is why no '
  . 'assertion about the return value could catch it',
  );

  is (
    scalar( $storage->captured_queries ),
    0,
    '... and yet the storage saw no statement at all, where the real override '
  . 'gave it two. That is section 4 inverted, and it is what makes those '
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

# --- 6. live round-trip -----------------------------------------------------
#
# Everything above pins what this driver EMITS. Whether DB2 takes it is the one
# thing an offline suite cannot say, and every spelling here is documented
# engine knowledge rather than something executed against a server. No fixture
# is needed -- SYSIBM.SYSDUMMY1 supplies the query -- but the explain tables
# ARE a precondition: without them the first statement fails with SQLSTATE
# 42704 and nothing here is reached, which is itself the documented behaviour
# and the first thing to check when this block goes red.

SKIP: {
  my ($dsn, $user, $pass)
    = @ENV{map { "DBIO_TEST_DB2_${_}" } qw/DSN USER PASS/};

  skip 'Set $ENV{DBIO_TEST_DB2_DSN}, _USER and _PASS to run the live half', 4
    unless $dsn && $user;

  skip 'Test needs '
     . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_db2'), 4
    unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_db2');

  my $live    = db2_schema($dsn, $user, $pass);
  my $storage = $live->storage;

  # The EXPLAIN_* tables are a precondition of the whole block, not something
  # the operation can work around: the first statement WRITES the plan into
  # them, so without them it dies with SQL0219N / SQLSTATE 42704 before any of
  # the four assertions below is reached. SYSPROC.SYSINSTALLOBJECTS installs
  # them once, under the schema explain_table_schema names (SYSTOOLS by
  # default) -- maint/docker/entrypoint.sh does that for every fresh test
  # server; every other setup has to do it itself.
  my $dbh = $storage->dbh;   # first dbh access resolves the driver (lazy)
  my $explain_schema = $storage->explain_table_schema;
  my ($have) = $dbh->selectrow_array(
    'SELECT COUNT(*) FROM SYSCAT.TABLES'
    . ' WHERE TABSCHEMA = ? AND TABNAME = ?',
    undef, uc $explain_schema, 'EXPLAIN_INSTANCE',
  );

  skip 'The Explain tables are missing from the '
     . "$explain_schema schema -- the first statement would fail with "
     . 'SQL0219N / SQLSTATE 42704. Install them once with CALL '
     . "SYSPROC.SYSINSTALLOBJECTS ('EXPLAIN', 'C', "
     . 'CAST(NULL AS VARCHAR(128)), CAST(NULL AS VARCHAR(128)))', 4
     unless $have;

  my ($rand) = $storage->dbh->selectrow_array(
    'SELECT ' . $storage->_random_function . ' FROM SYSIBM.SYSDUMMY1'
  );

  ok (
    defined $rand && $rand >= 0 && $rand < 1,
    'DB2 runs the random function and answers a number in [0,1)',
  );

  # The one assertion that could falsify the per-row claim the POD marks as
  # unverified: if RAND() were evaluated once per statement, every row would
  # sort by the same number and this would come back in table order every time.
  my @orders = map {
    join ',', map { $_->[0] } @{ $storage->dbh->selectall_arrayref(
      'SELECT ROWNUMBER() OVER () FROM SYSCAT.TABLES ORDER BY RAND()'
      . ' FETCH FIRST 20 ROWS ONLY'
    ) }
  } 1 .. 4;

  ok (
    scalar( keys %{ { map { $_ => 1 } @orders } } ) > 1,
    '... and ORDER BY RAND() shuffles: four runs did not all come back in the '
  . 'same order, which is what an engine evaluating its random function once '
  . 'per statement would have produced',
  );

  # The driver's own operation, both statements, exactly as $rs->explain would
  # drive it -- including the requirement that the EXPLAIN_* tables exist in
  # explain_table_schema.
  my $rows = $storage->_explain_query('SELECT 1 FROM SYSIBM.SYSDUMMY1', []);

  is (ref $rows, 'ARRAY', 'the two-statement operation returns rows');

  ok (
    scalar @$rows,
    '... and they are not empty: the plan came out of the SECOND statement, '
  . 'the first having written it into the EXPLAIN_* tables and returned '
  . 'nothing',
  );
}

done_testing;
