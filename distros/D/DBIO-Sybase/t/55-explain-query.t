use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Test;
use DBIO::Storage::DBI;
use DBIO::Sybase::Storage;
use DBIO::Sybase::Storage::ASE;

require DBIO::Test::Storage;

# karr k28 / core ADR 0040 section 7 -- the server-message half of the ticket,
# pinned offline. The other half (_random_function) is t/54.
#
#   _execute_sth   -- the collector. ASE emits its plan as server MESSAGES,
#                     the channel DBD::Sybase exposes only through
#                     syb_err_handler, so the execute verb is wrapped to
#                     install a handler that traps the showplan message numbers
#                     (3612-3615, 6201-6299, 10201-10299, per DBD::Sybase's own
#                     worked example) and returns them as the second value,
#                     which core stores in _server_messages.
#   _explain_query -- the orchestrator. Five statements: set showplan on, set
#                     noexec on, the query, set noexec off, set showplan off --
#                     the plain form prints the plan AND runs the query, so
#                     noexec has to bracket it. The plan is read back from
#                     _server_messages and wrapped as a single-column rowset.
#
# WHAT IS AND IS NOT PROVEN HERE. All of it is offline -- no DBI, no DSN, no
# server. It proves which statements this driver puts on the wire, in what
# order, that every one of them goes through the storage's statement path, that
# the showplan message numbers are collected and everything else is not, that
# the handler is restored even when execute throws, and that the OFF statements
# run from a guard. It cannot prove that ASE accepts any of it: no live server
# was run, and the XML plan routes (set plan for show_exec_xml,
# show_final_plan_xml, showplan_in_xml()) are unverified -- if one of them
# answers with a rowset rather than messages, this section and the driver are
# both wrong. The engine facts come from SAP's "Using set showplan with noexec"
# page and DBD::Sybase's own POD.

# --- 1. the hook lives on ::ASE, not on the shared dispatcher --------------
#
# The same cross-repo hazard t/54 section 2 pins for _random_function.
# DBIO::MSSQL::Storage::Sybase is @ISA (DBIO::Sybase::Storage,
# DBIO::MSSQL::Storage) under c3, so anything declared on the shared
# sp_server_info dispatcher answers for Microsoft SQL Server out of THIS
# distribution. ASE spells the setting "set showplan on" where SQL Server
# spells it SET SHOWPLAN_ALL ON, so a declaration on the dispatcher would be
# a wrong answer that still looks like a plan.

isnt( DBIO::Sybase::Storage::ASE->can('_explain_query'),
      DBIO::Storage::DBI->can('_explain_query'),
  'Sybase ASE overrides _explain_query -- core\'s bare EXPLAIN is a syntax '
. 'error on this engine' );

isnt( DBIO::Sybase::Storage::ASE->can('_execute_sth'),
      DBIO::Storage::DBI->can('_execute_sth'),
  '... and _execute_sth, the seam the plan arrives on' );

is( DBIO::Sybase::Storage->can('_explain_query'),
    DBIO::Storage::DBI->can('_explain_query'),
  '... and nothing was put on the shared DBD::Sybase dispatcher, where ASE\'s '
. '"set showplan on" would answer for Microsoft SQL Server, whose setting is '
. 'spelled SET SHOWPLAN_ALL ON (dbio-mssql t/56 pins the far side)' );

is( DBIO::Sybase::Storage->can('_execute_sth'),
    DBIO::Storage::DBI->can('_execute_sth'),
  '... nor for _execute_sth' );

SKIP: {
  skip 'DBIO::MSSQL not installed (not a dependency)', 2
    unless eval { require DBIO::MSSQL::Storage::Sybase; 1 };

  isnt( DBIO::MSSQL::Storage::Sybase->can('_explain_query'),
        DBIO::Sybase::Storage::ASE->can('_explain_query'),
    'MSSQL-over-DBD::Sybase does not resolve _explain_query to the ASE override' );

  isnt( DBIO::MSSQL::Storage::Sybase->can('_execute_sth'),
        DBIO::Sybase::Storage::ASE->can('_execute_sth'),
    '... nor _execute_sth' );
}

