use strict;
use warnings;
use Test::More;

use DBIO::Optional::Dependencies ();
use DBIO::Test;
use DBIO::Test::Schema;
use DBIO::Storage::DBI;
use DBIO::Oracle::Storage;

# karr k22 / core ADR 0011 and ADR 0040 -- the two driver-spelling hooks this
# driver inherited wrong, pinned offline. Neither of them is a preference:
# core's inherited answer is invalid SQL on Oracle in both cases.
#
#   _random_function  -- core answers RANDOM(), a function Oracle does not
#                        have. DBMS_RANDOM.VALUE is the one it does have.
#   _explain_query    -- core's inherited operation is a bare EXPLAIN, which
#                        Oracle has no such statement for. And the spelling is
#                        the smaller half: EXPLAIN PLAN FOR returns NO rows, it
#                        writes into PLAN_TABLE, so the plan is a SECOND
#                        statement. That is the shape ADR 0040 widened the seam
#                        from a string to a method for, naming this engine.
#
# WHAT IS AND IS NOT PROVEN HERE. Everything below is offline -- no DBI, no
# DSN, no server. It proves what this driver puts on the wire, that both
# statements of the two-statement operation go through the storage's statement
# path, and that the plan the caller gets back is the second statement's rows.
# It cannot prove that Oracle accepts either statement: no live server was
# available when this was written, and the spellings come from the SQL Language
# Reference and the DBMS_XPLAN package documentation. The SKIP block at the end
# is where that half gets checked, against a DSN somebody supplies.

# --- 1. the string hook is gone on both sides -------------------------------
#
# ADR 0040 REMOVED _explain_sql rather than deprecating it, so the migration is
# not silently safe in either direction: an override left behind on this class
# would simply never be called again, and $rs->explain would go back to core's
# bare EXPLAIN with nothing to notice. Pinned on both classes because either
# side reappearing is that failure.

ok !DBIO::Storage::DBI->can('_explain_sql'),
  'core has no _explain_sql -- ADR 0040 removed the string hook outright';

ok !DBIO::Oracle::Storage->can('_explain_sql'),
  '... and this driver carries no dead override of it, which would be a hook '
. 'nobody calls claiming a behaviour the code no longer has';

# --- 2. _random_function ----------------------------------------------------
#
# Static class fact: string out, no $dbh, no version probe. The storage below
# is of the driver its schema declares, is built from a dbi:Oracle: DSN and
# never connects -- the hook is on core's driver-determination list, and the
# declared driver stands through it, so the answer is this driver's rather
# than the base one arrived at by accident.

# DBIO::Test::Schema is shared by the driver suites and declares no driver; a
# schema always has one (core ADR 0067). Each connect here declares Oracle's
# storage on a clone, so the shared class stays without one.
sub oracle_schema {
  my $schema = DBIO::Test::Schema->clone;
  $schema->storage_type('+DBIO::Oracle::Storage');
  return $schema->connect(@_);
}

