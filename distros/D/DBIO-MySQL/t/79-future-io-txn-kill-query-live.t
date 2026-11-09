use strict;
use warnings;
use Test::More;
use Time::HiRes ();
use Scalar::Util ();

# LIVE half of t/71 (karr k71, point 2): a statement the server interrupts
# inside a txn_do_async ends that transaction and nothing else -- the session
# lives, the transaction is rolled back by us, and the connection is used
# again.
#
# WHY IT MATTERS. For an interrupted statement, as for most statement errors,
# MySQL and MariaDB undo that statement and leave the transaction open: a
# COMMIT after it would succeed and keep the half of the block that ran. So
# the transport must neither take the error for a lost connection (the
# connection would be closed and the pool refilled for every statement
# timeout) nor leave the transaction as it is (the next borrower's statement
# would land inside it). t/71 pins that offline, over a fake server that
# interrupts when the test says so. What only a server can show is what t/71
# assumes of it: that an interrupted statement arrives as an error at its
# result, under which number, and that session and transaction are open
# afterwards.
#
# t/77 already shows, for the POOL path and KILL QUERY only: error 1317, the
# session answers a ping, the seam says "kept", the next call runs on the same
# session. Nothing there is in a transaction, and no statement timeout.
#
# What this file claims, on a pool of one, for an interrupted statement in a
# transaction -- by KILL QUERY from another session (1317) and by the server's
# own statement timeout (MySQL: the MAX_EXECUTION_TIME hint, 3024; MariaDB:
# SET STATEMENT max_statement_time, 1969):
#   1. the statement fails at its result with that number, and
#      _conn_error_is_fatal keeps the connection;
#   2. session and transaction are still open: asked from inside the block,
#      after the failure, the session is the same, it still sees the row the
#      block wrote before, and another session does not;
#   3. the transaction then fails with the interrupted statement's error, and
#      ROLLBACK has run: the row is gone for that session too, and nobody else
#      ever saw it;
#   4. the same when nobody looks at the failed statement and the block just
#      returns its Future;
#   5. the connection is used again: the next call runs on the same session,
#      on the pool's one connection, and commits on its own.
#
# NO BLIND WAITING: KILL QUERY is sent once the server lists the statement as
# running (it waits for a row lock another session holds); the timeouts are
# the server's.
#
# Runs through whichever DBD the DSN names. Gated like the other live tests:
# needs DBIO_TEST_MYSQL_DSN, _USER and _PASS. Creates and drops a table of its
# own.

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
use Future;
use DBIO::Test;

eval { require DBIO::MySQL::Storage::Async; 1 }
  or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
plan skip_all => 'the installed dbio-async predates the _conn_error_is_fatal seam (dbio-async k26)'
  unless DBIO::Async::Storage->can('_conn_error_is_fatal');

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

sub raw { DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 }) }
my $other   = raw();   # kills, and is "another session"
my $version = $other->selectrow_array('SELECT VERSION()');
my $mariadb = $version =~ /MariaDB/i ? 1 : 0;
my ($dbd)   = $dsn =~ /\Adbi:(\w+):/;
note "server $version, DBD::$dbd " . "DBD::$dbd"->VERSION;

my $T = "dbio_k71_txn_$$";
my ($holder, $schema, $async);

# Whatever happens below, in this order: the pool's sessions go first -- one
# left inside a transaction on the table would make the DROP wait for its
# metadata lock, for good --, then the row lock, then the table.
END {
  if ($other) {
    local ($@, $?);
    eval { $async->disconnect } if $async;
    eval { $holder->disconnect } if $holder;
    eval { $other->do("DROP TABLE IF EXISTS `$T`") };
  }
}

# A statement nobody answers would leave its Future pending for good.
local $SIG{ALRM} = sub { die "t/79 timed out: a Future never settled\n" };
alarm 120;

$other->do("DROP TABLE IF EXISTS `$T`");
$other->do("CREATE TABLE `$T` (id INT NOT NULL PRIMARY KEY, v INT NOT NULL) ENGINE=InnoDB");
$other->do("INSERT INTO `$T` (id, v) VALUES (1, 0)");

# Row 1 stays locked, so a statement that wants it waits.
$holder = raw();
$holder->begin_work;
$holder->do("UPDATE `$T` SET v = 1 WHERE id = 1");

# The ways a statement is interrupted: [ label, the statement, the number it
# fails with, whether another session has to send KILL QUERY ].
my @INTERRUPTS = (
  [ 'KILL QUERY', "UPDATE `$T` SET v = v + 1 WHERE id = 1", 1317, 1 ],
  $mariadb
    ? [ 'SET STATEMENT max_statement_time',
        "SET STATEMENT max_statement_time=0.3 FOR UPDATE `$T` SET v = v + 1 WHERE id = 1", 1969, 0 ]
    : [ 'the MAX_EXECUTION_TIME hint',
        "SELECT /*+ MAX_EXECUTION_TIME(300) */ v FROM `$T` WHERE id = 1 FOR UPDATE", 3024, 0 ],
);

# The seam, watched: the number on the handle and the answer.
my @asked;
{
  my $fatal = \&DBIO::MySQL::Storage::Async::_conn_error_is_fatal;
  no warnings 'redefine';
  *DBIO::MySQL::Storage::Async::_conn_error_is_fatal = sub {
    my $dbh     = ref $_[1] eq 'HASH' ? $_[1]{dbh} : undef;
    my $err     = $dbh && $dbh->err;
    my $verdict = $fatal->(@_) ? 1 : 0;
    push @asked, [ $err, $verdict ];
    return $verdict;
  };
}