# --- 2. _execute_sth: the message collector ---------------------------------
#
# The handler is installed on the handle the statement runs on -- the one
# _dbh_execute received, never $self->dbh -- so tracing/redact_bind_value
# (ADR 0025), dbh_do retry and the read handler of a replicated storage all
# survive. It fires only for the showplan message numbers and returns 0 for
# them (showplan output is not an error); everything else is chained to the
# handler it displaced -- a caller's own PRINT/dbcc processing keeps its
# messages and its verdict while the slot is borrowed (karr k34). The restore
# is a Scope::Guard: if execute throws, the handler must not outlive the
# statement it was installed for.

{
  package T::ASE::FakeSth;

  sub new {
    my ($class, $execute) = @_;
    bless { execute => $execute }, $class;
  }

  sub execute { $_[0]->{execute}->(@_) }
}

{
  my $schema = DBIO::Test->init_schema(
    storage_type => 'DBIO::Sybase::Storage::ASE',
    no_deploy    => 1,
    quote_names  => 1,
  );
  my $storage = $schema->storage;

  # A fresh handle, not the storage's own -- the assertion below is that the
  # storage's own handle is never touched.
  my $dbh = DBIO::Test::Storage::FakeDbh->new;
  my $old = sub { 'old handler' };
  $dbh->{syb_err_handler} = $old;

  my @returns;
  my $sth = T::ASE::FakeSth->new(sub {
    my $h = $dbh->{syb_err_handler};
    # the three showplan ranges, the numbers just outside each, and a real
    # error -- the handler's return value is recorded for each.
    push @returns, $h->(3611, 0, 0, 0, 'MYSYBASE', 'proc', 'not showplan');
    push @returns, $h->(3612, 0, 0, 0, 'MYSYBASE', 'proc', 'plan line 1');
    push @returns, $h->(3615, 0, 0, 0, 'MYSYBASE', 'proc', 'plan line 2');
    push @returns, $h->(3616, 0, 0, 0, 'MYSYBASE', 'proc', 'not showplan');
    push @returns, $h->(6200, 0, 0, 0, 'MYSYBASE', 'proc', 'not showplan');
    push @returns, $h->(6201, 0, 0, 0, 'MYSYBASE', 'proc', 'plan line 3');
    push @returns, $h->(6299, 0, 0, 0, 'MYSYBASE', 'proc', 'plan line 4');
    push @returns, $h->(6300, 0, 0, 0, 'MYSYBASE', 'proc', 'not showplan');
    push @returns, $h->(10200, 0, 0, 0, 'MYSYBASE', 'proc', 'not showplan');
    push @returns, $h->(10201, 0, 0, 0, 'MYSYBASE', 'proc', 'plan line 5');
    push @returns, $h->(10299, 0, 0, 0, 'MYSYBASE', 'proc', 'plan line 6');
    push @returns, $h->(10300, 0, 0, 0, 'MYSYBASE', 'proc', 'not showplan');
    push @returns, $h->(50000, 16, 1, 0, 'MYSYBASE', 'proc', 'real error');
    return 1;
  });

  my ($rv, $messages) = $storage->_execute_sth($dbh, $sth);

  is $rv, 1, 'the execute return value passes through';

  is_deeply $messages,
    [ 'plan line 1', 'plan line 2', 'plan line 3', 'plan line 4',
      'plan line 5', 'plan line 6' ],
    'the showplan message numbers (3612-3615, 6201-6299, 10201-10299) are '
  . 'collected, and the numbers just outside each range are not';

  is_deeply \@returns, [ 'old handler', 0, 0, 'old handler', 'old handler',
      0, 0, 'old handler', 'old handler', 0, 0, 'old handler', 'old handler' ],
    '... the handler returns 0 for showplan output (not an error) and chains '
  . 'everything else to the prior handler, whose verdict passes through -- a '
  . 'caller\'s PRINT/dbcc processing is not skipped (karr k34)';

  is $dbh->{syb_err_handler}, $old,
    'the previous handler is restored after the statement';

  is $storage->_dbh->{syb_err_handler}, undef,
    '... and the storage\'s own handle was never touched: the handler goes on '
  . 'the handle the statement runs on, not on $self->dbh';
}

