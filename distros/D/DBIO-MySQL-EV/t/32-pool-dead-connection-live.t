use strict;
use warnings;
use Test::More;
use Time::HiRes ();
use Socket ();

# LIVE counterpart of t/32-pool-dead-connection-mock.t: a pooled connection
# whose session is gone is retired and never handed out again (karr k55:
# reported after a failed statement; karr k58: asked about before an idle
# connection is borrowed, DBIO::MySQL::EV::Pool::_idle_connection_alive).
#
# The offline file pins the logic against doubles. Only a server can say
# whether the handle's socket / pending_count really tell a dead session from a
# live one, and -- the question the borrow-time check lives or dies by --
# whether a HEALTHY idle connection is ever taken for gone (a readable idle
# socket: a TLS 1.3 record, the further result sets of a CALL). That would turn
# the pool silently into connect-per-call, without a single error to show for
# it, so section "c)" and "d)" count what the pool did, not only what the
# caller saw: the CONNECTION_ID the caller ran on, connections opened,
# connections retired, borrow-time checks answered "gone".
#
#   a) k55: the session ends AFTER the borrow (KILL during a statement)
#   b) k55: a statement error the session survives keeps the session
#   c) k58: the session ends while the connection is idle (KILL, wait_timeout)
#   d) k58: a healthy idle connection is never taken for gone -- plain TCP and
#      TLS, with proof that the session really speaks TLS
#   e) k58: a CALL that returns one or two result sets leaves a healthy
#      connection, measured on the socket -- with bind values; without them
#      (EV::MariaDB's query) over plain TCP that was a known state until
#      karr k84, see g)
#   f) k58: the same question for a call chained in the callback of the
#      previous one
#   g) k83: why a CALL via query() does not leave one -- its Future settles
#      before the rest of its answer was read -- shown with a procedure that
#      sleeps after its result set, so no luck is needed, and what a caller
#      sees of it
#   h) k75: a multi-statement text is refused by the server and leaves the
#      session
#
# Every number the measurements read off the handle is a diag line, so a run
# documents what EV::MariaDB reports (socket, error_number, is_connected,
# pending_count) at the moment the pool is told. Every wait is bounded and the
# file has an alarm; the objects it creates (a table, three procedures) are
# unique to this run and removed in END, after the pool's sessions were ended.
# Passwords never appear: the DSN, user and password come from the environment.
#
# TLS here is the transport's own: with a ssl_* parameter in the DSN its handles
# get a non-blocking socket after the connect (karr k85), so every TLS case below
# runs with statements that leave the loop running, as plain TCP does. t/52 holds
# that. The TLS assertions of this file were green before the work-around and are
# green with it (MySQL 8.0 and MariaDB 11): none of them depended on the blocking.
#
# Not covered (no server access from here): a Unix socket; TLS 1.2 -- EV::MariaDB
# offers no tls_version option and both servers negotiate 1.3 with it.
#
# Gated like the other live tests: DBIO_TEST_MYSQL_DSN (dbi:mysql: or
# dbi:MariaDB:), _USER, _PASS, plus EV and EV::MariaDB.

use DBIO::MySQL::EV::TestHarness;

DBIO::MySQL::EV::TestHarness->skip_all_unless_live;

use DBI;
use DBIO::Util ();
use EV;
use DBIO::MySQL::EV::Pool ();   # loaded before the hooks wrap its methods

$SIG{ALRM} = sub { BAIL_OUT('t/32-pool-dead-connection-live.t: alarm, a wait did not end') };
alarm 300;

my ($DSN, $USER, $PASS) = map { $ENV{"DBIO_TEST_MYSQL_$_"} } qw( DSN USER PASS );

# ---------------------------------------------------------------- a Result class
{
  package T32::Item;
  use base 'DBIO::Core';
  __PACKAGE__->table("dbio_k55_item_$$");
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 50 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(name_uniq => ['name']);

  package T32::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL', 'MySQL::EV');
  __PACKAGE__->register_class(Item => 'T32::Item');
}
my $TABLE = "dbio_k55_item_$$";
my $P1    = "dbio_k58_one_$$";
my $P2    = "dbio_k58_two_$$";
my $PS    = "dbio_k83_slow_$$";
my $SLOW  = 0.4;   # seconds $PS sleeps after its result set

# ---------------------------------------------------------------- measuring hooks
# Wrapped once, for the whole file: what the pool did.
our (%C, @MEASURE, @PEEK);

