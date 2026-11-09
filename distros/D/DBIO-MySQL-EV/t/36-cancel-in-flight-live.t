use strict;
use warnings;
use Test::More;
use Time::HiRes ();
use Scalar::Util ();

# LIVE counterpart of t/36-cancel-in-flight-mock.t (karr k73): a statement
# Future cancelled while its statement is in flight -- on the pooled path and
# inside txn_do_async -- against a real server and the real EV::MariaDB.
#
# WHY: the offline file holds its claims against a stand-in for EV::MariaDB,
# and every one of them stands on what that stand-in assumes: that the callback
# of a cancelled statement is still called, that a query is taken while another
# is in flight and answered in order, that a statement with bind values keeps
# the handle busy until its close_stmt. Only the real client and a server can
# say whether that is so. What is at stake is the same: a cancel is a
# client-side act, the statement goes on running on the server, and its
# connection must come back exactly once, after the last answer, with nothing
# in flight -- or the next caller on it fails, reads another statement's rows,
# or runs inside a transaction that was never ended.
#
# The claims are numbered as in the offline file. Held here:
#   1. pooled, a statement with bind values and one without, on a warm and on a
#      cold pool: the cancel releases nothing and sends nothing -- the server
#      goes on running the statement --; the connection comes back once, not
#      before the statement was answered, with nothing in flight; every
#      statement the session prepared was closed; the Future stays cancelled;
#      the next call runs on the same CONNECTION_ID and gets its own rows;
#   2. pooled, pool of one, the next call issued BEFORE the late answer (before
#      or after the cancel): it is not handed to EV::MariaDB while the
#      cancelled statement is in flight, runs after it on the same session and
#      gets its own rows; one release for each call;
#   3. pooled, the late answer is not a result: a server error the session
#      survives (a lock wait timeout) leaves the connection in the pool,
#      released once; a session that is ended (KILL) is not handed out again,
#      and the call waiting for it runs on a newly opened one;
#   4. pooled insert_async, cancelled with its prepare or its execute in
#      flight: the cancel releases nothing; the connection comes back once,
#      after the last answer; the next insert gets the id of its own row.
#      Whether the cancelled insert still wrote its row is NOT claimed (it
#      did, in every run so far); the file notes what it saw. A cancel with
#      LAST_INSERT_ID() in flight cannot be timed against a server and is left
#      to the offline file;
#   5. pinned, a statement of a txn_do_async coderef sent as a plain query (no
#      bind values) and cancelled in flight -- after the coderef returned, or
#      as the loser of a wait_any: the transaction waits for the late answer;
#      ROLLBACK reaches the server and COMMIT never does (the session's own
#      Com_rollback / Com_commit); the transaction fails with core's "cancelled
#      before it was answered" error, or with the error that won the wait_any;
#      the row inserted before is not there; the connection comes back once,
#      nothing in flight, no transaction open, and a write that follows on it
#      is committed on its own;
#   6. pinned, a plain query behind the cancelled one: it gets its own rows;
#   7. pinned, a statement cancelled in the callback that issued it, where
#      EV::MariaDB has only queued it: the transaction rolls back and the
#      connection comes back once. Whether such a statement is still sent is
#      NOT claimed; the file notes what it saw;
#   8. no callback of this transport dies out of EV::MariaDB, and nothing
#      warns.
#
# NOT held here: 9 (the cancelled statement of a transaction has bind values,
# karr k74) is measured in t/37-txn-rollback-refused-live.t; 10 (the coderef
# returned the cancelled Future, core k274) is open and stays with the offline
# file's TODO.
#
# How it looks: a slow statement is SELECT SLEEP(...) carrying a tag in its
# text, found in the server's process list from a second session; an INSERT is
# held by a row lock of a second session. What the pool did is recorded by
# hooks around the real methods: every release (which connection, what
# EV::MariaDB still had pending on it, when), every connection opened, every
# statement handed to EV::MariaDB and how its Future ended. What the server
# saw is read from the session's own status counters (Com_begin, Com_commit,
# Com_rollback, Com_stmt_prepare, Com_stmt_close) and, for an open
# transaction, from @@in_transaction (MariaDB), performance_schema (MySQL)
# and information_schema.INNODB_TRX.
#
# Every wait is bounded and the file has an alarm. The table is unique to this
# run and dropped in END, after the pool's sessions were ended. Passwords
# never appear: the DSN, user and password come from the environment.
#
# Gated like the other live tests: DBIO_TEST_MYSQL_DSN (dbi:mysql: or
# dbi:MariaDB:), _USER, _PASS, plus EV and EV::MariaDB.

use DBIO::MySQL::EV::TestHarness;

DBIO::MySQL::EV::TestHarness->skip_all_unless_live;
DBIO::MySQL::EV::TestHarness->count_session_status;

use DBI;
use DBIO::Util ();
use EV;
use DBIO::MySQL::EV::Pool ();            # loaded before the hooks wrap its methods
use DBIO::MySQL::EV::QueryExecutor ();