# the restore is a Scope::Guard: a throwing execute must not leave the handler
# installed, or a caller's own syb_err_handler would be lost and a stale
# closure left on the handle.
{
  my $schema = DBIO::Test->init_schema(
    storage_type => 'DBIO::Sybase::Storage::ASE',
    no_deploy    => 1,
    quote_names  => 1,
  );
  my $storage = $schema->storage;

  my $dbh = DBIO::Test::Storage::FakeDbh->new;
  my $old = sub { 'old handler' };
  $dbh->{syb_err_handler} = $old;

  my $sth = T::ASE::FakeSth->new(sub {
    die "DBD::Sybase::st execute failed: Invalid column name 'bogus'.\n";
  });

  throws_ok { $storage->_execute_sth($dbh, $sth) } qr/Invalid column name/,
    'a throwing execute propagates out of _execute_sth';

  is $dbh->{syb_err_handler}, $old,
    '... and the handler is still restored: the guard must not outlive the '
  . 'statement it was installed for';
}

# karr k34: the slot is BORROWED, not owned. A caller's own syb_err_handler
# was displaced for the duration of every statement, and the return-1 branch
# answered with a flat 1 -- its PRINT/dbcc processing was silently skipped and
# its verdict lost. Now the wrapper chains every non-showplan message to the
# handler it displaced: the message arrives, and so does the verdict.
{
  my $schema = DBIO::Test->init_schema(
    storage_type => 'DBIO::Sybase::Storage::ASE',
    no_deploy    => 1,
    quote_names  => 1,
  );
  my $storage = $schema->storage;

  my $dbh = DBIO::Test::Storage::FakeDbh->new;
  my @heard;
  my $old = sub {
    my ($err, $sev, $state, $line, $server, $proc, $msg) = @_;
    push @heard, [ $err, $msg ];
    return 0;   # "handled" -- e.g. a PRINT line consumed
  };
  $dbh->{syb_err_handler} = $old;

  my @verdicts;
  my $sth = T::ASE::FakeSth->new(sub {
    my $h = $dbh->{syb_err_handler};
    # a normal statement's server message -- PRINT output, not showplan
    push @verdicts, $h->(5000, 0, 0, 0, 'MYSYBASE', 'proc', 'print: hello');
    return 1;
  });

  my ($rv, $messages) = $storage->_execute_sth($dbh, $sth);

  is $rv, 1, 'the execute return value passes through';
  is_deeply $messages, [],
    'no showplan message numbers arrived, so nothing was collected';
  is_deeply \@heard, [ [ 5000, 'print: hello' ] ],
    'the pre-installed handler saw the non-showplan message -- its PRINT/dbcc '
  . 'processing is not skipped while the slot is borrowed';
  is_deeply \@verdicts, [ 0 ],
    '... and its verdict (0: handled) is what the wrapper reports to '
  . 'DBD::Sybase';
  is $dbh->{syb_err_handler}, $old,
    'the prior handler is restored after the statement';
}

# ... and without a prior handler the fallback is unchanged: 1, normal error
# processing. The chaining must not invent a handler where none was installed.
{
  my $schema = DBIO::Test->init_schema(
    storage_type => 'DBIO::Sybase::Storage::ASE',
    no_deploy    => 1,
    quote_names  => 1,
  );
  my $storage = $schema->storage;

  my $dbh = DBIO::Test::Storage::FakeDbh->new;   # no prior handler

  my @verdicts;
  my $sth = T::ASE::FakeSth->new(sub {
    push @verdicts, $dbh->{syb_err_handler}->(5000, 0, 0, 0, 'MYSYBASE', 'proc', 'print: hello');
    return 1;
  });

  $storage->_execute_sth($dbh, $sth);

  is_deeply \@verdicts, [ 1 ],
    'without a prior handler the fallback is still 1 -- normal error processing';
  is $dbh->{syb_err_handler}, undef,
    '... and the slot is clean again after the statement';
}