# What is waiting on a handle's socket, without taking it off: MSG_PEEK on a
# dup of the descriptor. Plain TCP shows the MySQL packet itself; on TLS it is
# the record. An end of file reads as 'eof'.
sub peek_socket {
  my ($mdb) = @_;
  my $fd = $mdb->socket;
  return 'no socket' unless defined $fd && $fd >= 0;
  open(my $fh, '<&', $fd) or return "dup failed: $!";
  my $buf = '';
  my $r = recv($fh, $buf, 16, Socket::MSG_PEEK() | Socket::MSG_DONTWAIT());
  close $fh;
  return 'recv failed' unless defined $r;
  return length($buf) ? 'peek ' . unpack('H*', $buf) : 'eof';
}
{
  no warnings 'redefine';
  my $new   = \&DBIO::MySQL::EV::Pool::_new_connection;
  my $alive = \&DBIO::MySQL::EV::Pool::_idle_connection_alive;
  my $rep   = \&DBIO::MySQL::EV::Pool::_mysql_report_if_gone;
  my $ret   = \&DBIO::Storage::PoolBase::_retire_connection;
  my $mark  = \&DBIO::Storage::PoolBase::_mark_connection_dead;

  *DBIO::MySQL::EV::Pool::_new_connection = sub { $C{opened}++; goto &$new };
  *DBIO::Storage::PoolBase::_retire_connection = sub { $C{retired}++; goto &$ret };
  *DBIO::Storage::PoolBase::_mark_connection_dead = sub { $C{marked_dead}++; goto &$mark };
  *DBIO::MySQL::EV::Pool::_idle_connection_alive = sub {
    my $a = $alive->(@_);
    $C{alive_asked}++;
    unless ($a) {
      $C{alive_false}++;
      push @PEEK, peek_socket($_[1]);
    }
    return $a;
  };
  # What the handle says at the moment the pool is told about a failure.
  *DBIO::MySQL::EV::Pool::_mysql_report_if_gone = sub {
    my ($pool, $mdb) = @_;
    push @MEASURE, {
      socket        => scalar $mdb->socket,
      error_number  => scalar $mdb->error_number,
      is_connected  => scalar $mdb->is_connected,
      pending_count => scalar $mdb->pending_count,
      gone          => $pool->_mysql_connection_gone($mdb) ? 1 : 0,
    };
    goto &$rep;
  };
}
sub reset_counts { %C = (); @MEASURE = (); @PEEK = () }
sub counts { join ' ', map { "$_=" . ($C{$_} // 0) } qw( opened retired marked_dead alive_asked alive_false ) }
sub measure_str {
  my ($m) = @_;
  return join ' ', map { "$_=" . ($m->{$_} // 'undef') } qw( socket error_number is_connected pending_count gone );
}

# ---------------------------------------------------------------- helpers
sub wait_until {
  my ($cond, $timeout) = @_;
  my $deadline = Time::HiRes::time() + ($timeout // 15);
  until ($cond->()) {
    return 0 if Time::HiRes::time() > $deadline;
    EV::run(EV::RUN_ONCE());
  }
  return 1;
}
my $TICK = EV::timer(0.02, 0.02, sub {});   # RUN_ONCE never blocks for long

sub pause {
  my ($s) = @_;
  my $done = 0;
  my $t = EV::timer($s, 0, sub { $done = 1 });
  wait_until(sub { $done }, $s + 5);
}

# Wait WITHOUT a loop turn: what the server sends meanwhile stays in the
# kernel's buffer, unread by EV::MariaDB.
sub block_without_loop {
  my ($s) = @_;
  my $deadline = Time::HiRes::time() + $s;
  while ((my $left = $deadline - Time::HiRes::time()) > 0) {
    select(undef, undef, undef, $left);
  }
}

# karr k83 (found with k58), fixed by karr k84. EV::MariaDB 0.08 calls back
# with the first result of a query() and reads the rest of the answer -- the
# closing OK packet of a CALL, its further result sets -- only after that
# callback returned, and nothing on the handle says so. The executor therefore
# sends a CALL without bind values through prepare/execute/close_stmt, where
# the whole answer is read before the Future settles. Sections e) to g) hold
# that: the next statement, with or without bind values, pooled or pinned, runs
# on the session the CALL ran on.

sub raw {
  # DBI dies quoting the DSN: named without a password it may carry (karr k76).
  my $dbh = eval {
    DBI->connect($DSN, $USER, $PASS, {
      AutoCommit => 1, RaiseError => 1, PrintError => 0, AutoInactiveDestroy => 1,
    });
  } or die DBIO::Util::mask_connect_secrets("$@", [ $DSN, $USER, $PASS ]);
  return $dbh;
}

my $admin = raw();

# Wait for $f, return ($ok, $value_or_error). A rows result is the first row.
sub settle {
  my ($f, $t) = @_;
  wait_until(sub { $f->is_ready }, $t // 20) or return (undef, 'still pending');
  return $f->is_failed ? (0, scalar $f->failure) : (1, ($f->get)[0]);
}

my ($H, @ALL_H);
sub new_harness {
  my (%o) = @_;
  my $h = DBIO::MySQL::EV::TestHarness->new(
    schema_class  => 'T32::Schema',
    connect_attrs => { pool_size => $o{pool_size} // 1, ($o{on_connect_do} ? (on_connect_do => $o{on_connect_do}) : ()) },
    ($o{dsn} ? (dsn => $o{dsn}) : ()),
  );
  push @ALL_H, $h;
  $h->warm_pool;
  $H = $h;
  reset_counts();
  return $h;
}
sub end_harness { my ($h) = @_; eval { $h->disconnect }; $H = undef }

sub cid_of {
  my ($async) = @_;
  my ($ok, $row) = settle($async->_query_async('SELECT CONNECTION_ID()'));
  # the reset of the session that was just released (karr k100) is over before
  # the caller goes on: it is a connection idle in the pool the test acts on
  wait_until(sub { !%{ $async->pool->{_resetting} || {} } }, 5);
  return $ok ? $row->[0] : undef;
}

sub server_has {
  my ($tid) = @_;
  return scalar $admin->selectrow_array('SELECT COUNT(*) FROM information_schema.PROCESSLIST WHERE ID = ?', undef, $tid);
}
sub kill_session {
  my ($tid) = @_;
  eval { $admin->do("KILL $tid") };
  return wait_until(sub { !server_has($tid) }, 10);
}
sub running_info_like {
  my ($tid, $like) = @_;
  return scalar $admin->selectrow_array(
    'SELECT COUNT(*) FROM information_schema.PROCESSLIST WHERE ID = ? AND INFO LIKE ?', undef, $tid, $like);
}

# The pool's connection ids, sorted.
sub pool_tids { sort { $a <=> $b } map { $_->thread_id } grep { defined } @{ $_[0]->{_connections} } }

# ---------------------------------------------------------------- server objects
$admin->do("DROP TABLE IF EXISTS `$TABLE`");
$admin->do("CREATE TABLE `$TABLE` (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(50) NOT NULL, UNIQUE KEY name_uniq (name)) ENGINE=InnoDB");
$admin->do("DROP PROCEDURE IF EXISTS `$P1`");
$admin->do("DROP PROCEDURE IF EXISTS `$P2`");
$admin->do("DROP PROCEDURE IF EXISTS `$PS`");
$admin->do("CREATE PROCEDURE `$P1`(IN x INT) BEGIN SELECT x AS one; END");
$admin->do("CREATE PROCEDURE `$P2`(IN x INT) BEGIN SELECT x AS one; SELECT x + 1 AS two; END");
# Its result set is on the wire $SLOW seconds before the answer ends.
$admin->do("CREATE PROCEDURE `$PS`(IN x INT) BEGIN SELECT x AS one; DO SLEEP($SLOW); END");

my $OPENER = $$;
END {
  if (defined $OPENER && $$ == $OPENER) {
    local ($@, $?);
    # The pool's sessions first: one that sits in a transaction or holds a lock
    # would make the DROPs wait for a metadata lock.
    eval { $_->disconnect } for @ALL_H;
    eval {
      my $dbh = raw();
      $dbh->do('SET SESSION lock_wait_timeout = 10');
      $dbh->do("DROP TABLE IF EXISTS `$TABLE`");
      $dbh->do("DROP PROCEDURE IF EXISTS `$P1`");
      $dbh->do("DROP PROCEDURE IF EXISTS `$P2`");
      $dbh->do("DROP PROCEDURE IF EXISTS `$PS`");
      $dbh->disconnect;
    };
  }
}

diag 'server: ' . $admin->selectrow_array('SELECT VERSION()');

# ====================================================================== a)
subtest 'a) k55: the session ends after the borrow, exactly that call fails' => sub {

  for my $path ([ 'query (no bind values)', 'SELECT SLEEP(30)', [] ],
                [ 'prepare/execute (bind values)', 'SELECT SLEEP(?)', [ 30 ] ]) {
    my ($label, $sql, $bind) = @$path;
    subtest "a1) $label" => sub {
      my $h = new_harness();
      my $async = $h->async;
      my $tid = cid_of($async);
      ok $tid, "the pool's session is $tid";

      @MEASURE = ();
      my $f = $async->_query_async($sql, $bind);
      ok wait_until(sub { running_info_like($tid, 'SELECT SLEEP(%') }, 10), 'the statement runs on the server';
      ok kill_session($tid), '... and its session is ended by a second session';
      my ($ok, $err) = settle($f);
      ok !$ok, 'exactly that call fails' or diag "result: " . (ref $err ? "row @$err" : $err);
      diag "error: $err" unless $ok;
      ok wait_until(sub { $h->pool->size == 0 }, 5), 'the connection is retired: the pool holds none';
      is $C{marked_dead} // 0, 1, 'it was reported to _mark_connection_dead once';
      diag "$label, handle when the pool was told: " . measure_str($_) for @MEASURE;
      ok scalar(@MEASURE) >= 1, 'the failed statement had the pool asked about its handle';
      is $MEASURE[0]{gone}, 1, '... which answered "gone"' if @MEASURE;

      my $tid2 = cid_of($async);
      ok $tid2, 'the next call runs';
      isnt $tid2, $tid, '... on a new session (CONNECTION_ID differs)';
      is $h->pool->size, 1, 'the pool holds one connection again';
      end_harness($h);
    };
  }

  subtest 'a2) a caller queued for the connection gets a new session' => sub {
    my $h = new_harness();
    my $async = $h->async;
    my $tid = cid_of($async);
    my $f1 = $async->_query_async('SELECT SLEEP(30)');
    my $f2 = $async->_query_async('SELECT CONNECTION_ID()');   # pool of one: queued
    ok wait_until(sub { running_info_like($tid, 'SELECT SLEEP(%') }, 10), 'the first statement runs on the server';
    ok !$f2->is_ready, '... queued for the one connection';
    kill_session($tid);
    my ($ok1) = settle($f1);
    ok !$ok1, 'the first call fails';
    my ($ok2, $row) = settle($f2);
    ok $ok2, 'the queued call runs' or diag $row;
    isnt $row->[0], $tid, '... on a new session' if $ok2;
    is $h->pool->size, 1, 'the pool holds one connection';
    end_harness($h);
  };

  subtest 'a3) insert_async after the session ended' => sub {
    my $h = new_harness();
    my $async  = $h->async;
    my $source = $h->schema->source('Item');
    my $tid = cid_of($async);

    my $locker = raw();
    $locker->do("LOCK TABLES `$TABLE` WRITE");
    my $f = $async->insert_async($source, { name => 'a3-lost' });
    ok wait_until(sub { running_info_like($tid, "INSERT INTO%$TABLE%") }, 10), 'the INSERT waits for the lock on the server';
    kill_session($tid);
    my ($ok, $err) = settle($f);
    ok !$ok, 'the insert fails';
    $locker->do('UNLOCK TABLES');
    $locker->disconnect;
    ok wait_until(sub { $h->pool->size == 0 }, 5), 'the connection is retired';
    is scalar $admin->selectrow_array("SELECT COUNT(*) FROM `$TABLE` WHERE name = 'a3-lost'"), 0, 'nothing was written';

    my ($ok2, $ret) = settle($async->insert_async($source, { name => 'a3-ok' }));
    ok $ok2, 'the next insert runs' or diag $ret;
    ok $ret && $ret->{id}, 'it returns the auto-increment id' if $ok2;
    is scalar $admin->selectrow_array("SELECT COUNT(*) FROM `$TABLE` WHERE name = 'a3-ok'"), 1, '... and wrote its row';
    end_harness($h);
  };

  subtest 'a4) the session ends in the middle of txn_do_async' => sub {
    my $h = new_harness();
    my $async = $h->async;
    my $tid = cid_of($async);
    my $t = $async->txn_do_async(sub {
      my ($ctx) = @_;
      return $ctx->_query_async("INSERT INTO `$TABLE` (name) VALUES (?)", [ 'a4-lost' ])
        ->then(sub { $ctx->_query_async('SELECT SLEEP(30)') });
    });
    ok wait_until(sub { running_info_like($tid, 'SELECT SLEEP(%') }, 10), 'the transaction is in its second statement';
    kill_session($tid);
    my ($ok, $err) = settle($t);
    ok !$ok, 'the transaction fails';
    ok wait_until(sub { $h->pool->size == 0 }, 5), 'its pinned connection is retired, not handed back';
    is scalar $admin->selectrow_array("SELECT COUNT(*) FROM `$TABLE` WHERE name = 'a4-lost'"), 0, 'the insert was rolled back by the server';
    my $tid2 = cid_of($async);
    ok $tid2 && $tid2 != $tid, 'the next call runs on a new session';
    my ($ok2) = settle($async->txn_do_async(sub {
      $_[0]->_query_async("INSERT INTO `$TABLE` (name) VALUES (?)", [ 'a4-ok' ]);
    }));
    ok $ok2, 'and so does the next transaction';
    end_harness($h);
  };
};

# ====================================================================== b)
subtest 'b) k55: a statement error the session survives keeps the session' => sub {
  my $h = new_harness();
  my $async = $h->async;
  my $tid = cid_of($async);
  $admin->do("INSERT INTO `$TABLE` (name) VALUES ('b-dup')");
  reset_counts();

  for my $case ([ 'duplicate key (prepare/execute)', "INSERT INTO `$TABLE` (name) VALUES (?)", [ 'b-dup' ] ],
                [ 'duplicate key (query)',           "INSERT INTO `$TABLE` (name) VALUES ('b-dup')", [] ],
                [ 'syntax error (query)',            'SELEKT 1', [] ],
                [ 'syntax error (prepare)',          'SELEKT ?', [ 1 ] ]) {
    my ($label, $sql, $bind) = @$case;
    @MEASURE = ();
    my ($ok, $err) = settle($async->_query_async($sql, $bind));
    ok !$ok, "$label fails";
    diag "$label, handle when the pool was told: " . measure_str($_) for @MEASURE;
    is cid_of($async), $tid, '... and the next call runs on the same session';
  }
  is $h->pool->size, 1, 'the pool still holds its one connection';
  is $C{marked_dead} // 0, 0, 'nothing was reported dead';
  is $C{retired} // 0, 0, 'nothing was retired';
  is $C{opened} // 0, 0, 'no connection was opened meanwhile';
  end_harness($h);
};

# ====================================================================== c)
my @MODES = (
  [ 'tcp' => sub { undef } ],
  [ 'tls' => sub { "$DSN;ssl_cipher=DEFAULT" } ],
);

for my $mode (@MODES) {
  my ($name, $dsn_for) = @$mode;
  my $dsn = $dsn_for->();

  subtest "c) k58: the session ends while the connection is idle ($name)" => sub {
    subtest 'c1) KILL of an idle connection' => sub {
      my $h = new_harness(dsn => $dsn);
      my $async = $h->async;
      my $tid = cid_of($async);
      ok kill_session($tid), "the idle session $tid is ended";
      pause(0.2);
      reset_counts();
      my $tid2 = cid_of($async);
      ok $tid2, 'the next call runs, without an error';
      isnt $tid2, $tid, '... on a new session';
      is $h->pool->size, 1, 'the pool size stays 1';
      is $C{alive_false} // 0, 1, 'the borrow-time check said "gone" once';
      is $C{marked_dead} // 0, 0, '... so no statement had to fail to find out';
      diag "counts: " . counts();
      end_harness($h);
    };

    subtest 'c2) KILL of several idle connections' => sub {
      my $h = new_harness(dsn => $dsn, pool_size => 3);
      my $async = $h->async;
      cid_parallel($async, 3);   # three concurrent statements open three sessions
      my @tids = pool_tids($h->pool);
      is scalar(@tids), 3, 'three pooled sessions';
      kill_session($_) for @tids;
      pause(0.2);
      reset_counts();
      my @after = map { cid_of($async) } 1 .. 4;
      ok !(grep { !defined } @after), 'four calls in a row run, without an error';
      my %old = map { ($_ => 1) } @tids;
      ok !(grep { $old{$_ // 0} } @after), '... none on a session that was ended';
      cmp_ok $h->pool->size, '<=', 3, 'the pool did not grow past its size';
      diag "counts: " . counts() . ' after: @after=' . join(',', map { $_ // 'undef' } @after);
      end_harness($h);
    };

    subtest 'c3) the server ends the idle session by wait_timeout' => sub {
      # A session setting made inside a borrow is gone when the borrow ends (karr
      # k100, core k398); wait_timeout is set by a connect action, which the reset
      # puts back.
      my $h = new_harness(dsn => $dsn, on_connect_do => [ q{SET SESSION wait_timeout = 1} ]);
      my $async = $h->async;
      my ($ok, $wt) = settle($async->_query_async(q{SELECT @@session.wait_timeout}));
      is $wt->[0], 1, q{wait_timeout = 1 is set on the pool session by the connect action};
      my $tid = cid_of($async);
      ok wait_until(sub { !server_has($tid) }, 6), "the server ends session $tid on its own";
      pause(0.3);
      reset_counts();
      my $tid2 = cid_of($async);
      ok $tid2, 'the next call runs, without an error';
      isnt $tid2, $tid, '... on a new session';
      is $h->pool->size, 1, 'the pool size stays 1';
      is $C{alive_false} // 0, 1, 'the borrow-time check said "gone" once';
      diag "counts: " . counts();
      end_harness($h);
    };

    subtest 'c4) no pause between the KILL and the call (race, measured)' => sub {
      my $h = new_harness(dsn => $dsn);
      my $async = $h->async;
      my $tid = cid_of($async);
      eval { $admin->do("KILL $tid") };
      reset_counts();
      my ($ok, $row) = settle($async->_query_async('SELECT CONNECTION_ID()'));
      diag "call right after the KILL: " . ($ok ? "ran on session $row->[0]" : "failed ($row)") . '; ' . counts();
      my $tid2 = cid_of($async);
      ok $tid2 && $tid2 != $tid, 'at the latest the following call runs on a new session';
      end_harness($h);
    } if $name eq 'tcp';
  };
}

# parallel opener for c2: n concurrent statements force n sessions
sub cid_parallel {
  my ($async, $n) = @_;
  my @f = map { $async->_query_async('SELECT CONNECTION_ID(), SLEEP(0.3)') } 1 .. $n;
  return map { my ($ok, $r) = settle($_); $ok ? $r->[0] : () } @f;
}

# ====================================================================== d)
for my $mode (@MODES) {
  my ($name, $dsn_for) = @$mode;
  my $dsn = $dsn_for->();

  subtest "d) k58: a healthy idle connection is never taken for gone ($name)" => sub {
    my $h = new_harness(dsn => $dsn);
    my $async = $h->async;

    my %ssl;
    {
      my $f = $async->_query_async("SHOW SESSION STATUS WHERE Variable_name IN ('Ssl_cipher','Ssl_version')");
      wait_until(sub { $f->is_ready });
      %ssl = map { @$_ } $f->get if $f->is_done;
    }
    diag "$name session: Ssl_version='" . ($ssl{Ssl_version} // '') . "' Ssl_cipher='" . ($ssl{Ssl_cipher} // '') . "'";
    if ($name eq 'tls') {
      ok length($ssl{Ssl_version} // ''), 'the session really speaks TLS (Ssl_version not empty)';
      ok length($ssl{Ssl_cipher}  // ''), '... (Ssl_cipher not empty)';
    }
    else {
      is $ssl{Ssl_cipher} // '', '', 'the plain session has no cipher: the case measures clear text';
    }

    my $tid = cid_of($async);
    reset_counts();
    my @seen;
    my @readable;
    for my $i (1 .. 12) {
      pause($i % 3 ? 0.25 : 1.0);
      # What the borrow-time check will see: is the idle socket readable?
      my ($mdb) = grep { defined } @{ $h->pool->{_connections} };
      my $fd = $mdb->socket;
      my $rin = ''; vec($rin, $fd, 1) = 1;
      push @readable, select(my $rout = $rin, undef, undef, 0);
      push @seen, cid_of($async);
    }
    is_deeply [ grep { !defined $_ || $_ != $tid } @seen ], [], '12 calls with pauses all run on the same CONNECTION_ID';
    is_deeply [ grep { $_ != 0 } @readable ], [], 'the idle socket was never readable between the calls';
    is $C{alive_false} // 0, 0, 'the borrow-time check never said "gone"';
    cmp_ok $C{alive_asked} // 0, '>=', 12, '... and was asked on every borrow';
    is $C{retired} // 0, 0, '0 connections retired';
    is $C{opened} // 0, 0, '0 connections opened';
    diag "counts: " . counts();

    # a long idle stretch
    pause(4);
    my ($mdb) = grep { defined } @{ $h->pool->{_connections} };
    my $fd = $mdb->socket;
    my $rin = ''; vec($rin, $fd, 1) = 1;
    is select(my $rout = $rin, undef, undef, 0), 0, 'after 4 s idle the socket is still not readable';
    is cid_of($async), $tid, '... and the connection is still the same session';
    is $C{alive_false} // 0, 0, 'still no "gone"';
    end_harness($h);
  };
}

# ====================================================================== e)
for my $mode (@MODES) {
  my ($name, $dsn_for) = @$mode;
  my $dsn = $dsn_for->();

  subtest "e) k58: CALL with result sets ($name)" => sub {
    for my $proc ([ '1 result set', $P1 ], [ '2 result sets', $P2 ]) {
      my ($plabel, $p) = @$proc;
      for my $path ([ 'query', "CALL `$p`(7)", [] ], [ 'prepare/execute', "CALL `$p`(?)", [ 7 ] ]) {
        my ($pathlabel, $sql, $bind) = @$path;
        subtest "$plabel, $pathlabel" => sub {
          my $h = new_harness(dsn => $dsn);
          my $async = $h->async;
          my $tid = cid_of($async);
          reset_counts();

          my ($ok, $res) = settle($async->_query_async($sql, $bind));
          ok $ok, "CALL answers" or diag $res;
          # the next call at once, as a caller does
          my $tid_now = cid_of($async);
          ok $tid_now, 'the next call at once runs, without an error';
          pause(0.5);
          is cid_of($async), $tid_now, '... and one after a pause of 0.5 s runs on the session that one ran on';
          cmp_ok $C{opened} // 0, '<=', 1, 'at most one connection was opened meanwhile';
          {
            # A CALL without bind values used to leave the rest of its answer
            # on the socket over plain TCP, so the next call could run on a new
            # session (karr k83). Since karr k84 the executor sends it through
            # prepare/execute and the whole answer is read before the Future
            # settles (measured again 2026-10-22, karr k75): these are hard
            # on both paths, and together with the ones above they say what
            # they always said: every call on the one session, nothing
            # retired, nothing opened.
            is $tid_now, $tid, 'the next call at once runs on the same session';
            is $C{alive_false} // 0, 0, 'the borrow-time check never said "gone"';
            is $C{retired} // 0, 0, '0 connections retired';
            is $C{opened} // 0, 0, '0 connections opened';
          }
          diag "counts: " . counts();
          end_harness($h);
        };
      }
    }

    # The measurement itself, on the handle: what is on the socket, and what
    # is pending, right after the CALL's callback and later on.
    for my $proc ([ '1 result set', $P1 ], [ '2 result sets', $P2 ]) {
      my ($plabel, $p) = @$proc;
      subtest "handle after CALL, $plabel" => sub {
        my $h = new_harness(dsn => $dsn);
        my $pool = $h->pool;
        my $conn;
        my $af = $pool->acquire;
        ok wait_until(sub { $af->is_ready }), 'a connection is borrowed';
        $conn = $af->get;
        my $tid = $conn->thread_id;
        my $snap = sub {
          my ($tag) = @_;
          my $fd = $conn->socket;
          my $rin = ''; vec($rin, $fd, 1) = 1;
          my $r = select(my $rout = $rin, undef, undef, 0);
          return sprintf '%s: socket=%s pending_count=%s readable=%s gone=%s', $tag, $fd, $conn->pending_count, $r,
            $pool->_mysql_connection_gone($conn) ? 1 : 0;
        };
        my (@lines, $done);
        $conn->query("CALL `$p`(7)", sub {
          my ($rows, $err) = @_;
          push @lines, $snap->("in the CALL callback (rows=" . (defined $rows ? 'yes' : 'no') . ", err=" . ($err // '-') . ')');
          my $step = 0;
          my @after = (0, 0.05, 0.3);
          my $next; $next = sub {
            my $d = shift @after;
            unless (defined $d) { $done = 1; undef $next; return }
            my $t; $t = EV::timer($d, 0, sub { push @lines, $snap->("after ${d}s"); undef $t; $next->() });
          };
          $next->();
        });
        ok wait_until(sub { $done }, 10), 'the CALL answers and the probes ran';
        diag "$plabel: $_" for @lines;
        my @gone = grep { /gone=1/ } @lines;
        # The skill text claims this can read as gone; the measurement decides.
        diag(@gone ? "RESULT: $plabel -- a healthy session reads as GONE at some point" : "RESULT: $plabel -- never read as gone");
        $pool->release($conn);
        is cid_of($h->async), $tid, 'the connection, released after the CALL, is borrowed again on the same session';
        end_harness($h);
      };
    }
  };
}

# ====================================================================== f)
# The pattern callers actually write: the next call chained off the previous
# one with ->then. The previous statement's connection is released by its
# Future settling -- inside EV::MariaDB's callback -- and the next call borrows
# it in that same callback, with whatever the callback left on the socket. The
# borrow-time check sees exactly that, so this is where a healthy connection
# could be taken for gone. Measured per statement kind, plain and TLS.
for my $mode (@MODES) {
  my ($name, $dsn_for) = @$mode;
  my $dsn = $dsn_for->();

  subtest "f) k58: the next call chained in the callback of the previous one ($name)" => sub {
    my $h = new_harness(dsn => $dsn);
    my $async = $h->async;
    my $source = $h->schema->source('Item');
    my $tid = cid_of($async);
    my $n = 0;
    my @kinds = (
      [ 'SELECT, query',             sub { $async->_query_async('SELECT 1') } ],
      [ 'SELECT, prepare/execute',   sub { $async->_query_async('SELECT ?', [ 1 ]) } ],
      [ 'INSERT, prepare/execute',   sub { $async->_query_async("INSERT INTO `$TABLE` (name) VALUES (?)", [ "f-$name-" . $n++ ]) } ],
      [ 'insert_async',              sub { $async->insert_async($source, { name => "fi-$name-" . $n++ }) } ],
      [ 'CALL 1 result set, query',  sub { $async->_query_async("CALL `$P1`(7)") } ],
      [ 'CALL 1 result set, bind',   sub { $async->_query_async("CALL `$P1`(?)", [ 7 ]) } ],
      [ 'CALL 2 result sets, query', sub { $async->_query_async("CALL `$P2`(7)") } ],
      [ 'CALL 2 result sets, bind',  sub { $async->_query_async("CALL `$P2`(?)", [ 7 ]) } ],
    );
    for my $k (@kinds) {
      my ($label, $first) = @$k;
      reset_counts();
      my $bad = 0;
      for (1 .. 20) {
        my $chain = $first->()->then(sub { $async->_query_async('SELECT CONNECTION_ID()') });
        my ($ok, $row) = settle($chain);
        $bad++ unless $ok && $row->[0] == $tid;
        $tid = $row->[0] if $ok;
      }
      diag "$label: " . counts() . (@PEEK ? ' on the socket: ' . join(' | ', @PEEK) : '');
      # FINDING (measured 2026-10-05, MariaDB 11.8.8, plain TCP; again
      # 2026-10-07, MySQL 8.0.30 and MariaDB 11.8.9): a CALL sent without bind
      # values (EV::MariaDB's `query`) is answered with its first result set
      # while the rest -- the closing OK packet, further result sets -- is
      # still to be read, so a call chained in that callback finds a readable
      # idle socket and the borrow-time check takes a healthy session for
      # gone: one reconnect for a chained call without bind values, in some of
      # the runs (it depends on whether the server's packet arrived: 1 of 20 in
      # a LAN, 11 to 19 of 20 through the cluster's load balancer). Over TLS
      # this was never seen while the transport held the loop for every
      # statement (karr k85: the whole answer was read before query() returned,
      # which is not a property of TLS but of that blocking); with the socket
      # non-blocking (karr k85 work-around) TLS is concurrent like plain TCP,
      # and the claim holds for the other reason. The cause, and what a chained
      # call WITH bind values gets instead, is section g). Since karr k84 a CALL
      # without bind values is prepared and executed, and leaves nothing unread.
      is $C{alive_false} // 0, 0, "$label, 20x chained: a healthy connection was never taken for gone"
        or diag "$label: $bad of 20 chains did not stay on one session";
    }
    end_harness($h);
  };
}

# ====================================================================== g)
# karr k83, k84: the cause behind the findings of e) and f). $PS answers
# with its result set and ends $SLOW seconds later, so the Future of a CALL sent
# without bind values is settled -- and its connection back in the pool -- while
# the rest of the answer is certain not to have arrived. What the pool and a
# caller then see is measured four ways:
#
#   g1) the rest arrives while the loop does not turn: the next borrow finds a
#       readable idle socket and takes the healthy session for gone
#   g2) a statement with bind values right after the CALL: EV::MariaDB is still
#       reading the rest and refuses the prepare
#   g3) ... chained in the CALL's callback: the client library refuses the
#       prepare, the rest of the answer is still due
#   g4) the same chain on a pinned connection, where no borrow-time check comes
#       between the two -- with any procedure, no sleep needed
#
# The diag lines say what was
# measured. The hard ones hold either way: the CALL answers, no call fails for
# good, and the connection is usable once the rest was read. A run that was
sub handle_str {
  my ($pool, $mdb) = @_;
  my $fd = $mdb->socket;
  return "socket=$fd" unless $fd >= 0;
  my $rin = ''; vec($rin, $fd, 1) = 1;
  my $r = select(my $rout = $rin, undef, undef, 0);
  return sprintf 'socket=%s pending_count=%s readable=%s gone=%s', $fd, $mdb->pending_count, $r,
    $pool->_mysql_connection_gone($mdb) ? 1 : 0;
}
sub outcome_str {
  my ($ok, $r) = @_;
  return 'ran' if $ok;
  ($r = $r // 'undef') =~ s/\s+\z//;
  return "failed ($r)";
}

for my $mode (@MODES) {
  my ($name, $dsn_for) = @$mode;
  my $dsn = $dsn_for->();
  my $bound = sub { $_[0]->_query_async('SELECT ? AS v', [ $_[1] ]) };

  subtest "g) k83: a CALL via query() settles before the rest of its answer was read ($name)" => sub {

    subtest 'g1) the rest arrives while the loop does not turn' => sub {
      my $h = new_harness(dsn => $dsn);
      my $async = $h->async;
      my $tid = cid_of($async);
      reset_counts();

      my $t0 = Time::HiRes::time();
      my ($ok, $res) = settle($async->_query_async("CALL `$PS`(7)"));
      my $settled = Time::HiRes::time() - $t0;
      ok $ok, 'the CALL answers' or diag $res;
      is $res->[0], 7, '... with its result set' if $ok;

      my ($mdb) = grep { defined } @{ $h->pool->{_connections} };
      my $at_once = handle_str($h->pool, $mdb);
      block_without_loop($SLOW + 0.6);
      my $later = handle_str($h->pool, $mdb);
      my $gone  = $h->pool->_mysql_connection_gone($mdb) ? 1 : 0;
      my $tid2  = cid_of($async);
      diag sprintf '%s: the CALL settled after %.3f s (the procedure ends after %.1f s); handle then: %s; after %.1f s without a loop turn: %s',
        $name, $settled, $SLOW, $at_once, $SLOW + 0.6, $later;
      diag "$name: the next call ran on " . (($tid2 // 0) == $tid ? 'the same session' : 'a NEW session') . '; ' . counts();

      ok $tid2, 'the next call runs, without an error';
      cmp_ok $C{opened} // 0, '<=', 1, 'at most one connection was opened for it';
      pause(0.3);
      is cid_of($async), $tid2, '... and the call after it stays on that session';
      {
        is $gone, 0, 'a connection with the rest of its answer unread is not taken for gone';
        is $tid2, $tid, 'the next call runs on the same session';
        is $C{alive_false} // 0, 0, 'the borrow-time check never said "gone"';
        is $C{opened} // 0, 0, '0 connections opened';
      }
      end_harness($h);
    };

    subtest 'g2) a statement with bind values right after the CALL' => sub {
      my $h = new_harness(dsn => $dsn);
      my $async = $h->async;
      my ($ok, $res) = settle($async->_query_async("CALL `$PS`(7)"));
      ok $ok, 'the CALL answers' or diag $res;
      my ($ok2, $r2) = settle($bound->($async, 1));
      diag "$name: a statement with bind values right after the CALL " . outcome_str($ok2, $r2) . '; ' . counts();
      {
        ok $ok2, 'a statement with bind values right after the CALL runs';
      }
      pause($SLOW + 0.3);
      my ($ok3, $r3) = settle($bound->($async, 2));
      ok $ok3, 'once the rest was read, a statement with bind values runs' or diag $r3;
      end_harness($h);
    };

    subtest "g3) a statement with bind values chained in the CALL's callback" => sub {
      my $h = new_harness(dsn => $dsn);
      my $async = $h->async;
      my ($ok, $r) = settle($async->_query_async("CALL `$PS`(7)")->then(sub { $bound->($async, 1) }));
      diag "$name: a statement with bind values chained in the CALL's callback " . outcome_str($ok, $r) . '; ' . counts();
      {
        ok $ok, "a statement with bind values chained in the CALL's callback runs";
      }
      pause($SLOW + 0.3);
      my ($ok3, $r3) = settle($bound->($async, 2));
      ok $ok3, 'once the rest was read, a statement with bind values runs' or diag $r3;
      end_harness($h);
    };

    subtest 'g4) the same chain on a pinned connection' => sub {
      my $h = new_harness(dsn => $dsn);
      my $async = $h->async;
      # CALL, then the next statement of the transaction chained off it.
      my $txn = sub {
        my ($call, $bind, $next) = @_;
        return settle($async->txn_do_async(sub {
          my ($ctx) = @_;
          return $ctx->_query_async($call, $bind)->then(sub { $next->($ctx) });
        }));
      };
      my ($ok, $r) = $txn->("CALL `$P1`(7)", [], sub { $bound->($_[0], 1) });
      diag "$name: CALL via query(), then a statement with bind values, in a transaction: " . outcome_str($ok, $r);
      {
        ok $ok, 'a CALL without bind values, then a statement with bind values';
      }
      my ($oks, $rs) = $txn->("CALL `$PS`(7)", [], sub { $bound->($_[0], 1) });
      ok $oks, 'a CALL without bind values that ends late, then a statement with bind values' or diag $rs;
      my ($okq, $rq) = $txn->("CALL `$P1`(7)", [], sub { $_[0]->_query_async('SELECT 3 AS v') });
      ok $okq, 'a CALL without bind values, then a statement without: EV::MariaDB queues it behind the rest' or diag $rq;
      my ($okb, $rb) = $txn->("CALL `$P1`(?)", [ 7 ], sub { $bound->($_[0], 1) });
      ok $okb, 'a CALL with bind values, then a statement with bind values: not affected' or diag $rb;
      end_harness($h);
    };
  };
}

# ====================================================================== h)
# karr k75: the other way to get several result sets out of one query() is a
# multi-statement text. EV::MariaDB connects without CLIENT_MULTI_STATEMENTS,
# so both servers refuse it with a syntax error at the second statement
# (measured 2026-10-22, MySQL 8.0.30 and MariaDB 11.8.9, plain TCP and TLS):
# nothing is left unread, and the session stays where it was. A text that
# begins with CALL does not need this: since karr k84 it is prepared.
for my $mode (@MODES) {
  my ($name, $dsn_for) = @$mode;
  subtest "h) k75: a multi-statement text is refused and leaves the session ($name)" => sub {
    my $h = new_harness(dsn => $dsn_for->());
    my $async = $h->async;
    my $tid = cid_of($async);
    for my $sql ("SELECT 1 AS a; SELECT 2 AS b", "SET \@h75 = 1; CALL `$P1`(7)", "SELECT 1 AS a; CALL `$P2`(7)") {
      reset_counts();
      my ($ok, $err) = settle($async->_query_async($sql)->then(sub { $async->_query_async('SELECT CONNECTION_ID()') }));
      ok !$ok, "refused: $sql";
      like $err, qr/error in your SQL syntax/, '... with the server\'s syntax error';
      my ($ok2, $row) = settle($async->_query_async('SELECT CONNECTION_ID()'));
      is $row->[0], $tid, '... and the next call runs on the same session';
      is $C{alive_false} // 0, 0, '... without the borrow-time check saying "gone"';
      is $C{opened} // 0, 0, '... and without a new connection';
    }
    end_harness($h);
  };
}

$admin->disconnect;
done_testing;