# The file's alarm; the harness hands an outer alarm back after each await.
$SIG{ALRM} = sub { BAIL_OUT('t/36-cancel-in-flight-live.t: alarm, a wait did not end') };
alarm 300;

my ($DSN, $USER, $PASS) = map { $ENV{"DBIO_TEST_MYSQL_$_"} } qw( DSN USER PASS );

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

my $EVF       = 'DBIO::MySQL::EV::Future';
my $CANCELLED = qr/cancelled before it was answered/;
my $SLEEP     = 1.5;   # seconds a slow statement runs on the server

# ---------------------------------------------------------------- a Result class
my $TABLE = "dbio_k73_item_$$";
{
  package T36L::Item;
  use base 'DBIO::Core';
  __PACKAGE__->table("dbio_k73_item_$$");
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 50 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(name_uniq => ['name']);

  package T36L::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL', 'MySQL::EV');
  __PACKAGE__->register_class(Item => 'T36L::Item');
}

# ---------------------------------------------------------------- recording hooks
# Wrapped once, for the whole file: what the pool and the executor did.
our (@RELEASED, @HANDED, %C);
{
  no warnings 'redefine';
  my $release = \&DBIO::Storage::PoolBase::release;
  my $new     = \&DBIO::MySQL::EV::Pool::_new_connection;
  my $execute = \&DBIO::MySQL::EV::QueryExecutor::execute;

  # Every release: which handle, on which session, with how much still pending
  # in EV::MariaDB, and when.
  *DBIO::Storage::PoolBase::release = sub {
    my ($pool, $conn) = @_;
    push @RELEASED, {
      conn      => Scalar::Util::refaddr($conn),
      tid       => scalar eval { $conn->thread_id },
      in_flight => scalar eval { $conn->pending_count },
      at        => Time::HiRes::time(),
    };
    goto &$release;
  };
  *DBIO::MySQL::EV::Pool::_new_connection = sub { $C{opened}++; goto &$new };

  # Every statement the transport hands to EV::MariaDB, in order: on which
  # session, whether EV::MariaDB refused it, and how its Future ended.
  *DBIO::MySQL::EV::QueryExecutor::execute = sub {
    my ($self, $mdb, $sql, $bind) = @_;
    my $entry = { tid => scalar eval { $mdb->thread_id }, sql => $sql, end => 'pending' };
    # The session's character set and collation, read after a spawn and set
    # again by every reset (karr k100), are no statement of a case.
    push @HANDED, $entry unless $sql =~ /\A(?:SELECT \@\@character_set_client|SET NAMES )/;
    my ($f, $err);
    {
      local $@;
      eval { $f = $execute->($self, $mdb, $sql, $bind); 1 } or $err = $@;
    }
    if (defined $err) {
      $entry->{end} = "refused: $err";
      die $err;
    }
    $f->on_ready(sub {
      my ($done) = @_;
      $entry->{end} = $done->is_cancelled ? 'cancelled' : $done->is_failed ? 'failed: ' . $done->failure : 'done';
    });
    return $f;
  };
}
my ($H, @ALL_H);
# The reset of a session that was just released (karr k100, core k398) hands
# statements to EV::MariaDB too; it is waited out so that the records start
# with what the case does.
sub reset_records {
  wait_until(sub { !%{ $H->pool->{_resetting} || {} } }, 5) if $H && $H->pool;
  @RELEASED = (); @HANDED = (); %C = (); @warnings = ();
}

# The releases so far, as [ session, pending in EV::MariaDB ] each.
sub releases { [ map { [ $_->{tid}, $_->{in_flight} ] } @RELEASED ] }