# The transport has no session reset (core ADR 0079): the pool retires its
# connection at the end of every borrow. This file asks that a transaction whose
# statement the server interrupted ends in a ROLLBACK and hands back the SAME
# session, clean, and that is only visible on a connection that is handed back.
# So the pool gets the reset a server with a session reset would give, done at
# once and touching nothing: the open transaction the claim looks at is the one
# the server's session has until the transport's ROLLBACK, not one a stub ends.
# Server and DBD stay real.
{
  no warnings 'redefine';
  *DBIO::MySQL::Storage::Async::_reset_pool_connection = sub { Future->done };
}

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

$schema = $test_schema->connect($dsn, $user, $pass, { async => 'future_io', pool_size => 1 });
$async  = $schema->storage->async;

sub session_id { my @rows = $async->_query_async('SELECT CONNECTION_ID()', [])->get; $rows[0][0] }
sub pool_connections { grep { defined } @{ $async->pool->{_connections} } }
sub seen_by_other { scalar $other->selectrow_array("SELECT COUNT(*) FROM `$T` WHERE id = ?", undef, $_[0]) }
sub running {
  $other->selectrow_array(
    'SELECT 1 FROM information_schema.PROCESSLIST WHERE ID = ? AND INFO LIKE ?', undef, $_[0], 'UPDATE%',
  );
}

my $row = 10;

for my $interrupt (@INTERRUPTS) {
  my ($how, $statement, $number, $needs_kill) = @$interrupt;

  for my $looked_at (1, 0) {
    my $label = "$how, " . ($looked_at ? 'the block looks at the failure' : 'nobody looks at the failure');
    my $done  = eval {
    my $session = session_id();
    my ($conn)  = pool_connections();
    my $mine    = ++$row;
    my (%inside, $in_flight);
    @asked = ();

    my $txn = $async->txn_do_async(sub {
      my ($t) = @_;
      my $f = $t->_query_async("INSERT INTO `$T` (id, v) VALUES (?, 1)", [$mine])->then(sub {
        $in_flight = 1;
        return $t->_query_async($statement, []);
      });
      return $f unless $looked_at;

      # Still inside the block, after the statement failed: what the session
      # is and sees. Then the failure is handed on, as the block's outcome.
      return $f->else(sub {
        my @failure = @_;
        return $t->_query_async(
          "SELECT CONNECTION_ID(), (SELECT COUNT(*) FROM `$T` WHERE id = ?)", [$mine],
        )->then(sub {
          @inside{qw( session sees )} = @{ $_[0] };
          $inside{other_sees} = seen_by_other($mine);
          return Future->fail(@failure);
        });
      });
    });

    if ($needs_kill) {
      ok wait_until(sub { $in_flight && running($session) }, 5),
        "$label: the statement is running in the transaction, waiting for a row lock"
        or die "the statement never showed up on session $session\n";
      $other->do('KILL QUERY ' . int $session);
    }
    ok wait_until(sub { $txn->is_ready }, 10), "$label: the transaction settles"
      or die "the transaction did not settle\n";

    # 1. the number, and the seam's answer
    is scalar(@asked), 1, '... one statement failed';
    is $asked[0] && $asked[0][0], $number, "... with $number on the handle";
    ok $asked[0] && !$asked[0][1], '... and _conn_error_is_fatal keeps the connection';

    # 2. session and transaction open after it
    if ($looked_at) {
      is $inside{session}, $session, '... inside the block, after the failure: the same session';
      is $inside{sees}, 1, '... which still sees the row the block wrote before -- the transaction is open';
      is $inside{other_sees}, 0, '... and another session does not: nothing was committed';
    }

    # 3. / 4. the transaction's outcome
    ok $txn->is_ready && $txn->is_failed, '... the transaction fails';
    like scalar($txn->failure), qr/Query execution was interrupted/, '... with the interrupted statement\'s error';
    is seen_by_other($mine), 0, '... and its row is not there for anybody else';

    # 5. the connection, afterwards
    my @rows = eval { $async->_query_async("SELECT CONNECTION_ID(), (SELECT COUNT(*) FROM `$T` WHERE id = ?)", [$mine])->get };
    is $@, '', "$label: the next call returns no error";
    is $rows[0] && $rows[0][0], $session, '... on the same session';
    is $rows[0] && $rows[0][1], 0, '... which no longer sees the row: ROLLBACK ran';
    my @conns = pool_connections();
    ok @conns == 1 && $conns[0] == $conn, '... on the pool\'s one connection, the same as before';

    my $kept = ++$row;
    $async->_query_async("INSERT INTO `$T` (id, v) VALUES (?, 2)", [$kept])->get;
    is seen_by_other($kept), 1, '... and a statement on it afterwards is committed on its own -- no transaction is left open';
    1;
    };
    ok $done, "$label: ran to its end" or diag $@;
  }
}

is_deeply \@warnings, [], 'none of it warned';

alarm 0;
$async->disconnect;
undef $async;
$holder->rollback;
$holder->disconnect;
undef $holder;
$other->do("DROP TABLE IF EXISTS `$T`");
$other->disconnect;
undef $other;

done_testing;