# ... and on a dying execute the same borrow holds: the pre-installed handler
# was in the chain and fired during the failed statement, and the guard
# restored it afterwards -- a dead statement must not take a caller's handler
# with it.
{
  my $schema = DBIO::Test->init_schema(
    storage_type => 'DBIO::Sybase::Storage::ASE',
    no_deploy    => 1,
    quote_names  => 1,
  );
  my $storage = $schema->storage;

  my $dbh = DBIO::Test::Storage::FakeDbh->new;
  my @heard;
  my $old = sub {
    my ($err, $sev, $state, $line, $server, $proc, $msg) = @_;
    push @heard, [ $err, $msg ];
    return 1;
  };
  $dbh->{syb_err_handler} = $old;

  my $sth = T::ASE::FakeSth->new(sub {
    my $h = $dbh->{syb_err_handler};
    $h->(50000, 16, 1, 0, 'MYSYBASE', 'proc', 'real error');
    die "DBD::Sybase::st execute failed: Invalid column name 'bogus'.\n";
  });

  throws_ok { $storage->_execute_sth($dbh, $sth) } qr/Invalid column name/,
    'a throwing execute propagates out of _execute_sth';

  is_deeply \@heard, [ [ 50000, 'real error' ] ],
    'the pre-installed handler was in the chain and fired before the death';
  is $dbh->{syb_err_handler}, $old,
    '... and is restored after the dying execute: the guard must not leave a '
  . 'stale closure on the shared handle';
}

# --- 3. _explain_query: the five statements, in order, through the seam -----
#
# The mock storage is the whole instrument: _execute_rendered is the ONLY point
# at which it sees a statement at all, so anything issued past the seam is
# captured nowhere, traced nowhere and redacted nowhere. That is what makes
# this a test of ADR 0040 section 3's routing rule and not just of five SQL
# strings. On the mock no handler ever fires, so the collected messages are
# empty -- the rowset wrapping with content is section 4.

{
  my $schema = DBIO::Test->init_schema(
    storage_type => 'DBIO::Sybase::Storage::ASE',
    no_deploy    => 1,
    quote_names  => 1,
  );
  my $storage = $schema->storage;

  $storage->reset_captured;

  my $rows = $storage->_explain_query('SELECT 1', []);

  my @captured = $storage->captured_queries;

  is scalar @captured, 5,
    'five statements reached the storage layer. ADR 0040 section 3 makes '
  . 'that a requirement of the contract with no engine-named exceptions';

  is_deeply [ map { $_->{sql} } @captured ],
    [ 'set showplan on', 'set noexec on', 'SELECT 1',
      'set noexec off', 'set showplan off' ],
    '... in the order the operation needs: the plain form prints the plan AND '
  . 'runs the query, so noexec has to bracket it -- five statements in all';

  is_deeply $rows, [],
    'the return value is an empty rowset on the mock, where no handler ever '
  . 'fires -- the shape is right, the content is section 4';
}

# --- 4. the rowset wrapping: collected messages as a single-column rowset ----
#
# The seam itself (that _dbh_execute stores the second value of _execute_sth in
# _server_messages) is core's, tested in core. What is the driver's is that
# _explain_query reads _server_messages back after the query statement and
# wraps it as a single-column rowset -- the shape _explain_query's contract
# names. Pre-fill _server_messages and record the statements to pin that.

{
  package T::ASE::Storage::RecordOnly;
  use mro 'c3';

  sub _execute_rendered {
    my ($self, $sql, $bind) = @_;
    push @{ $self->{_explain_recorded} }, $sql;
    return ('0E0', undef);
  }
}