# A statement by a short name: BEGIN, COMMIT and ROLLBACK by their verb, the
# slow statement as SLEEP, LAST_INSERT_ID() as LII, anything else by its verb.
sub short {
  my ($sql) = @_;
  return 'LII'   if $sql =~ /LAST_INSERT_ID/;
  return 'SLEEP' if $sql =~ /SLEEP\(/;
  return $sql =~ /^\s*(\w+)/ ? uc $1 : $sql;
}
sub handed { [ map { short($_->{sql}) } @HANDED ] }

# ---------------------------------------------------------------- helpers
sub now { Time::HiRes::time() }

sub wait_until {
  my ($cond, $timeout) = @_;
  my $deadline = now() + ($timeout // 15);
  until ($cond->()) {
    return 0 if now() > $deadline;
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

# A second session: plain DBI, with every lock wait bounded.
sub raw {
  # DBI dies quoting the DSN: named without a password it may carry (karr k76).
  my $dbh = eval {
    DBI->connect($DSN, $USER, $PASS, {
      AutoCommit => 1, RaiseError => 1, PrintError => 0, AutoInactiveDestroy => 1,
    });
  } or die DBIO::Util::mask_connect_secrets("$@", [ $DSN, $USER, $PASS ]);
  $dbh->do('SET SESSION lock_wait_timeout = 20');
  $dbh->do('SET SESSION innodb_lock_wait_timeout = 20');
  return $dbh;
}

my $admin = raw();
my $VERSION_STRING = $admin->selectrow_array('SELECT VERSION()');
my $IS_MARIADB     = $VERSION_STRING =~ /MariaDB/i ? 1 : 0;

# Wait for $f: (1, $first_value) once it is done, (0, $error) once it failed,
# (undef, $why) when it was cancelled or is still pending after $t seconds. A
# rows result is its first row.
sub outcome {
  my ($f, $t) = @_;
  wait_until(sub { $f->is_ready }, $t // 20) or return (undef, 'still pending');
  return (undef, 'cancelled') if $f->is_cancelled;
  return $f->is_failed ? (0, scalar $f->failure) : (1, ($f->get)[0]);
}

sub state_of {
  my ($f) = @_;
  return !$f->is_ready ? 'pending' : $f->is_cancelled ? 'cancelled' : $f->is_failed ? 'failed' : 'done';
}

# The moment $f settles, whichever way.
sub stamp {
  my ($f) = @_;
  my $at;
  $f->on_ready(sub { $at = now() });
  return \$at;
}

sub new_harness {
  my (%o) = @_;
  my $h = DBIO::MySQL::EV::TestHarness->new(
    schema_class  => 'T36L::Schema',
    connect_attrs => { pool_size => 1, ($o{on_connect_do} ? (on_connect_do => $o{on_connect_do}) : ()) },
  );
  push @ALL_H, $h;
  $h->warm_pool unless $o{cold};
  $H = $h;
  reset_records();
  return $h;
}
sub end_harness { my ($h) = @_; eval { $h->disconnect }; $H = undef }

# The pool's one connection, and the session it is.
sub the_conn { (grep { defined } @{ $_[0]->pool->{_connections} })[0] }

sub cid_of {
  my ($async) = @_;
  my ($ok, $row) = outcome($async->_query_async('SELECT CONNECTION_ID()'));
  return $ok ? $row->[0] : undef;
}

my $SERIAL = 0;
sub tag { 'k73-' . $$ . '-' . ++$SERIAL }

# A slow statement, with a bind value (prepare, execute, close_stmt) or
# without (a plain query). $on is the storage or a transaction context. Its row
# is [ 0, $tag ].
my %SLOW = (
  bound => sub { my ($on, $tag, $s) = @_; $on->_query_async("SELECT SLEEP(?), '$tag'", [ $s ]) },
  plain => sub { my ($on, $tag, $s) = @_; $on->_query_async("SELECT SLEEP($s), '$tag'") },
);

# The session that runs a statement whose text carries $tag, seen from the
# second session; nothing when no session does.
sub running_on {
  my ($tag) = @_;
  return scalar $admin->selectrow_array(
    'SELECT ID FROM information_schema.PROCESSLIST WHERE ID <> CONNECTION_ID() AND INFO LIKE ? LIMIT 1',
    undef, "%$tag%");
}
sub server_has {
  my ($tid) = @_;
  return scalar $admin->selectrow_array('SELECT COUNT(*) FROM information_schema.PROCESSLIST WHERE ID = ?', undef, $tid);
}
sub command_of {
  my ($tid) = @_;
  return join ' / ', map { $_ // 'NULL' } $admin->selectrow_array(
    'SELECT COMMAND, STATE FROM information_schema.PROCESSLIST WHERE ID = ?', undef, $tid);
}
sub rows_named {
  my ($name) = @_;
  return scalar $admin->selectrow_array("SELECT COUNT(*) FROM `$TABLE` WHERE name = ?", undef, $name);
}

# Ask the session of a pooled handle something, on the handle itself and past
# the pool, once EV::MariaDB has nothing pending on it: a measurement must not
# show up as a borrow and a release of its own.
sub ask {
  my ($conn, $sql) = @_;
  wait_until(sub { $conn->pending_count == 0 }, 10) or return;
  my ($rows, $err, $done);
  $conn->query($sql, sub { ($rows, $err) = @_; $done = 1 });
  wait_until(sub { $done }, 10) or return;
  diag "asking the session failed: $err" if $err;
  return $rows;
}

# The session's own statement counters from its spawn on: the reset that ends
# a borrow (karr k100, core k398) zeroes them, the harness adds the readings
# taken ahead of each reset to the current one. Other clients of the server do
# not show up in them.
sub session_status {
  my ($conn) = @_;
  return $H->session_status($conn) || {};
}
sub delta {
  my ($before, $after, @names) = @_;
  return { map { ($_ => ($after->{"Com_$_"} // 0) - ($before->{"Com_$_"} // 0)) } @names };
}

# Is a transaction open on the session of $conn? 1 or 0; undef when the server
# gave no answer. MariaDB says so itself; MySQL has no @@in_transaction, there
# performance_schema is asked from the second session.
sub txn_open {
  my ($conn, $tid) = @_;
  if ($IS_MARIADB) {
    my $rows = ask($conn, 'SELECT @@in_transaction') or return;
    return $rows->[0][0];
  }
  my ($state) = $admin->selectrow_array(
    'SELECT t.STATE FROM performance_schema.events_transactions_current t '
    . 'JOIN performance_schema.threads th ON th.THREAD_ID = t.THREAD_ID WHERE th.PROCESSLIST_ID = ?', undef, $tid);
  return unless defined $state;
  return $state eq 'ACTIVE' ? 1 : 0;
}

# InnoDB transactions of a session, from the second session. The table is a
# snapshot the server refreshes every 0.1 s at most, hence the pause.
sub innodb_trx {
  my ($tid) = @_;
  pause(0.25);
  return scalar $admin->selectrow_array(
    'SELECT COUNT(*) FROM information_schema.INNODB_TRX WHERE trx_mysql_thread_id = ?', undef, $tid);
}

sub nothing_warned {
  my ($label) = @_;
  is_deeply \@warnings, [], "$label: no callback died out of EV::MariaDB, nothing warned";
  @warnings = ();
}

# Everything the session prepared it also closed, and it prepared something
# when a statement with bind values ran.
sub statements_closed {
  my ($label, $conn, $at_least) = @_;
  my $st = session_status($conn);
  cmp_ok $st->{Com_stmt_prepare} // -1, q{>=}, $at_least, "$label: premise: the session prepared a statement"
    if $at_least;
  is $st->{Com_stmt_close}, $st->{Com_stmt_prepare},
    "$label: every statement the session prepared was closed (Com_stmt_close = Com_stmt_prepare = "
    . ($st->{Com_stmt_prepare} // 'undef') . ')';
}

# The pool has its one connection, idle, with nothing pending on it -- and the
# next call, a statement with a bind value, runs on that session and gets its
# own rows.
sub next_call_is_its_own {
  my ($label, $h, $tid) = @_;
  my $pool = $h->pool;
  pause(0.2);   # a release that came late has come by now
  is $pool->size, 1, "$label: the pool still has its one connection";
  is $pool->available, 1, "$label: idle";
  is the_conn($h)->pending_count, 0, "$label: nothing pending on it";

  my $before = @RELEASED;
  my $opened = $C{opened} // 0;
  my ($ok, $row) = outcome($h->async->_query_async(q{SELECT CONNECTION_ID(), ?, 'next'}, [ 'mine' ]));
  ok $ok, "$label: the next call completes" or diag 'it ' . (defined $ok ? 'failed' : 'did not settle') . ": $row";
  is_deeply $ok ? $row : undef, [ $tid, 'mine', 'next' ],
    "$label: on the same session, with its own rows -- not the late answer";
  pause(0.2);
  is @RELEASED - $before, 1, "$label: and releases the connection once";
  is $pool->available, 1, "$label: idle again";
  is +($C{opened} // 0) - $opened, 0, "$label: no connection was opened for it";
  nothing_warned($label);
}

# ---------------------------------------------------------------- server objects
$admin->do("DROP TABLE IF EXISTS `$TABLE`");
$admin->do("CREATE TABLE `$TABLE` (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(50) NOT NULL, "
  . 'UNIQUE KEY name_uniq (name)) ENGINE=InnoDB');

my $OPENER = $$;
END {
  if (defined $OPENER && $$ == $OPENER) {
    local ($@, $?);
    # The pool's sessions first: one that sits in a transaction or holds a lock
    # would make the DROP wait for a metadata lock.
    eval { $_->disconnect } for @ALL_H;
    eval {
      my $dbh = DBI->connect($DSN, $USER, $PASS, { RaiseError => 1, PrintError => 0 });
      $dbh->do('SET SESSION lock_wait_timeout = 10');
      $dbh->do("DROP TABLE IF EXISTS `$TABLE`");
      $dbh->disconnect;
    };
  }
}

diag "server: $VERSION_STRING, EV::MariaDB " . EV::MariaDB->VERSION;

# ====================================================================== 1)
for my $kind (qw( bound plain )) {
  for my $temp (qw( warm cold )) {
    my $label = "pooled, $kind, $temp pool";
    subtest "1) $label: cancelled in flight, then its answer arrives" => sub {
      my $h     = new_harness(cold => $temp eq 'cold');
      my $async = $h->async;
      my $tag   = tag();

      my $issued = now();
      my $q1 = $SLOW{$kind}->($async, $tag, $SLEEP);
      my $tid;
      ok wait_until(sub { $tid = running_on($tag) }, 10), "$label: the statement runs on the server"
        or return end_harness($h);
      my $conn = the_conn($h);
      is $conn->thread_id, $tid, "$label: premise: on the pool's one connection";

      $q1->cancel;
      is state_of($q1), 'cancelled', "$label: the caller's Future is cancelled";
      is_deeply releases(), [],
        "$label: the cancel releases nothing -- EV::MariaDB is still busy with the statement";
      is $h->pool->available, 0, "$label: the connection is not idle while an answer is due";
      is $conn->pending_count, 1, "$label: EV::MariaDB still holds the statement's callback";

      pause(0.2);
      is running_on($tag), $tid, "$label: the server goes on running the statement: the cancel sent nothing";
      is_deeply releases(), [], "$label: and the connection stays checked out meanwhile";

      ok wait_until(sub { scalar @RELEASED }, 10), "$label: the connection is released"
        or return end_harness($h);
      pause(0.3);   # a second release would have come by now
      is_deeply releases(), [ [ $tid, 0 ] ], "$label: once, with nothing in flight";
      cmp_ok $RELEASED[0]{at} - $issued, '>=', $SLEEP - 0.05,
        "$label: and not before the statement was answered";
      ok !running_on($tag), "$label: the server is done with the statement";
      is state_of($q1), 'cancelled', "$label: the Future stays cancelled";
      is_deeply [ map { $_->{end} } @HANDED ], [ 'done' ],
        "$label: the statement was answered with a result all the same";

      statements_closed($label, $conn, $kind eq 'bound' ? 1 : 0);
      next_call_is_its_own($label, $h, $tid);
      is_deeply handed(), [qw( SLEEP SELECT )], "$label: nothing else was handed to EV::MariaDB";
      end_harness($h);
    };
  }
}

# ====================================================================== 2)
for my $kind (qw( bound plain )) {
  for my $order ('cancel, then the next call', 'the next call, then cancel') {
    my $label = "pool of one, $kind, $order";
    subtest "2) $label, issued before the late answer" => sub {
      my $h     = new_harness();
      my $async = $h->async;
      my $tid   = cid_of($async);
      my $conn  = the_conn($h);
      my $tag   = tag();
      my $mine  = tag();
      reset_records();

      my $issued = now();
      my $q1 = $SLOW{$kind}->($async, $tag, $SLEEP);
      ok wait_until(sub { running_on($tag) }, 10), "$label: the first statement runs on the server"
        or return end_harness($h);

      my $q2;
      my $next = sub { $async->_query_async(q{SELECT CONNECTION_ID(), ?}, [ $mine ]) };
      if ($order =~ /^cancel/) { $q1->cancel; $q2 = $next->() }
      else                     { $q2 = $next->(); $q1->cancel }
      my $q2_at = stamp($q2);

      is state_of($q1), 'cancelled', "$label: the first call is cancelled";
      is state_of($q2), 'pending', "$label: the next call waits"
        or diag $q2->is_failed ? 'it failed: ' . $q2->failure : 'it is ' . state_of($q2);
      is_deeply handed(), [ 'SLEEP' ],
        "$label: it is not handed to EV::MariaDB -- the connection is not given out before the late answer";
      is_deeply releases(), [], "$label: nothing is released yet";

      pause(0.2);
      is running_on($tag), $tid, "$label: the server goes on running the cancelled statement";
      is state_of($q2), 'pending', "$label: and the next call still waits";

      my ($ok, $row) = outcome($q2);
      ok $ok, "$label: the next call completes" or diag 'it ' . (defined $ok ? 'failed' : 'did not settle') . ": $row";
      is_deeply $ok ? $row : undef, [ $tid, $mine ], "$label: on that session, with its own rows";
      cmp_ok +($$q2_at // 0) - $issued, '>=', $SLEEP - 0.05, "$label: after the late answer, not before";
      is_deeply handed(), [qw( SLEEP SELECT )], "$label: it was handed to EV::MariaDB behind the cancelled statement";
      is state_of($q1), 'cancelled', "$label: the first call stays cancelled";
      pause(0.3);
      is_deeply releases(), [ [ $tid, 0 ], [ $tid, 0 ] ],
        "$label: one release for each call, each with nothing in flight";
      is $C{opened} // 0, 0, "$label: no connection was opened meanwhile";

      statements_closed($label, $conn, 1);
      next_call_is_its_own($label, $h, $tid);
      end_harness($h);
    };
  }
}

# ====================================================================== 3)
# The late answer is a server error the session survives: a lock wait timeout.
for my $kind (qw( bound plain )) {
  my $label = "late server error, $kind";
  subtest "3) $label" => sub {
    # A setting made inside a borrow is gone when it ends (karr k100, core k398):
    # the one-second lock wait is a connect action, which the reset puts back.
    my $h     = new_harness(on_connect_do => [ q{SET SESSION innodb_lock_wait_timeout = 1} ]);
    my $async = $h->async;
    my $tid   = cid_of($async);
    my $conn  = the_conn($h);
    my $tag   = tag();
    my $row   = tag();

    $admin->do("INSERT INTO `$TABLE` (name) VALUES (?)", undef, $row);
    my ($set, $lw) = outcome($async->_query_async(q{SELECT @@session.innodb_lock_wait_timeout}));
    ok $set && $lw->[0] == 1, "$label: premise: the pool's session waits one second for a row lock";
    my $locker = raw();
    $locker->do('BEGIN');
    $locker->do("UPDATE `$TABLE` SET name = CONCAT(name, '-held') WHERE name = ?", undef, $row);
    reset_records();

    my $q1 = $kind eq 'bound'
      ? $async->_query_async("UPDATE `$TABLE` SET name = 'late' WHERE name LIKE ? AND '$tag' <> ''", [ "$row%" ])
      : $async->_query_async("UPDATE `$TABLE` SET name = 'late' WHERE name LIKE '$row%' AND '$tag' <> ''");
    ok wait_until(sub { running_on($tag) }, 10), "$label: the statement waits for the lock on the server";
    $q1->cancel;
    is_deeply releases(), [], "$label: the cancel releases nothing";

    ok wait_until(sub { scalar @RELEASED }, 10), "$label: the statement is answered and the connection released";
    pause(0.3);
    like $HANDED[0]{end}, qr/^failed: .*Lock wait timeout/i, "$label: premise: the late answer was a server error"
      or diag "it ended: $HANDED[0]{end}";
    is state_of($q1), 'cancelled', "$label: the Future stays cancelled, it does not fail";
    is_deeply releases(), [ [ $tid, 0 ] ], "$label: the connection is released once, with nothing in flight";
    ok server_has($tid), "$label: the session survived";
    $locker->do('ROLLBACK');
    $locker->disconnect;

    statements_closed($label, $conn, $kind eq 'bound' ? 1 : 0);
    next_call_is_its_own($label, $h, $tid);
    end_harness($h);
  };
}

# The late answer never comes: the session is ended while the cancelled
# statement runs, with the next call waiting for the connection.
for my $kind (qw( bound plain )) {
  my $label = "connection lost, $kind";
  subtest "3) $label" => sub {
    my $h     = new_harness();
    my $async = $h->async;
    my $tid   = cid_of($async);
    my $conn  = the_conn($h);
    my $tag   = tag();
    my $mine  = tag();
    reset_records();

    my $q1 = $SLOW{$kind}->($async, $tag, 30);
    ok wait_until(sub { running_on($tag) }, 10), "$label: the statement runs on the server"
      or return end_harness($h);
    $q1->cancel;
    my $q2 = $async->_query_async(q{SELECT CONNECTION_ID(), ?}, [ $mine ]);
    is state_of($q2), 'pending', "$label: the next call waits for the connection"
      or diag $q2->is_failed ? 'it failed: ' . $q2->failure : 'it is ' . state_of($q2);

    eval { $admin->do("KILL $tid") };
    ok wait_until(sub { !server_has($tid) }, 10), "$label: the session is ended by a second session";

    my ($ok, $row) = outcome($q2);
    ok $ok, "$label: the waiting call completes" or diag 'it ' . (defined $ok ? 'failed' : 'did not settle') . ": $row";
    my $tid2 = $ok ? $row->[0] : undef;
    isnt $tid2, $tid, "$label: on a newly opened session";
    is_deeply $ok ? $row : undef, [ $tid2, $mine ], "$label: with its own rows";
    is state_of($q1), 'cancelled', "$label: the first call stays cancelled";
    pause(0.3);
    is scalar(grep { $_->{conn} == Scalar::Util::refaddr($conn) } @RELEASED), 1,
      "$label: the lost connection was handed back once";
    is scalar(@RELEASED), 2, "$label: one release for each call";
    is $C{opened} // 0, 1, "$label: one connection was opened in its place";
    is $h->pool->size, 1, "$label: the pool holds one connection";
    isnt Scalar::Util::refaddr(the_conn($h)), Scalar::Util::refaddr($conn), "$label: not the lost one";

    next_call_is_its_own($label, $h, $tid2);
    end_harness($h);
  };
}

# ====================================================================== 4)
# insert_async is INSERT and SELECT LAST_INSERT_ID() on one pooled connection.
# The INSERT is held on the server by a second session's uncommitted row of the
# same unique name.
for my $stage ('prepare', 'execute') {
  my $label = "pooled insert, cancelled with its $stage in flight";
  subtest "4) $label" => sub {
    my $h      = new_harness();
    my $async  = $h->async;
    my $source = $h->schema->source('Item');
    my $tid    = cid_of($async);
    my $conn   = the_conn($h);
    my $doomed = 'doomed-' . tag();
    my $mine   = 'mine-' . tag();

    my $locker = raw();
    $locker->do('BEGIN');
    $locker->do("INSERT INTO `$TABLE` (name) VALUES (?)", undef, $doomed);
    reset_records();

    my $insert = $async->insert_async($source, { name => $doomed });
    if ($stage eq 'execute') {
      ok wait_until(sub { command_of($tid) =~ /^Execute/ }, 10),
        "$label: premise: the INSERT waits for the row lock on the server (" . command_of($tid) . ')';
    }
    else {
      # Nothing has run the loop since the call: EV::MariaDB has started the
      # prepare and cannot have read its answer.
      is_deeply handed(), [ 'INSERT' ], "$label: premise: the INSERT was handed to EV::MariaDB this moment";
      is $conn->pending_count, 1, "$label: premise: and its prepare is in flight";
    }

    $insert->cancel;
    is state_of($insert), 'cancelled', "$label: the caller's Future is cancelled";
    is_deeply releases(), [], "$label: the cancel releases nothing";
    is $h->pool->available, 0, "$label: the connection is not idle while an answer is due";
    pause(0.3);
    is_deeply releases(), [], "$label: and stays checked out while the INSERT waits on the server";

    $locker->do('ROLLBACK');
    $locker->disconnect;
    ok wait_until(sub { scalar @RELEASED }, 10), "$label: the connection is released once the INSERT can run";
    pause(0.3);
    is_deeply releases(), [ [ $tid, 0 ] ], "$label: once, after the last answer, with nothing in flight";
    is state_of($insert), 'cancelled', "$label: the Future stays cancelled";
    note "$label: the cancelled insert handed EV::MariaDB @{[ join ', ', @{ handed() } ]} and left "
      . rows_named($doomed) . ' row(s) -- what a cancelled insert still does is not claimed here';

    my ($ok, $got) = outcome($async->insert_async($source, { name => $mine }));
    ok $ok, "$label: the next insert completes" or diag 'it ' . (defined $ok ? 'failed' : 'did not settle') . ": $got";
    my $id = $admin->selectrow_array("SELECT id FROM `$TABLE` WHERE name = ?", undef, $mine);
    ok $id, "$label: its row is there";
    is_deeply $ok ? $got : undef, { name => $mine, id => $id }, "$label: and it got the id of its own row";

    statements_closed($label, $conn, 2);
    next_call_is_its_own($label, $h, $tid);
    end_harness($h);
  };
}

# ====================================================================== 5) 6) 7)
# A transaction that inserted row $x and whose plain-query statement was
# cancelled has failed: ROLLBACK reached the server and COMMIT did not, the row
# is not there, and the connection is back once, with no transaction open.
sub rolled_back {
  my ($label, $h, $tid, $conn, $before, $x, @handed) = @_;

  pause(0.3);   # a second release would have come by now
  is_deeply releases(), [ [ $tid, 0 ] ],
    "$label: the connection comes back once, with nothing in flight";
  is_deeply handed(), [ 'BEGIN', 'INSERT', @handed, 'ROLLBACK' ],
    "$label: ROLLBACK was handed to EV::MariaDB behind the cancelled statement, and never COMMIT";
  is_deeply [ grep { /^refused/ } map { $_->{end} } @HANDED ], [], "$label: EV::MariaDB refused none of them";

  my $after = session_status($conn);
  is_deeply delta($before, $after, qw( begin rollback commit )), { begin => 1, rollback => 1, commit => 0 },
    "$label: the server saw one BEGIN, one ROLLBACK and no COMMIT on the session";
  is rows_named($x), 0, "$label: the row the transaction inserted is not there";
  is txn_open($conn, $tid), 0, "$label: no transaction is open on the connection";
  is innodb_trx($tid), 0, "$label: and InnoDB has none for the session";

  # A write that follows on the connection is committed on its own: a second
  # session sees it at once. Inside a transaction left open it would not.
  my $follow = 'after-' . tag();
  my ($ok, $err) = outcome($h->async->_query_async("INSERT INTO `$TABLE` (name) VALUES (?)", [ $follow ]));
  ok $ok, "$label: a write that follows on the connection runs" or diag $err;
  is rows_named($follow), 1, "$label: and is committed on its own -- a second session sees it at once";
  is rows_named($x), 0, "$label: the transaction's row is still not there";

  next_call_is_its_own($label, $h, $tid);
}

for my $when ('after the coderef returned', 'as the loser of a wait_any') {
  my $label = "txn, a plain query cancelled $when";
  subtest "5) $label" => sub {
    my $h      = new_harness();
    my $async  = $h->async;
    my $tid    = cid_of($async);
    my $conn   = the_conn($h);
    my $tag    = tag();
    my $x      = 'x-' . tag();
    my $before = session_status($conn);
    reset_records();

    my ($stmt, $timeout, $issued);
    my $txn = $async->txn_do_async(sub {
      my ($ctx) = @_;
      return $ctx->_query_async("INSERT INTO `$TABLE` (name) VALUES ('$x')")->then(sub {
        $issued = now();
        $stmt   = $SLOW{plain}->($ctx, $tag, $SLEEP);
        return 'gave up' unless $when =~ /wait_any/;
        $timeout = $EVF->new;
        return $EVF->wait_any($stmt, $timeout);
      });
    });
    my $txn_at = stamp($txn);
    ok wait_until(sub { running_on($tag) }, 10), "$label: the statement runs on the server, inside the transaction"
      or return end_harness($h);

    if ($when =~ /wait_any/) { $timeout->fail("timed out\n") }
    else                     { $stmt->cancel }
    is state_of($stmt), 'cancelled', "$label: the statement's Future is cancelled";
    is state_of($txn), 'pending', "$label: the transaction waits";
    is_deeply releases(), [], "$label: the connection stays pinned";
    pause(0.2);
    is running_on($tag), $tid, "$label: the server goes on running the cancelled statement";
    is state_of($txn), 'pending', "$label: and the transaction still waits";

    my ($ok, $err) = outcome($txn);
    is $ok, 0, "$label: the transaction fails" or diag defined $ok ? 'it completed' : "it did not settle: $err";
    if ($when =~ /wait_any/) { is   $ok ? '' : "$err", "timed out\n", "$label: with the error that cancelled it" }
    else                     { like $ok ? '' : "$err", $CANCELLED,    "$label: saying a statement was cancelled" }
    cmp_ok +($$txn_at // 0) - $issued, '>=', $SLEEP - 0.05,
      "$label: not before the cancelled statement was answered -- the late answer did not end it, ROLLBACK did";
    is state_of($stmt), 'cancelled', "$label: the statement stays cancelled";

    rolled_back($label, $h, $tid, $conn, $before, $x, 'SLEEP');
    end_harness($h);
  };
}

{
  my $label = 'txn, a query behind the cancelled one';
  subtest "6) $label" => sub {
    my $h      = new_harness();
    my $async  = $h->async;
    my $tid    = cid_of($async);
    my $conn   = the_conn($h);
    my $tag    = tag();
    my $mine   = tag();
    my $x      = 'x-' . tag();
    my $before = session_status($conn);
    reset_records();

    my ($doomed, $behind);
    my $txn = $async->txn_do_async(sub {
      my ($ctx) = @_;
      return $ctx->_query_async("INSERT INTO `$TABLE` (name) VALUES ('$x')")->then(sub {
        $doomed = $SLOW{plain}->($ctx, $tag, $SLEEP);
        $behind = $ctx->_query_async("SELECT CONNECTION_ID(), '$mine'");
        return $behind;
      });
    });
    ok wait_until(sub { running_on($tag) }, 10), "$label: the first statement runs on the server"
      or return end_harness($h);
    is $conn->pending_count, 2, "$label: premise: EV::MariaDB took both, one behind the other";

    $doomed->cancel;
    is state_of($behind), 'pending', "$label: the cancel does not settle the query behind it";

    my ($ok, $row) = outcome($behind);
    ok $ok, "$label: the query behind completes" or diag 'it ' . (defined $ok ? 'failed' : 'did not settle') . ": $row";
    is_deeply $ok ? $row : undef, [ $tid, $mine ], "$label: with its own rows, not the late answer";

    my ($tok, $err) = outcome($txn);
    is $tok, 0, "$label: the transaction fails -- one of its statements was cancelled";
    like $tok ? '' : "$err", $CANCELLED, "$label: saying so";

    rolled_back($label, $h, $tid, $conn, $before, $x, 'SLEEP', 'SELECT');
    end_harness($h);
  };
}

{
  my $label = 'txn, cancelled while queued';
  subtest "7) $label: behind a statement in flight" => sub {
    my $h      = new_harness();
    my $async  = $h->async;
    my $tid    = cid_of($async);
    my $conn   = the_conn($h);
    my $tag    = tag();
    my $first  = tag();
    my $x      = 'x-' . tag();
    my $before = session_status($conn);
    reset_records();

    my ($stmt, $unseen);
    my $txn = $async->txn_do_async(sub {
      my ($ctx) = @_;
      return $ctx->_query_async("INSERT INTO `$TABLE` (name) VALUES ('$x')")->then(sub {
        # Since karr k51 the coderef runs outside the INSERT's callback, so
        # EV::MariaDB sends a statement at once. One taken while another plain
        # query is in flight only waits in its queue.
        $SLOW{plain}->($ctx, $first, $SLEEP);
        $stmt   = $SLOW{plain}->($ctx, $tag, $SLEEP);
        $unseen = !running_on($tag);
        $stmt->cancel;
        return 'gave up';
      });
    });
    my $sent = wait_until(sub { $unseen && running_on($tag) }, 0.6);
    ok $unseen, "$label: premise: the server had not seen the statement when it was cancelled";
    note "$label: a statement cancelled in EV::MariaDB's queue was " . ($sent ? 'still sent' : 'not seen on the server')
      . ' -- whether it is sent is not claimed here';

    my ($ok, $err) = outcome($txn);
    is $ok, 0, "$label: the transaction fails" or diag defined $ok ? 'it completed' : "it did not settle: $err";
    like $ok ? '' : "$err", $CANCELLED, "$label: saying a statement was cancelled";
    is state_of($stmt), 'cancelled', "$label: the statement stays cancelled";

    rolled_back($label, $h, $tid, $conn, $before, $x, 'SLEEP', 'SLEEP');
    end_harness($h);
  };
}

$admin->disconnect;
done_testing;
