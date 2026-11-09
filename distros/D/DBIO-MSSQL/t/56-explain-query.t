use strict;
use warnings;

use Test::More;
use mro;

use DBIO::Test;
use DBIO::Storage::DBI;
use DBIO::MSSQL::Storage;
use DBIO::MSSQL::Storage::ODBC;

# karr k22 / core ADR 0040 -- the two driver-spelling hooks this driver
# inherited from core, pinned offline.
#
#   _random_function  -- already NEWID() on this class; pinned here so the
#                        rollout ticket's "nothing to do" stays true.
#   _explain_query    -- core's inherited operation is "EXPLAIN <query>", and
#                        Transact-SQL has no EXPLAIN statement at all. The
#                        spelling is not the interesting half: a plan on this
#                        engine comes from a SESSION SETTING across three
#                        round-trips, which is the shape ADR 0040 widened the
#                        seam from a string to a method for, naming this
#                        engine.
#
# Over DBD::ODBC explain is refused (section 2b), karr k71.
#
# WHAT IS AND IS NOT PROVEN HERE. Everything above the SKIP block is offline --
# no DBI, no DSN, no server. It proves what this driver puts on the wire, in
# what order, that every statement goes through the storage's statement path,
# and -- the assertion this ticket exists for -- that SHOWPLAN_ALL is turned
# back OFF even when the explained query throws. It cannot prove that SQL
# Server accepts any of it: no live server was run. The T-SQL facts come from
# Microsoft's SET SHOWPLAN_ALL / SET SHOWPLAN_XML reference pages.

# --- 1. the string hook is gone on both sides -------------------------------
#
# ADR 0040 REMOVED _explain_sql rather than deprecating it, so the migration is
# not silently safe in either direction: an override left behind on this class
# would simply never be called again, and $rs->explain would fall back to
# core's bare EXPLAIN with nothing anywhere to notice.

ok !DBIO::Storage::DBI->can('_explain_sql'),
  'core has no _explain_sql -- ADR 0040 removed the string hook outright';

ok !DBIO::MSSQL::Storage->can('_explain_sql'),
  '... and this driver carries no dead override of it, which would be a hook '
. 'nobody calls claiming a behaviour the code no longer has';

isnt(
  DBIO::MSSQL::Storage->can('_explain_query'),
  DBIO::Storage::DBI->can('_explain_query'),
  'the driver overrides _explain_query -- inheriting core\'s bare EXPLAIN '
. 'here is not a missing feature but a statement SQL Server cannot parse',
);

is(
  DBIO::MSSQL::Storage->_random_function, 'NEWID()',
  'the random-number function is NEWID(). Core answers RANDOM(), which SQL '
. 'Server has no such function for -- this half of karr k22 was already '
. 'correct and is pinned so it stays correct',
);

# --- 2. the rebless targets resolve to THIS driver's operation --------------
#
# A cross-repo tripwire, not an inheritance check (same hazard t/55 pins for
# _set_operation_keyword). DBIO::MSSQL::Storage::Sybase is
# @ISA (DBIO::Sybase::Storage, DBIO::MSSQL::Storage) under c3, so an
# _explain_query added to DBIO::Sybase::Storage would WIN here -- and that
# class talks DBD::Sybase to *Microsoft SQL Server*, not to Sybase ASE. The
# two engines do not even spell the setting the same way (ASE's is
# SET SHOWPLAN ON), so an ASE fact reaching this path would be a wrong answer
# that still looks like a plan. If this fails after a dbio-sybase change, that
# is the finding, not a stale assertion.
#
# Sharpened with t/55 under karr k25, because it was the same construct: the
# Sybase class was appended to the loop only when it loaded, so on a box
# without DBIO::Sybase (an optional dep) the iteration vanished with no trace
# in the TAP -- green, having checked nothing. It skips with a reason now, and
# pins the class that supplies the CV rather than comparing two CODE(0x...),
# so a dbio-sybase override is named wherever in that tree it lands.

sub first_definer {
  my ($class, $method) = @_;
  no strict 'refs';
  return( (grep { defined &{"${_}::${method}"} }
             @{ mro::get_linear_isa($class) })[0] );
}