# Both classes have to sit BEFORE DBIO::Test::Storage in the mro, and a plain
# subclass of DBIO::Sybase::Storage::ASE would not: DBIO::Test->init_schema
# builds a hybrid whose @ISA is (DBIO::Test::Storage, <driver>), so the mock's
# _execute_rendered shadows anything the driver side declares. Subclassing the
# hybrid the schema actually built is what puts the failure in front of it --
# and leaves the mock underneath, so the statements that DO get through are
# still captured.
sub reblessed_storage {
  my ($class) = @_;

  my $schema = DBIO::Test->init_schema(
    storage_type => 'DBIO::Sybase::Storage::ASE',
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
  my ($schema, $storage) = reblessed_storage('T::ASE::Storage::RecordOnly');

  $storage->{_explain_recorded} = [];
  $storage->_server_messages([ 'plan line 1', 'plan line 2' ]);

  my $rows = $storage->_explain_query('SELECT 1', []);

  is_deeply $storage->{_explain_recorded},
    [ 'set showplan on', 'set noexec on', 'SELECT 1',
      'set noexec off', 'set showplan off' ],
    'the five statements, in order, all through _execute_rendered';

  is_deeply $rows, [ [ 'plan line 1' ], [ 'plan line 2' ] ],
    'the collected server messages come back as a single-column rowset -- '
  . 'the shape $sth->fetchall_arrayref produces, whatever the engine had to '
  . 'do to get there';
}

# --- 5. the OFF also runs when the explained query throws -------------------
#
# THE POINT OF THE GUARD. Between the ONs and the OFFs the session is in plan
# mode, and that state outlives the call: if the middle statement dies and the
# OFFs are skipped, showplan stays on for the life of the connection and every
# later query on it silently returns a plan instead of its rows -- and with
# noexec still on, does not even run. So the OFFs are a Scope::Guard, and this
# is where that shows.

{
  package T::ASE::Storage::QueryDies;
  use mro 'c3';

  sub _execute_rendered {
    my ($self, $sql, $bind) = @_;
    die "DBD::Sybase::st execute failed: Invalid column name 'bogus'.\n"
      if $sql !~ /^set (?:showplan|noexec) /;
    push @{ $self->{_explain_recorded} }, $sql;
    return ('0E0', undef);
  }
}

{
  my ($schema, $storage) = reblessed_storage('T::ASE::Storage::QueryDies');

  $storage->{_explain_recorded} = [];

  my $err;
  eval { $storage->_explain_query('SELECT bogus FROM t', []); 1 } or $err = $@;

  like $err, qr/Invalid column name 'bogus'/,
    'the explained query\'s own exception propagates out of _explain_query -- '
  . 'the cleanup does not swallow it';

  is_deeply $storage->{_explain_recorded},
    [ 'set showplan on', 'set noexec on', 'set noexec off', 'set showplan off' ],
    '... and the two OFF statements still ran from the guard, although the '
  . 'query died between them: without them the session stays in plan mode for '
  . 'the life of the connection';
}

# --- 6. a failing ON issues nothing ------------------------------------------
#
# The guard is created only after BOTH ONs succeeded. A SET that failed was
# never applied, so an OFF here would be a second error hiding the first --
# and the query must not be attempted either, since without the setting the
# server would EXECUTE it instead of planning it.

{
  package T::ASE::Storage::SettingDies;
  use mro 'c3';

  sub _execute_rendered {
    my ($self, $sql, $bind) = @_;
    push @{ $self->{_explain_recorded} }, $sql;
    die "DBD::Sybase::st execute failed: showplan permission denied\n"
      if $sql =~ /^set showplan on/;
    return ('0E0', undef);
  }
}

{
  my ($schema, $storage) = reblessed_storage('T::ASE::Storage::SettingDies');

  $storage->{_explain_recorded} = [];

  my $err;
  eval { $storage->_explain_query('SELECT 1', []); 1 } or $err = $@;

  like $err, qr/showplan permission denied/,
    'a failing ON propagates as itself';

  is_deeply $storage->{_explain_recorded}, [ 'set showplan on' ],
    '... and nothing else is issued: the guard is created only after both '
  . 'ONs succeeded, so a failed ON leaves the session untouched';
}

done_testing;
