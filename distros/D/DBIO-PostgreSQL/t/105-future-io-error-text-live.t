use strict;
use warnings;
use Test::More;

# LIVE test: the failure of a statement over the future_io transport is the
# server's text, not where in this library it was collected (karr k120).
#
# WHY: what a statement fails with reaches the caller of a Future, and from
# there a log, a bug report, an API answer. It used to end in
# "... at <install path>/DBIO/PostgreSQL/Storage/Async.pm line 946." -- DBI
# raising the error itself and blaming its caller, which is always this
# transport. The path says where DBIO is installed, the line changes with
# every release, and neither says anything about the statement.
#
# What this file claims, against a real server, for every way an error of
# DBD::Pg's comes back through this transport -- the pool, a pinned connection,
# a transaction, the listen connection:
#   * the failure is a plain string, as it was;
#   * it is DBI's message with the server's text, whole;
#   * it names no perl file and no line;
#   * the SQLSTATE is where it was: on the handle.
# The mechanism, the caller's own HandleError and the transport's refusals are
# held offline in t/105-future-io-error-text.t.
#
# Creates one table, dbio_k120_error_text, and drops it. Ends two backends,
# both its own: a pool connection and a listen connection it opened.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_PG_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_PG_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

BEGIN {
  eval {
    require IO::Async::Loop;
    require Future::IO::Impl::IOAsync;
    Future::IO::Impl::IOAsync->import;
    1;
  } or plan skip_all =>
    'Future::IO::Impl::IOAsync + IO::Async required for the live future_io roundtrip';
}

use Future;
use Future::IO;
use DBIO::Test;

# DBIO::Test::Schema keeps no driver in its class: this file runs it on
# PostgreSQL (core ADR 0067).
DBIO::Test::Schema->storage_type('+DBIO::PostgreSQL::Storage');

eval { require DBIO::PostgreSQL::Storage::Async; 1 }
  or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';

# A server that is not there fails the file, with a plan (karr k113).
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
LiveServer->require_server;

my $TABLE = 'dbio_k120_error_text';

my $schema = DBIO::Test::Schema->connect($dsn, $user, $pass, { async => 'future_io' });
my $async  = $schema->storage->async;
my $dbh    = $schema->storage->dbh;

{
  local $dbh->{Warn} = 0;
  local $SIG{__WARN__} = sub { };   # the NOTICE of DROP ... IF EXISTS
  $dbh->do("DROP TABLE IF EXISTS $TABLE");
}
$dbh->do("CREATE TABLE $TABLE (id int PRIMARY KEY, v int NOT NULL)");
END {
  if ($dbh && $dbh->{Active}) {
    local $SIG{__WARN__} = sub { };
    $dbh->do("DROP TABLE IF EXISTS $TABLE");
  }
}

# What a Future fails with, or undef when it does not fail. A Future that is
# not ready in time fails the case instead of hanging the file.
my $LIMIT = 15;
sub failure_of {
  my ($f) = @_;
  my $ok = eval {
    Future->wait_any(
      $f->without_cancel,
      Future::IO->sleep($LIMIT)->then(sub { Future->fail("not finished after $LIMIT seconds\n") }),
    )->get;
    1;
  };
  return $ok ? undef : $@;
}

# The claim: a plain string, DBI's message with the server's text, and neither
# a perl file nor a line. No server message has a ".pm" in it, and none reads
# " at <something> line <n>" -- the server writes "LINE 1:" and, for PL/pgSQL,
# "line 3 at RAISE".
sub server_text_only {
  my ($err, $says, $name) = @_;
  ok defined $err && !ref $err, "$name: fails with a plain string"
    or diag 'got: ' . (defined $err ? ref $err : 'no failure');
  $err = '' unless defined $err && !ref $err;
  like   $err, $says,                  '... the message expected (DBI\'s with the server\'s text, or the queue\'s refusal)';
  unlike $err, qr/ at \S+ line \d+/,   '... that names no file and no line';
  unlike $err, qr/\.pm\b/,             '... and no module';
  like   $err, qr/[^\n]\n\z/,          '... and ends in one newline';
}

# --- the pool ----------------------------------------------------------------
server_text_only(
  failure_of($async->_query_async('SELEC 1', [])),
  qr/\ADBD::Pg::db pg_result failed: ERROR:  syntax error at or near "SELEC"\nLINE 1: SELEC 1\n\s+\^\n\z/,
  'a syntax error',
);
server_text_only(
  failure_of($async->select_async('dbio_k120_no_such_table', ['x'], {})),
  qr/\ADBD::Pg::db pg_result failed: ERROR:  relation "dbio_k120_no_such_table" does not exist\n/,
  'select_async on a table that is not there',
);
$async->_query_async("INSERT INTO $TABLE VALUES (?, ?)", [ 1, 1 ])->get;
server_text_only(
  failure_of($async->_query_async("INSERT INTO $TABLE VALUES (?, ?)", [ 1, 1 ])),
  qr/\ADBD::Pg::db pg_result failed: ERROR:  duplicate key value violates unique constraint "${TABLE}_pkey"\nDETAIL:  Key \(id\)=\(\*\*\*\) already exists\.\n\z/,
  'a unique violation',
);
server_text_only(
  failure_of($async->_query_async("INSERT INTO $TABLE VALUES (?, ?)", [ 2, undef ])),
  qr/\ADBD::Pg::db pg_result failed: ERROR:  null value in column "v" of relation "$TABLE" violates not-null constraint\nDETAIL:  /,
  'a not-null violation',
);
# Refused by DBD::Pg before it is sent: execute, not pg_result.
server_text_only(
  failure_of($async->_query_async('SELECT 1', [ 1 ])),
  qr/\ADBD::Pg::st execute failed: called with 1 bind variables when 0 are needed\n\z/,
  'a statement DBD::Pg refuses at execute',
);
server_text_only(
  failure_of($async->notify(dbio_k120 => 'x' x 9000)),
  qr/\ADBD::Pg::db pg_result failed: ERROR:  payload string too long\n\z/,
  'notify with a payload the server refuses',
);