sub explain_is_ours {
  my ($class) = @_;

  is(
    $class->can('_explain_query'),
    DBIO::MSSQL::Storage->can('_explain_query'),
    "$class resolves _explain_query to the MSSQL operation",
  );

  is( first_definer($class, '_explain_query'), 'DBIO::MSSQL::Storage',
    "... and DBIO::MSSQL::Storage is the class that supplies it" );
}

# DBD::ODBC refuses (karr k71, section 2b); only the Sybase class resolves to
# the three-round-trip operation of the base.

SKIP: {
  skip 'DBIO::Sybase not installed (optional dep), so the cross-dist half of '
     . 'this tripwire did NOT run', 2
    unless eval { require DBIO::MSSQL::Storage::Sybase; 1 };

  explain_is_ours('DBIO::MSSQL::Storage::Sybase');
}

# --- 2b. over DBD::ODBC explain is refused, not answered wrongly -----------
#
# Measured live 2026-10-19 (karr k71): over DBD::ODBC the prepared SET SHOWPLAN_ALL
# ON does not outlive its prepare, so the explained query runs and its own rows
# came back as the "plan" -- silently wrong. The ODBC class refuses instead
# (ADR 0040), before any statement is sent.

is(
  first_definer('DBIO::MSSQL::Storage::ODBC', '_explain_query'),
  'DBIO::MSSQL::Storage::ODBC',
  'the ODBC class has its own _explain_query, ahead of the base operation',
);

{
  my $schema = DBIO::Test->init_schema(
    storage_type => 'DBIO::MSSQL::Storage::ODBC',
    no_deploy    => 1,
    quote_names  => 1,
  );
  my $storage = $schema->storage;
  $storage->mock(qr/^SELECT /, [ [ 1 ] ]);
  $storage->reset_captured;

  my $err;
  eval { $schema->resultset('Artist')->search({ name => 'x' })->explain; 1 }
    or $err = $@;

  like $err, qr/refus/, 'explain over the ODBC path is refused';
  like $err, qr/no plan over ODBC/,
    '... and the message says what ODBC cannot do';
  like $err, qr/DBD::Sybase/, '... and names DBD::Sybase as the way to a plan';
  is scalar( $storage->captured_queries ), 0,
    '... before any statement is sent: neither SHOWPLAN setting is touched '
  . 'nor the query run, so no session is left in plan mode and no query '
  . 'rows pass as a plan';
}

# --- 3. the three round-trips, in order, all through the seam ---------------
#
# The mock storage is the whole instrument: _execute_rendered is the ONLY point
# at which it sees a statement at all, so anything issued past the seam is
# captured nowhere, traced nowhere and redacted nowhere. That is what makes
# this a test of ADR 0040 section 3's routing rule and not just of three SQL
# strings.

