use strict;
use warnings;
use Test::More;
use Time::HiRes ();

# LIVE proof of karr k65: when a statement fails, _conn_error_is_fatal tells a
# connection the server ended from one that merely refused a statement -- the
# first is retired at its release and the next call runs on a fresh one, the
# second goes back to the pool and is used again.
#
# WHY IT MATTERS. t/68 pins the seam offline, over fake DBDs that fail with the
# number the test hands them. Which number a real server and a real client
# library produce for which death is the one thing it could not know, and the
# seam is a list of numbers: a death that arrives under a number not on it
# puts a dead connection back on the idle list, and a statement error taken
# for a death throws a healthy one away on every duplicate key.
#
# So the central claim is not about numbers. Every time the seam is asked, the
# test asks the server too -- a ping on that handle, right after the seam has
# answered, which the seam itself must never send -- and the two must agree:
# dead exactly when the session is gone. The numbers are noted, per run, for
# the POD of _conn_error_is_fatal, which lists what was measured.
#
# THE BORROW-TIME CHECK IS OFF HERE. _idle_connection_alive (karr k63, t/76)
# would retire a dead idle connection at its next borrow whatever this seam
# said, and every "the next call is fresh" below would hold with the seam
# answering nothing but false. It is held at its default, "alive without
# looking", so that what is shown rests on _conn_error_is_fatal alone -- and
# switched back on in the one place that shows what the two do together.
#
# What this file claims, on a pool of one, over a plain connection and over
# TLS where it can be had:
#   1. KILL CONNECTION from another session while a statement runs on the
#      borrowed connection: the statement fails, the seam says dead, the pool
#      retires the connection at its release, and the next call runs on a
#      fresh session -- through _query_async and for the pinned connection of
#      a txn_do_async;
#   2. the control: a duplicate key (1062), a syntax error (1064) and KILL
#      QUERY (1317) fail the statement and leave the session: the seam says
#      kept, and the next call runs on the SAME session;
#   3. a statement on a connection that died while it sat idle -- killed, or
#      timed out by wait_timeout: it fails, and the seam says dead. MySQL 8.0.24
#      and later report wait_timeout as 4031, which is a statement error on
#      MariaDB: the seam answers it by server product (karr k72);
#   4. a CALL that returns two result sets: the later set is read out, and the
#      next statement runs on the same pool connection (karr k73; before, it
#      left DBD::MariaDB refusing every statement after it), and that the
#      handles of a dead connection are dropped without a warning (karr k74).
#
# NO BLIND WAITING: a KILL is sent once the server lists the statement as
# running, and what follows waits, bounded, for the statement's Future; a
# connection killed while idle is used once its socket is readable.
#
# NOT REACHED without stopping a server, so not shown: 1053
# (ER_SERVER_SHUTDOWN) and MariaDB's 1927 (ER_CONNECTION_KILLED). A KILL did
# not deliver them: what the client library reported was the loss of the
# connection.
#
# Runs through whichever DBD the DSN names. Gated like the other live tests:
# needs DBIO_TEST_MYSQL_DSN, _USER and _PASS. Creates and drops a table and a
# procedure of its own; the sessions it kills are its own pool's.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
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

use DBI;
use DBIO::Test;

eval { require DBIO::MySQL::Storage::Async; 1 }
  or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
plan skip_all => 'the installed DBIO core predates PoolBase::_mark_connection_dead (core k230)'
  unless DBIO::Storage::PoolBase->can('_mark_connection_dead');
plan skip_all => 'the installed dbio-async predates the _conn_error_is_fatal seam (dbio-async k26)'
  unless DBIO::Async::Storage->can('_conn_error_is_fatal');

# The transport has no session reset (core ADR 0079): the pool retires its
# connection at the end of every borrow. This file asks which failures take the
# connection with them and which leave it to be used again, which is only
# visible on a connection that survives a borrow. So the pool gets the reset a
# server with a session reset would give, done at once: the statements of this
# file leave no session state to reset. The server and the DBD stay real, and
# what retires a connection here is the verdict of _conn_error_is_fatal.
{
  no warnings 'redefine';
  *DBIO::MySQL::Storage::Async::_reset_pool_connection = sub { Future->done };
}