# --- a pinned connection: the SQLSTATE beside the text, a cancel, a loss -------
{
  my $conn = $async->pool->acquire->get;

  server_text_only(
    failure_of($async->_query_async_pinned($conn, 'SELECT 1/0', [])),
    qr/\ADBD::Pg::db pg_result failed: ERROR:  division by zero\n\z/,
    'a division by zero',
  );
  is $conn->{dbh}->state, '22012', '... and its SQLSTATE is on the handle';

  $async->_query_async_pinned($conn, q{SET statement_timeout = '100ms'}, [])->get;
  server_text_only(
    failure_of($async->_query_async_pinned($conn, 'SELECT pg_sleep(1)', [])),
    qr/\ADBD::Pg::db pg_result failed: PostgreSQL cancelled the statement \(SQLSTATE 57014 query_canceled/,
    'a statement the server cancels',
  );
  is $conn->{dbh}->state, '57014', '... and its SQLSTATE is on the handle';
  $async->_query_async_pinned($conn, 'RESET statement_timeout', [])->get;

  # The connection is lost under a statement: its own backend is terminated.
  my ($pid) = map { $_->[0] } $async->_query_async_pinned($conn, 'SELECT pg_backend_pid()', [])->get;
  my $sleep = $async->_query_async_pinned($conn, 'SELECT pg_sleep(10)', []);
  $dbh->do('SELECT pg_terminate_backend(?)', undef, $pid);
  server_text_only(
    failure_of($sleep),
    qr/\ADBD::Pg::db pg_result failed: FATAL:  terminating connection due to administrator command\n/,
    'a connection lost under its statement',
  );
  # Not DBI's text: the connection is reported dead to the pool, and since
  # dbio-async k47 nothing more is sent on it -- the queue refuses with a
  # plain string of its own, which must hold the same shape.
  server_text_only(
    failure_of($async->_query_async_pinned($conn, 'SELECT 1', [])),
    qr/\Anot sent: this connection was reported dead to the pool \(_conn_error_is_fatal\), so nothing more is sent on it\n\z/,
    'the next statement on that connection is refused, not sent',
  );
  $async->pool->release($conn);
}

# --- a transaction ------------------------------------------------------------
server_text_only(
  failure_of($async->txn_do_async(sub {
    my ($txn) = @_;
    return $async->_query_async_pinned($txn->txn_conn, "INSERT INTO $TABLE VALUES (1, 1)", []);
  })),
  qr/\ADBD::Pg::db pg_result failed: ERROR:  duplicate key value violates unique constraint "${TABLE}_pkey"\n/,
  'a statement that fails its transaction',
);

# --- the listen connection ------------------------------------------------------
{
  my $conn = $async->_listen_open->get;
  my $pid  = $conn->{dbh}{pg_pid};
  $dbh->do('SELECT pg_terminate_backend(?)', undef, $pid);
  # until the backend is gone
  for (1 .. 50) {
    my ($there) = $dbh->selectrow_array('SELECT count(*) FROM pg_stat_activity WHERE pid = ?', undef, $pid);
    last unless $there;
    select undef, undef, undef, 0.1;
  }

  my $ok  = eval { $async->_listen_subscribe($conn, 'dbio_k120'); 1 };
  my $err = $@;
  ok !$ok, 'LISTEN on a listen connection that is lost dies';
  server_text_only($err, qr/\ADBD::Pg::db do failed: \S/, 'what it dies with');

  # The first drain may take the server's FATAL as a notice; the end of file
  # behind it fails the next.
  $ok  = eval { $async->_listen_drain($conn) for 1 .. 3; 1 };
  $err = $@;
  ok !$ok, 'draining a listen connection that is lost dies';
  server_text_only($err, qr/\ADBD::Pg::db (?:pg_notifies|do) failed: \S|\Adraining the listen connection failed: \S/,
    'what it dies with');

  $async->_listen_close($conn);
}

# --- the pool is none the worse -------------------------------------------------
is_deeply [ $async->_query_async('SELECT ?::int', [ 7 ])->get ], [ [ 7 ] ],
  'after all of it the next statement runs';

$async->disconnect;
{
  local $SIG{__WARN__} = sub { };
  $dbh->do("DROP TABLE IF EXISTS $TABLE");
}

done_testing;