{
  my $schema = DBIO::Test->init_schema(
    storage_type => 'DBIO::MSSQL::Storage',
    no_deploy    => 1,
    quote_names  => 1,
  );
  my $storage = $schema->storage;

  # The plan comes back from the QUERY, not from a statement of the driver's
  # own: while SHOWPLAN_ALL is on the server does not execute the query, it
  # answers it with the plan. Four of SHOWPLAN_ALL's eighteen columns are
  # enough to make that visible.
  $storage->mock(qr/^SELECT /, [
    [ 'SELECT [me].[artistid] ... ', 1, 1, 0, undef,        undef            ],
    [ '  |--Clustered Index Scan', 1, 2, 1, 'Clustered Index Scan',
                                                            'Index Scan'     ],
  ]);

  # ADR 0025: the redactor is an observable only the traced path can produce.
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

  my @captured = $storage->captured_queries;

  is scalar @captured, 3,
    'three statements reached the storage layer. ADR 0040 section 3 makes '
  . 'that a requirement of the contract with no engine-named exceptions, and '
  . 'this is where it is checkable: a statement issued past _execute_rendered '
  . 'is captured nowhere at all';

  is $captured[0]{sql}, 'SET SHOWPLAN_ALL ON',
    'first: the session setting. Not a statement prefix -- there is no '
  . 'EXPLAIN in Transact-SQL to prefix with -- and alone in its batch, which '
  . 'is what Microsoft requires of it and what one _execute_rendered call is';

  is_deeply $captured[0]{bind}, [],
    '... with no binds of its own';

  like $captured[1]{sql}, qr/^SELECT \[me\]\.\[artistid\]/,
    'second: the explained query itself, unchanged. It is not executed while '
  . 'the setting is on -- the server answers it with the plan instead, which '
  . 'is why no second statement of the driver\'s own is needed to read one';

  unlike $captured[1]{sql}, qr/^\s*\(/,
    '... with the parentheses as_query wraps its output in stripped off by '
  . 'core before the hook ever saw it';

  unlike $captured[1]{sql}, qr/SHOWPLAN|EXPLAIN/,
    '... and nothing wrapped around or prepended to it';

  is_deeply [ map { ref $_ eq 'ARRAY' ? $_->[1] : $_ } @{ $captured[1]{bind} } ],
    [ 'secret' ],
    '... carrying the explained query\'s own bind values: the statement is '
  . 'still parsed, so its placeholders are still its own';

  is $captured[2]{sql}, 'SET SHOWPLAN_ALL OFF',
    'third: the setting is taken back off, or the session would answer every '
  . 'later query with a plan instead of its rows';

  is $plan->[0][0], 'SELECT [me].[artistid] ... ',
    'the caller gets the rows of the middle statement -- the plan';

  is scalar @$plan, 2,
    '... all of them, passed through without inventing columns or dropping '
  . 'the ones SHOWPLAN_ALL leaves undef on non-PLAN_ROW rows';

  # The trace is the second, independent witness, and the one carrying ADR
  # 0025. None of these lines can exist without _execute_rendered.
  ok scalar( grep { /SHOWPLAN_ALL ON/ } @traced ),
    'the ON reached the traced path';

  ok scalar( grep { /SHOWPLAN_ALL OFF/ } @traced ),
    '... and so did the OFF, which is the statement a driver is most tempted '
  . 'to run past the seam: it carries no user data, only everything else -- '
  . 'dbh_do retry, NoBindVars, and the read handler on a replicated storage';

  ok scalar( grep { /\[redacted\]/ } @traced ),
    'redact_bind_value (ADR 0025) got its chance at the explained query\'s '
  . 'bind values';

  ok ! scalar( grep { /secret/ } @traced ),
    '... and the raw value never reached the trace sink. This is the '
  . 'observable a $self->dbh bypass cannot fake: it would have skipped the '
  . 'hook entirely';
}

# --- 4. the OFF also runs when the explained query throws -------------------
#
# THE POINT OF THIS TICKET. Between the ON and the OFF the session is in plan
# mode, and that state outlives the call: if the middle statement dies and the
# OFF is skipped, SHOWPLAN_ALL stays on for the life of the connection and
# every later query on it silently returns a plan instead of its rows. No
# exception, no warning, well-formed rowsets answering a question nobody
# asked -- strictly worse than the missing EXPLAIN this override fixes,
# because it is quiet. So the OFF is a Scope::Guard, and this is where that
# shows.

{
  package T::MSSQL::Storage::QueryDies;
  use mro 'c3';

  our $ERROR = "DBD::ODBC::st execute failed: [Microsoft][ODBC Driver 18]"
             . "[SQL Server]Invalid column name 'bogus'.\n";

  sub _execute_rendered {
    my ($self, $sql, $bind) = @_;

    die $ERROR if $sql !~ /^SET SHOWPLAN_ALL /;

    return $self->next::method($sql, $bind);
  }
}

{
  package T::MSSQL::Storage::SettingDies;
  use mro 'c3';

  sub _execute_rendered {
    my ($self, $sql, $bind) = @_;

    die "DBD::ODBC::st execute failed: SHOWPLAN permission denied\n"
      if $sql =~ /^SET SHOWPLAN_ALL ON/;

    return $self->next::method($sql, $bind);
  }
}

# Both classes have to sit BEFORE DBIO::Test::Storage in the mro, and a plain
# subclass of DBIO::MSSQL::Storage would not: DBIO::Test->init_schema builds a
# hybrid whose @ISA is (DBIO::Test::Storage, <driver>), so the mock's
# _execute_rendered shadows anything the driver side declares. Subclassing the
# hybrid the schema actually built is what puts the failure in front of it --
# and leaves the mock underneath, so the statements that DO get through are
# still captured.
sub reblessed_storage {
  my ($class) = @_;

  my $schema = DBIO::Test->init_schema(
    storage_type => 'DBIO::MSSQL::Storage',
    no_deploy    => 1,
    quote_names  => 1,
  );
  my $storage = $schema->storage;

  {
    no strict 'refs';
    @{"${class}::ISA"} = (ref $storage);
  }
  bless $storage, $class;

  return ($schema, $storage);
}

{
  my ($schema, $storage) = reblessed_storage('T::MSSQL::Storage::QueryDies');

  $storage->reset_captured;

  # Plain eval rather than throws_ok, because the assertion is about WHICH
  # error survives and $@ has to be inspected twice for that.
  my $err;
  eval {
    $schema->resultset('Artist')->search({ name => 'x' })->explain;
    1;
  } or $err = $@;

  like $err, qr/\QInvalid column name 'bogus'\E/,
    'the explained query\'s own exception propagates out of explain -- the '
  . 'cleanup does not swallow it, which a bare try/finally would have done';

  unlike $err, qr/SHOWPLAN/,
    '... and is not replaced by anything the cleanup did: the caller is told '
  . 'what actually went wrong';

  my @captured = $storage->captured_queries;

  is scalar @captured, 2,
    'two statements reached the storage: the ON, and -- although the query '
  . 'died between them -- the OFF';

  is $captured[0]{sql}, 'SET SHOWPLAN_ALL ON',
    '... the ON first';

  is $captured[-1]{sql}, 'SET SHOWPLAN_ALL OFF',
    '... and the OFF last, which is the whole assertion: without it the '
  . 'session stays in plan mode for the life of the connection and answers '
  . 'every later query with a plan, silently';
}

{
  my ($schema, $storage) = reblessed_storage('T::MSSQL::Storage::SettingDies');

  $storage->reset_captured;

  my $err;
  eval {
    $schema->resultset('Artist')->search({ name => 'x' })->explain;
    1;
  } or $err = $@;

  like $err, qr/SHOWPLAN permission denied/,
    'a failing ON propagates as itself';

  is scalar( $storage->captured_queries ), 0,
    '... and nothing else is issued. The guard is created AFTER the ON '
  . 'succeeded on purpose: a SET that failed was never applied, so an OFF '
  . 'here would be a second error hiding the first -- and the query must not '
  . 'be attempted either, since without the setting the server would EXECUTE '
  . 'it instead of planning it';
}

# --- 5. the control: what a bypassing driver would look like ----------------
#
# Section 3 is worth nothing if its assertions cannot fail. This is the same
# hook implemented the way core karr k112 found explain() implemented --
# reaching for the handle instead of the seam. It ANSWERS, so no caller can
# tell; what it does not do is appear anywhere. Core cannot detect this from
# inside a driver (ADR 0040 section 3 says so), so the driver's own suite is
# where it has to be caught, and inverting the assertion is how.

{
  package T::MSSQL::Storage::Bypass;
  use base 'DBIO::MSSQL::Storage';

  sub _explain_query {
    my ($self, $sql, $bind) = @_;

    # THE ANTI-PATTERN -- deliberately wrong, do not copy into the driver.
    my $dbh  = $self->_dbh;
    my @rows;
    for my $stmt ('SET SHOWPLAN_ALL ON', $sql, 'SET SHOWPLAN_ALL OFF') {
      my $sth = $dbh->prepare($stmt);
      $sth->execute;
      push @rows, @{ $sth->fetchall_arrayref } if $stmt eq $sql;
    }

    return \@rows;
  }
}
$INC{'T/MSSQL/Storage/Bypass.pm'} = __FILE__;

{
  my $schema = DBIO::Test->init_schema(
    storage_type => 'T::MSSQL::Storage::Bypass',
    no_deploy    => 1,
    quote_names  => 1,
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

  is ref $plan, 'ARRAY',
    'a bypassing override still returns the right TYPE -- which is why no '
  . 'assertion about the return value could catch it';

  is scalar( $storage->captured_queries ), 0,
    '... and yet the storage saw no statement at all, where the real override '
  . 'gave it three. That is section 3 inverted, and it is what makes those '
  . 'assertions a test rather than a decoration';

  is scalar @traced, 0,
    '... nothing traced either, so redact_bind_value never ran on the bind '
  . 'values of the caller\'s own query (ADR 0025) -- one of the four things '
  . 'routing through the storage buys, together with dbh_do retry, NoBindVars '
  . 'interpolation and the read handler of a replicated storage';
}

# --- 6. live round-trip -----------------------------------------------------
#
# Everything above pins what this driver EMITS. Whether SQL Server takes it is
# the one thing an offline suite cannot say, and the two things most likely to
# be wrong are not the spellings:
#
#   * the batch rule. Microsoft documents that SET SHOWPLAN_ALL cannot appear
#     inside a stored procedure and must be the only statement in its batch.
#     Each _execute_rendered is its own prepare/execute -- unless the DBD
#     wraps it, and a DBD::ODBC routing prepare through sp_prepare /
#     sp_executesql would put the SET inside exactly that.
#   * how many result sets come back. Because the query is not executed, the
#     plan should be the first and only rowset, which is why the driver
#     fetches once and never loops over more_results.
#
# The last assertion is the one worth having: it runs an ordinary query on the
# SAME connection afterwards and checks it answers with data. That is the
# poisoned session this ticket is about, and it is invisible from inside the
# explain call.

# Live, karr k71 (written 2026-10-19, NOT yet run: no live runs that day).
# Expectations, to be confirmed against MSSQL 2022 / DBD::ODBC 1.61 /
# tdsodbc 1.3.17 and DBD::Sybase 1.27 / FreeTDS 1.3.17:
#   ODBC:   explain throws "refus ... no plan over ODBC", sends nothing, and an
#           ordinary query on the same connection answers with its data.
#   Sybase: a query WITHOUT placeholders returns the plan, 18 columns per row
#           (SHOWPLAN_ALL), and the session is not left in plan mode.

SKIP: {
  my ($dsn, $user, $pass) =
    @ENV{ map { "DBIO_TEST_MSSQL_ODBC_$_" } qw/DSN USER PASS/ };

  skip 'Set $ENV{DBIO_TEST_MSSQL_ODBC_DSN}, _USER and _PASS to run the live '
     . 'ODBC half', 4
    unless $dsn && $user && $pass;

  require DBIO::Test::Schema;
  # a schema always declares its driver (core ADR 0067)
  DBIO::Test::Schema->storage_type('+DBIO::MSSQL::Storage');
  my $live = DBIO::Test::Schema->connect($dsn, $user, $pass);
  $live->storage->dbh;    # the declared storage adapts at its first use
  my $storage = $live->storage;

  isa_ok $storage, 'DBIO::MSSQL::Storage::ODBC';

  my $err;
  eval { $storage->_explain_query('SELECT 1 AS one', []); 1 } or $err = $@;

  like $err, qr/refus.*no plan over ODBC/s,
    'explain over a live DBD::ODBC connection is refused';

  my ($one) = $storage->dbh->selectrow_array('SELECT 1 AS one');
  is $one, 1,
    'the session is not in plan mode: an ordinary query answers with data';

  my ($guid) = $storage->dbh->selectrow_array(
    'SELECT ' . $storage->_random_function
  );
  like $guid, qr/^[0-9A-F]{8}-/i,
    'SQL Server runs the random function and answers a uniqueidentifier';
}

SKIP: {
  my ($dsn, $user, $pass) =
    @ENV{ map { "DBIO_TEST_MSSQL_$_" } qw/DSN USER PASS/ };

  skip 'Set $ENV{DBIO_TEST_MSSQL_DSN}, _USER and _PASS to run the live '
     . 'DBD::Sybase half', 4
    unless $dsn && $user && $pass;

  require DBIO::Test::Schema;
  DBIO::Test::Schema->storage_type('+DBIO::MSSQL::Storage');
  my $live = DBIO::Test::Schema->connect($dsn, $user, $pass);
  $live->storage->dbh;
  my $storage = $live->storage;

  my $rows = $storage->_explain_query('SELECT 1 AS one', []);

  is ref $rows, 'ARRAY', 'over DBD::Sybase the three round-trips return rows';
  ok scalar @$rows, '... not empty';
  is scalar @{ $rows->[0] }, 18,
    '... the 18 columns of SHOWPLAN_ALL, not the query\'s own row';

  my ($one) = $storage->dbh->selectrow_array('SELECT 1 AS one');
  is $one, 1, 'and the session is not left in plan mode';
}

done_testing;