# Each DBD's own names, spelled out here: the expectation must not be derived
# from the table under test.
my %API = (
  mysql   => { fd => 'mysql_fd',       ssl => 'mysql_ssl',   ssl_optional => 'mysql_ssl_optional' },
  MariaDB => { fd => 'mariadb_sockfd', ssl => 'mariadb_ssl', ssl_optional => 'mariadb_ssl_optional' },
);
my ($dbd) = $dsn =~ /\Adbi:(\w+):/;
plan skip_all => 'DBIO_TEST_MYSQL_DSN names neither dbi:mysql: nor dbi:MariaDB:'
  unless defined $dbd && $API{$dbd};
my $api = $API{$dbd};

# A schema always declares its driver (core ADR 0067), and DBIO::Test::Schema
# keeps none in its class: declare the storage class the DSN's DBD is
# registered for -- DBIO::MySQL::Storage::MariaDB for a dbi:MariaDB: DSN.
my $test_schema = DBIO::Test::Schema->clone;
$test_schema->storage_type(
  $dsn =~ /\Adbi:MariaDB:/i ? '+DBIO::MySQL::Storage::MariaDB' : '+DBIO::MySQL::Storage'
);

my $loop = IO::Async::Loop->new;

sub wait_until {
  my ($cond, $timeout) = @_;
  my $deadline = Time::HiRes::time() + ($timeout // 10);
  until ($cond->()) {
    return 0 if Time::HiRes::time() > $deadline;
    $loop->loop_once(0.05);
  }
  return 1;
}

sub socket_readable {
  my ($fd, $timeout) = @_;
  my $rin = '';
  vec($rin, $fd, 1) = 1;
  my $found;
  do { $found = select(my $rout = $rin, undef, undef, $timeout) }
    while $found < 0 && $!{EINTR};
  return $found;
}

# The other sessions: one kills and is asked what the server lists, one holds
# a row lock for the statements below to wait on.
sub raw { DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 }) }
my $killer  = raw();
my $version = $killer->selectrow_array('SELECT VERSION()');
note "server $version, DBD::$dbd " . "DBD::$dbd"->VERSION . ', client library ' . ($killer->{ lc($dbd) . '_clientinfo' } // 'unknown');

my $T = "dbio_k65_$$";
my $P = "dbio_k65_p_$$";
my $holder;

sub drop_fixture {
  local $killer->{Warn} = 0;
  $killer->do("DROP PROCEDURE IF EXISTS `$P`");
  $killer->do("DROP TABLE IF EXISTS `$T`");
}

# Whatever happens below: the lock goes first, so that nothing waits on it,
# then the fixture.
END {
  if ($killer) {
    local ($@, $?);
    eval { $holder->disconnect } if $holder;
    eval { drop_fixture() };
  }
}

drop_fixture();
$killer->do("CREATE TABLE `$T` (id INT NOT NULL PRIMARY KEY, v INT NOT NULL) ENGINE=InnoDB");
$killer->do("INSERT INTO `$T` (id, v) VALUES (1, 0), (2, 0)");
$killer->do("CREATE PROCEDURE `$P`() BEGIN SELECT 1 AS a; SELECT 2 AS b; END");

$holder = raw();
$holder->begin_work;
$holder->do("UPDATE `$T` SET v = 1 WHERE id = 1");

# A statement that waits for the row the holder has locked, until it is
# killed.
my $BLOCKED = "UPDATE `$T` SET v = v + 1 WHERE id = 1";

sub session_gone {
  !$killer->selectrow_array('SELECT 1 FROM information_schema.PROCESSLIST WHERE ID = ?', undef, $_[0]);
}
sub statement_running {
  $killer->selectrow_array(
    'SELECT 1 FROM information_schema.PROCESSLIST WHERE ID = ? AND INFO LIKE ?', undef, $_[0], 'UPDATE%',
  );
}

# The seam, watched: what the handle said when it was asked, what it answered,
# and -- asked of the server only after it has answered -- whether the session
# is still there. And the borrow-time check, held at its default unless a test
# switches it on.
my @asked;
our $BORROW_TIME_CHECK = 0;
{
  my $fatal = \&DBIO::MySQL::Storage::Async::_conn_error_is_fatal;
  my $alive = \&DBIO::MySQL::Storage::Async::_idle_connection_alive;
  no warnings 'redefine';
  *DBIO::MySQL::Storage::Async::_conn_error_is_fatal = sub {
    my $dbh = ref $_[1] eq 'HASH' ? $_[1]{dbh} : undef;
    my %ask = ( err => $dbh && $dbh->err, errstr => $dbh && $dbh->errstr );
    $ask{verdict} = $fatal->(@_) ? 1 : 0;
    $ask{alive}   = $dbh && eval { $dbh->ping } ? 1 : 0;
    push @asked, \%ask;
    return $ask{verdict};
  };
  *DBIO::MySQL::Storage::Async::_idle_connection_alive = sub {
    return $BORROW_TIME_CHECK ? $alive->(@_) : 1;
  };
}

sub session_id { my @rows = $_[0]->_query_async('SELECT CONNECTION_ID()', [])->get; $rows[0][0] }
sub pool_connections { grep { defined } @{ $_[0]->pool->{_connections} } }
sub numbers { join ', ', map { ($_->{err} // 'none') . ' (' . ($_->{errstr} // '') . ')' } @_ }

# Send KILL $kill once the server lists $id's statement as running, and wait
# for the statement's Future.
sub kill_while_running {
  my ($label, $id, $f, $kill) = @_;
  ok wait_until(sub { statement_running($id) }, 5),
    "$label: the statement is running on the borrowed connection, waiting for a row lock"
    or die "the statement never showed up on session $id\n";
  $killer->do("KILL $kill " . int $id);
  ok wait_until(sub { $f->is_ready }, 10), "... and settles after KILL $kill"
    or die "the statement did not settle after the KILL\n";
  return;
}

# The session behind $conn is gone, and the seam said so: the pool dropped it
# at its release, and the next call -- with no borrow-time check to help --
# runs on a fresh session.
sub retired_and_fresh {
  my ($label, $async, $conn, $id) = @_;
  ok !$conn->{dbh}{Active} && !( grep { $_ == $conn } pool_connections($async) ),
    "$label: the pool retired the connection at its release";
  my $next = eval { session_id($async) };
  is $@, '', '... and the next call returns no error';
  ok defined $next && $next != $id, '... on a fresh session';
  return $next;
}

# A case above failed and left the pool without a usable connection: get it
# one, with the borrow-time check's help, so that the cases after it are still
# shown. Dies if not even that works.
sub recovered {
  my ($async) = @_;
  local $BORROW_TIME_CHECK = 1;
  return session_id($async);
}

sub scenario {
  my ($label, $attrs, $want_tls) = @_;

  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };

  my $schema = $test_schema->connect(
    $dsn, $user, $pass, { async => 'future_io', pool_size => 1, %$attrs },
  );
  my $async = $schema->storage->async;

  my $done = eval {
    my $id = session_id($async);
    if ($want_tls) {
      my @status = $async->_query_async(q{SHOW SESSION STATUS LIKE 'Ssl_version'}, [])->get;
      like $status[0][1], qr/\ATLS/, "$label: the pool session is encrypted ($status[0][1])"
        or die "not a TLS session -- nothing below would be about TLS\n";
      $label = $status[0][1];
    }

    # -- 2. the control first, on the session the pool starts with: a failed
    #       statement that leaves it where it was.
    for my $case (
      [ 1062, 'a duplicate key', "INSERT INTO `$T` (id, v) VALUES (2, 0)" ],
      [ 1064, 'a syntax error',  'SELEKT 1' ],
      [ 1317, 'KILL QUERY',      $BLOCKED ],
    ) {
      my ($code, $what, $sql) = @$case;
      $id = session_id($async);
      @asked = ();
      my $f = $async->_query_async($sql, []);
      kill_while_running("$label, $what", $id, $f, 'QUERY') if $code == 1317;
      wait_until(sub { $f->is_ready }, 10);
      ok $f->is_ready && $f->is_failed, "$label, $what: the statement fails";
      is scalar(@asked), 1, '... the seam is asked once';
      is $asked[0]{err}, $code, "... with $code on the handle";
      ok $asked[0]{alive}, '... the session is still there';
      ok !$asked[0]{verdict}, '... and the seam says so: kept';
      is eval { session_id($async) }, $id, '... the next call runs on the SAME session';
    }
    is_deeply \@warnings, [], "$label: a statement error warns about nothing";
    $id = session_id($async);

    # -- 1. KILL CONNECTION while a statement runs: through _query_async ...
    {
      my ($conn) = pool_connections($async);
      @asked = ();
      my $f = $async->_query_async($BLOCKED, []);
      kill_while_running("$label, KILL CONNECTION", $id, $f, 'CONNECTION');
      ok $f->is_failed, '... it fails';
      is scalar(@asked), 1, '... the seam is asked once';
      ok !$asked[0]{alive}, '... the session is gone';
      ok $asked[0]{verdict}, '... and the seam says so: dead';
      note "$label: KILL CONNECTION while a statement runs arrives as " . numbers(@asked);
      $id = retired_and_fresh("$label, KILL CONNECTION", $async, $conn, $id);
      $id //= recovered($async);
    }

    #       ... and on the pinned connection of a transaction.
    {
      my ($conn, $pinned);
      @asked = ();
      my $f = $async->txn_do_async(sub {
        my ($txn) = @_;
        $conn = $txn->txn_conn;
        return $txn->_query_async('SELECT CONNECTION_ID()', [])->then(sub {
          $pinned = $_[0][0];
          return $txn->_query_async($BLOCKED, []);
        });
      });
      ok wait_until(sub { defined $pinned }, 5), "$label, KILL CONNECTION in txn_do_async: the transaction is open"
        or die "the transaction never started\n";
      is $pinned, $id, '... on the pool\'s one connection';
      kill_while_running("$label, KILL CONNECTION in txn_do_async", $pinned, $f, 'CONNECTION');
      ok $f->is_failed, '... the transaction fails';
      ok scalar(@asked), '... the seam is asked';
      ok !( grep { $_->{alive} } @asked ), '... the session is gone';
      ok !( grep { !$_->{verdict} } @asked ), '... and the seam says so each time: dead';
      note "$label: in a transaction it arrives as " . numbers(@asked)
        . ' -- the statement, then the ROLLBACK core still sends';
      $id = retired_and_fresh("$label, KILL CONNECTION in txn_do_async", $async, $conn, $pinned);
      $id //= recovered($async);
    }

    # -- 3. a statement on a connection that died while it sat idle. Killed:
    {
      my ($conn) = pool_connections($async);
      $killer->do('KILL ' . int $id);
      is socket_readable($conn->{dbh}->${\ $api->{fd} }, 5), 1,
        "$label, killed while idle: the close has reached the idle socket"
        or die "the socket stayed quiet\n";
      @asked = ();
      ok !defined eval { session_id($async) }, '... the statement it is handed out for fails';
      is scalar(@asked), 1, '... the seam is asked once';
      ok !$asked[0]{alive}, '... the session is gone';
      ok $asked[0]{verdict}, '... and the seam says so: dead';
      note "$label: a statement on a connection killed while idle fails with " . numbers(@asked);
      $id = retired_and_fresh("$label, killed while idle", $async, $conn, $id);
      $id //= recovered($async);
    }

    #       Timed out by the server, twice: what follows a miss is shown
    #       without the borrow-time check and with it.
    for my $with_check (0, 1) {
      my $case = "$label, wait_timeout" . ($with_check ? ' (borrow-time check on afterwards)' : '');
      $async->_query_async('SET SESSION wait_timeout = 1', [])->get;
      is session_id($async), $id, "$case: set on the pool's session";
      my ($conn) = pool_connections($async);
      is socket_readable($conn->{dbh}->${\ $api->{fd} }, 10), 1, '... the server ends it, which reaches the idle socket'
        or die "the socket stayed quiet\n";
      ok wait_until(sub { session_gone($id) }, 5), '... and the server no longer lists the session';

      @asked = ();
      ok !defined eval { session_id($async) }, '... the statement it is handed out for fails';
      is scalar(@asked), 1, '... the seam is asked once';
      ok !$asked[0]{alive}, '... the session is gone';
      my $ask = $asked[0];
      note "$case: a statement after wait_timeout fails with " . numbers($ask);
      ok $ask->{verdict}, '... and the seam says so: dead';

      if ($ask->{verdict}) {
        $id = retired_and_fresh($case, $async, $conn, $id);
      }
      else {
        # The miss, as it stands: the dead connection is idle in the pool again.
        ok scalar( grep { $_ == $conn } pool_connections($async) ),
          "$case: missed -- the dead connection is back on the idle list";
        if ($with_check) {
          local $BORROW_TIME_CHECK = 1;
          my $next = eval { session_id($async) };
          is $@, '', '... with the borrow-time check the next call returns no error';
          ok defined $next && $next != $id, '... on a fresh session: the miss cost the one call';
          $id = $next;
        }
        else {
          @asked = ();
          ok !defined eval { session_id($async) }, '... without the borrow-time check one more call fails';
          ok @asked == 1 && $asked[0]{verdict}, '... under a number the seam lists (' . numbers(@asked) . ')';
          $id = retired_and_fresh($case, $async, $conn, $id);
        }
      }
      $id //= recovered($async);
    }
    1;
  };
  ok $done, "$label: ran to its end" or diag $@;
  eval { $async->disconnect };

  # -- 4b. the warnings of the handles dropped above. The failure itself
  #        reached the caller as a failed Future each time.
  my @known = grep {
    /disconnect invalidates \d+ active statement handle/ || /\(in cleanup\) DBD::\w+::st DESTROY failed/
  } @warnings;
  my %known = map { $_ => 1 } @known;
  is_deeply [ grep { !$known{$_} } @warnings ], [], "$label: no warning at all";
  is scalar(@known), 0, "$label: a connection that died warns about nothing";
  return;
}

scenario('plain', {}, 0);

SKIP: {
  my %tls = ( $api->{ssl} => 1, $api->{ssl_optional} => 1 );
  my $probe = eval { DBI->connect($dsn, $user, $pass, { RaiseError => 1, PrintError => 0, %tls }) };
  my $tls_version = $probe && ($probe->selectrow_array(q{SHOW SESSION STATUS LIKE 'Ssl_version'}))[1];
  $probe->disconnect if $probe;
  skip "no TLS session to be had from this server through DBD::$dbd -- the TLS half is not shown", 1
    unless $tls_version;
  scenario('TLS', \%tls, 1);
}

# -- 4a. A statement that leaves a second result set behind. The collector
#        reads it out (karr k73); the next statement on the pool connection
#        runs, on the SAME session, on both DBDs.
{
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my $schema = $test_schema->connect($dsn, $user, $pass, { async => 'future_io', pool_size => 1 });
  my $async  = $schema->storage->async;

  my $before = session_id($async);
  my @rows = eval { $async->_query_async("CALL `$P`()", [])->get };
  is $@, '', 'a CALL that returns two result sets runs';
  is_deeply \@rows, [ [1] ], '... and resolves with the rows of the first';

  @asked = ();
  my $next = eval { session_id($async) };
  my $failure = $@;
  is $failure, '', '... the next statement on that pool connection runs (karr k73)';
  is $next, $before, '... on the same session: the connection was neither retired nor replaced';
  ok !@asked, '... and the seam was not asked: nothing failed';
  eval { $async->disconnect };
}

$holder->rollback;
$holder->disconnect;
undef $holder;
drop_fixture();
$killer->disconnect;
undef $killer;

done_testing;