{
  my $schema  = oracle_schema('dbi:Oracle:orcl');
  my $storage = $schema->storage;

  is (
    $storage->_random_function,
    'DBMS_RANDOM.VALUE',
    'the random-number function is DBMS_RANDOM.VALUE. Core answers RANDOM(), '
  . 'which is right on PostgreSQL and SQLite and is not a function Oracle has '
  . 'at all, so the server has nothing to resolve the name to',
  );

  unlike (
    $storage->_random_function,
    qr/\(/,
    '... written WITHOUT parentheses: this is the zero-argument overload and '
  . 'SQL has no empty argument list, so DBMS_RANDOM.VALUE() is not the same '
  . 'string with optional punctuation but a parse error',
  );

  is (
    ref $storage,
    'DBIO::Oracle::Storage',
    '... answered by the storage the schema declared, still that class after '
  . 'the hook ran driver determination on the dbi:Oracle: DSN',
  );

  isnt (
    DBIO::Oracle::Storage->can('_random_function'),
    DBIO::Storage::DBI->can('_random_function'),
    '... and it is a real override, by coderef identity rather than by the '
  . 'inherited string happening to look right',
  );

  is (
    $storage->can('_explain_query'),
    DBIO::Oracle::Storage->can('_explain_query'),
    'the same never-connected storage already resolves _explain_query to this '
  . 'driver\'s operation too (ADR 0040 section 5: the driver has to be '
  . 'determined BEFORE its explain is chosen, not as a side effect of the '
  . 'first statement the base implementation would have run)',
  );

  isnt (
    DBIO::Oracle::Storage->can('_explain_query'),
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
    storage_type => 'DBIO::Oracle::Storage',
  );

  my ($sql, @bind) = @{ ${
    $schema->resultset('Artist')->search({ name => 'foo' })->rand(3)->as_query
  } };

  like (
    $sql,
    qr/ORDER BY DBMS_RANDOM\.VALUE/,
    'rand() orders by the function the storage named',
  );

  unlike (
    $sql,
    qr/\bRANDOM\s*\(/,
    '... and nowhere by the RANDOM() core answers with by default',
  );

  # Not decoration: rand() adds `rows`, so the ROWNUM limit dialect wraps the
  # query -- and the sort has to end up INSIDE that wrapper. A random ORDER BY
  # applied outside a ROWNUM predicate shuffles the rows the predicate already
  # picked, which is three arbitrary rows in a random order rather than three
  # random rows.
  like (
    $sql,
    qr/ORDER BY DBMS_RANDOM\.VALUE\s*\)\s*"me"\s+WHERE\s+ROWNUM/s,
    '... inside the ROWNUM subquery rather than outside it, which is what '
  . 'makes it three RANDOM rows instead of three arbitrary ones in random '
  . 'order',
  );

  is_deeply (
    [ map { $_->[1] } @bind ],
    [ 'foo', 3 ],
    '... with the search condition and the row count as binds, in that order',
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
    storage_type => 'DBIO::Oracle::Storage',
  );
  my $storage = $schema->storage;

  # Only the SECOND statement answers. The first one is mocked by nobody on
  # purpose: EXPLAIN PLAN FOR returns no rows on the engine either, and an
  # implementation that tried to read its plan out of the first statement would
  # come back empty here exactly as it would there.
  $storage->mock(qr/DBMS_XPLAN/, [
    ['Plan hash value: 1234567890'],
    ['--------------------------------------------------'],
    ['| Id | Operation         | Name   | Rows | Cost |'],
    ['|  0 | SELECT STATEMENT  |        |    1 |    3 |'],
  ]);

  # ADR 0025: the redactor is an observable only the traced path can produce.
  # A driver reaching for $self->dbh would print the raw value -- or, far more
  # likely, print nothing at all, there being no trace.
  my $default_redactor = $storage->redact_bind_value;
  $storage->redact_bind_value(sub {
    my ($colname, $value) = @_;
    return defined $colname && $colname eq 'name' ? '[redacted]' : $value;
  });

  my @traced;
  $storage->debugcb(sub { push @traced, $_[1] });
  $storage->debug(2);
  $storage->reset_captured;

  my $plan = $schema->resultset('Artist')
    ->search({ name => 'secret' })->explain;

  $storage->debug(0);
  $storage->debugcb(undef);
  $storage->redact_bind_value($default_redactor);

  is (
    $plan->[0][0],
    'Plan hash value: 1234567890',
    'explain answers with the rows of the SECOND statement -- the first one '
  . 'has no plan in it to return, which is the whole reason this hook is a '
  . 'method and not a string',
  );

  is (
    scalar @$plan,
    4,
    '... all of them: DBMS_XPLAN hands back one row per line of its formatted '
  . 'report, and the driver passes them through without inventing columns to '
  . 'fit them into',
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
    qr/^EXPLAIN PLAN FOR SELECT /,
    'first statement: EXPLAIN PLAN FOR, not the bare EXPLAIN core inherits '
  . 'here -- Oracle has no such statement and answers ORA-00900',
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
    '... carrying the explained query\'s own bind values: EXPLAIN PLAN parses '
  . 'the statement, so its placeholders are the statement\'s and have to be '
  . 'supplied',
  );

  like (
    $captured[1]{sql},
    qr/^SELECT \* FROM TABLE\(DBMS_XPLAN\.DISPLAY\)$/,
    'second statement: the driver\'s own, which core never rendered and knows '
  . 'nothing about. With no arguments DBMS_XPLAN.DISPLAY reads back the most '
  . 'recently explained statement of the session -- the one the first '
  . 'statement just wrote into PLAN_TABLE',
  );

  is_deeply (
    $captured[1]{bind},
    [],
    '... with no binds of its own',
  );

  # The trace is the second, independent witness, and the one carrying ADR
  # 0025. Neither line can exist without _execute_rendered.
  ok (
    scalar( grep { /^EXPLAIN PLAN FOR SELECT/ } @traced ),
    'the first statement reached the traced path',
  );

  ok (
    scalar( grep { /DBMS_XPLAN/ } @traced ),
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
  package T::OraBypass::Storage;
  use base 'DBIO::Oracle::Storage';

  sub _explain_query {
    my ($self, $sql, $bind) = @_;
    # THE ANTI-PATTERN -- deliberately wrong, do not copy into the driver.
    my $sth = $self->_dbh->prepare("EXPLAIN PLAN FOR $sql");
    $sth->execute;
    return $sth->fetchall_arrayref;
  }
}
$INC{'T/OraBypass/Storage.pm'} = __FILE__;

{
  my $schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'T::OraBypass::Storage',
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
# Everything above pins what this driver EMITS. Whether Oracle takes it is the
# one thing an offline suite cannot say, and both spellings here are documented
# engine knowledge rather than something executed against a server. No fixture
# is needed: DUAL supplies the query, and PLAN_TABLE is the database's own.

SKIP: {
  my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_ORA_${_}" } qw/DSN USER PASS/};

  skip 'Set $ENV{DBIO_TEST_ORA_DSN}, _USER and _PASS to run the live half', 4
    unless $dsn && $user && $pass;

  skip 'Test needs '
     . DBIO::Optional::Dependencies->req_missing_for('rdbms_oracle'), 4
    unless DBIO::Optional::Dependencies->req_ok_for('rdbms_oracle');

  my $live    = oracle_schema($dsn, $user, $pass);
  my $storage = $live->storage;

  my ($rand) = $storage->dbh->selectrow_array(
    'SELECT ' . $storage->_random_function . ' FROM DUAL'
  );

  ok (
    defined $rand && $rand >= 0 && $rand < 1,
    'Oracle runs the random function and answers a number in [0,1)',
  );

  # The driver's own operation, both statements, exactly as $rs->explain would
  # drive it -- including the requirement that PLAN_TABLE be visible to this
  # session. If it is not, this throws (ORA-02404 / ORA-00942 / ORA-01031)
  # rather than answering an empty plan, which is the documented behaviour and
  # the thing to check first when it fails.
  my $rows = $storage->_explain_query('SELECT 1 FROM DUAL', []);

  is (ref $rows, 'ARRAY', 'the two-statement operation returns rows');

  ok (
    scalar @$rows,
    '... and they are not empty: the plan came out of the SECOND statement, '
  . 'the first having written it into PLAN_TABLE and returned nothing',
  );

  ok (
    scalar( grep { defined && /DUAL/i } map { @$_ } @$rows ),
    '... and the plan names the table the explained query reads, so it is '
  . 'this query\'s plan and not a stale row of somebody else\'s',
  );
}

done_testing;
