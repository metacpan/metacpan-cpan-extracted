use strict;
use warnings;
use Test::More;
use Time::HiRes ();
use Scalar::Util ();

# LIVE measurement for karr k74: a transaction of txn_do_async ends -- its
# coderef died, its Future failed, or one of its statements was cancelled --
# while a statement WITH BIND VALUES is in flight on its connection.
#
# WHY: a statement with bind values is prepare, execute and close_stmt, and
# EV::MariaDB takes no query while one of those is in flight. ROLLBACK is a
# query. Core sends it the moment it knows the transaction has failed, and the
# transport hands it to EV::MariaDB at once. If EV::MariaDB refuses it, no
# ROLLBACK reaches the server, and the connection goes back to the pool with a
# statement in flight and the transaction OPEN: whatever the pool runs on it
# next runs inside that transaction, and the next BEGIN there commits it. A
# caller that was told its transaction failed has its rows committed by a
# stranger. t/36-cancel-in-flight-mock.t holds that as TODO in its section 9,
# on a stand-in whose refusal was only READ from MariaDB.xs. This file is the
# measurement, against a server and the real EV::MariaDB.
#
# Two parts.
#
# R) EV::MariaDB itself, on a handle of its own: is a query refused while a
#    prepare, an execute or a close_stmt is in flight, and with which words?
#    HARD assertions on what the library does -- they document its behaviour
#    and turn red when a release of EV::MariaDB changes it. Measured 2026-10-05
#    with EV::MariaDB 0.08 against MySQL 8.0.30 and MariaDB 11.8.8, the same on
#    both:
#      - prepare in flight: query croaks "cannot queue query: exclusive
#        operation in progress", at top level and inside a callback of the
#        handle; the refused query is not queued;
#      - execute in flight, just issued and while the statement runs on the
#        server: the same croak;
#      - close_stmt is never in flight: its callback has run by the time
#        close_stmt returns (the client library sends COM_STMT_CLOSE and waits
#        for nothing), and a query right behind it is taken and answered;
#      - inside the callback of an execute the handle is idle again: a query
#        issued there is taken, and answered after a close_stmt issued behind
#        it.
#    So the refusal is real, for two of the three operations, and it ends with
#    the statement: a ROLLBACK issued once the statement's close_stmt has
#    called back is taken.
#
# T) Through the transport: txn_do_async, a row X inserted by the coderef, and
#    the transaction made to fail with a statement with bind values in flight,
#    its prepare or its execute, with and without a cancel:
#      T1 the statement is cancelled while it runs on the server (execute);
#      T2 the statement is cancelled in the callback that issued it (prepare);
#      T3 the coderef dies with its INSERT of row X just issued (prepare);
#      T4 the coderef's Future fails while a statement runs on the server
#         (execute).
#    What holds whichever way k74 is solved is a HARD assertion: the
#    transaction fails, with the error of what made it fail; it sends no
#    COMMIT; its connection is not handed back twice; the statement in flight
#    is answered in the end; a second session does not see row X before
#    another transaction runs; no callback dies out of EV::MariaDB.
#    What k74 broke was held as TODO until it was solved (transport: the
#    ROLLBACK waits behind the statements in flight, QueryExecutor
#    execute_when_idle, and a ROLLBACK that fails retires the connection). Each
#    was seen red without the fix (2026-10-05, both servers, all four cases),
#    and is a plain assertion now:
#      - ROLLBACK reaches the server (the session's Com_rollback);
#      - the pool is not left holding the connection with a statement of the
#        failed transaction in flight, nor with the transaction open;
#      - a call issued the moment the transaction failed runs;
#      - after the next transaction on the pool -- one that is rolled back
#        itself -- row X is NOT there.
#    What was measured instead, BEFORE the fix, is printed per case (the same
#    diag lines still print what happens now): the error the transaction
#    failed with, what the transport handed to EV::MariaDB and how each ended,
#    the state the connection went back in, and whether row X got committed.
#    It was the same in all four cases on both servers: EV::MariaDB refuses
#    ROLLBACK with the words of part R; the transaction fails with core's
#    "Transaction aborted: <cause>. Rollback failed: cannot queue query:
#    exclusive operation in progress"; the session's Com_rollback stays where
#    it was; the connection is back in the pool, idle, with one operation
#    pending on it and the transaction open; a call issued that moment fails
#    with EV::MariaDB's "another operation is in progress"; and the BEGIN of
#    the next transaction commits row X, although that transaction is rolled
#    back. In T3 the insert's LAST_INSERT_ID() is still sent as well, on a
#    connection the pool has back by then.
#
# What the pool did is recorded by hooks around the real methods (every
# release, every statement handed to EV::MariaDB); what the server saw is read
# from the session's own status counters and, for an open transaction, from
# @@in_transaction (MariaDB), performance_schema (MySQL) and
# information_schema.INNODB_TRX. A statement that runs on the server is
# SELECT SLEEP(?) with a tag in its text, found in the process list from a
# second session.
#
# Every wait is bounded and the file has an alarm. The table is unique to this
# run and dropped in END, after the pool's sessions and the handle of part R
# were ended. Passwords never appear: the DSN, user and password come from the
# environment.
#
# Gated like the other live tests: DBIO_TEST_MYSQL_DSN (dbi:mysql: or
# dbi:MariaDB:), _USER, _PASS, plus EV and EV::MariaDB.

use DBIO::MySQL::EV::TestHarness;

DBIO::MySQL::EV::TestHarness->skip_all_unless_live;
DBIO::MySQL::EV::TestHarness->count_session_status;

use DBI;
use DBIO::Util ();
use EV;
use EV::MariaDB;
use DBIO::MySQL::EV::ConnectInfo ();
use DBIO::MySQL::EV::Pool ();            # loaded before the hooks wrap its methods
use DBIO::MySQL::EV::QueryExecutor ();

# The file's alarm; the harness hands an outer alarm back after each await.
$SIG{ALRM} = sub { BAIL_OUT('t/37-txn-rollback-refused-live.t: alarm, a wait did not end') };
alarm 240;

my ($DSN, $USER, $PASS) = map { $ENV{"DBIO_TEST_MYSQL_$_"} } qw( DSN USER PASS );

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

my $EVF       = 'DBIO::MySQL::EV::Future';
my $CANCELLED = qr/cancelled before it was answered/;
my $REFUSAL   = 'cannot queue query: exclusive operation in progress';
my $SLEEP     = 1.5;   # seconds a slow statement runs on the server

# ---------------------------------------------------------------- a Result class
my $TABLE = "dbio_k74_item_$$";
{
  package T37L::Item;
  use base 'DBIO::Core';
  __PACKAGE__->table("dbio_k74_item_$$");
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 50 },
  );
  __PACKAGE__->set_primary_key('id');

  package T37L::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL', 'MySQL::EV');
  __PACKAGE__->register_class(Item => 'T37L::Item');
}

# ---------------------------------------------------------------- recording hooks
# Wrapped once, for the whole file: what the pool and the executor did.
our (@RELEASED, @HANDED);

# An error on one line, without the places it was raised at.
sub bare {
  my ($err) = @_;
  $err = "$err";
  $err =~ s{ at \S+ line \d+\.?}{}g;
  $err =~ s{\s*\n\s*\.?\s*}{ | }g;
  $err =~ s{[\s|]+\z}{};
  return $err;
}
{
  no warnings 'redefine';
  my $release = \&DBIO::Storage::PoolBase::release;
  my $execute = \&DBIO::MySQL::EV::QueryExecutor::execute;

  # Every release: which handle, on which session, with how much still pending
  # in EV::MariaDB.
  *DBIO::Storage::PoolBase::release = sub {
    my ($pool, $conn) = @_;
    push @RELEASED, {
      conn      => Scalar::Util::refaddr($conn),
      tid       => scalar eval { $conn->thread_id },
      in_flight => scalar eval { $conn->pending_count },
    };
    goto &$release;
  };

  # Every statement the transport hands to EV::MariaDB, in order: what was
  # pending on the handle then, whether EV::MariaDB refused it, and how its
  # Future ended.
  *DBIO::MySQL::EV::QueryExecutor::execute = sub {
    my ($self, $mdb, $sql, $bind) = @_;
    my $entry = { sql => $sql, pending => scalar eval { $mdb->pending_count }, end => 'pending' };
    push @HANDED, $entry;
    my ($f, $err);
    {
      local $@;
      eval { $f = $execute->($self, $mdb, $sql, $bind); 1 } or $err = $@;
    }
    if (defined $err) {
      $entry->{end} = 'refused: ' . bare($err);
      die $err;
    }
    $f->on_ready(sub {
      my ($done) = @_;
      $entry->{end} = $done->is_cancelled ? 'cancelled'
                    : $done->is_failed    ? 'failed: ' . bare($done->failure)
                    :                       'done';
    });
    return $f;
  };
}
sub reset_records { @RELEASED = (); @HANDED = (); @warnings = () }

sub short {
  my ($sql) = @_;
  return 'LII'   if $sql =~ /LAST_INSERT_ID/;
  return 'SLEEP' if $sql =~ /SLEEP\(/;
  return $sql =~ /^\s*(\w+)/ ? uc $1 : $sql;
}

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
  return $dbh;
}

my $admin = raw();
my $VERSION_STRING = $admin->selectrow_array('SELECT VERSION()');
my $IS_MARIADB     = $VERSION_STRING =~ /MariaDB/i ? 1 : 0;

# Wait for $f: (1, $first_value) once it is done, (0, $error) once it failed,
# (undef, $why) when it was cancelled or is still pending after $t seconds.
sub outcome {
  my ($f, $t) = @_;
  wait_until(sub { $f->is_ready }, $t // 20) or return (undef, 'still pending');
  return (undef, 'cancelled') if $f->is_cancelled;
  return $f->is_failed ? (0, scalar $f->failure) : (1, ($f->get)[0]);
}

my @ALL_H;
sub new_harness {
  my $h = DBIO::MySQL::EV::TestHarness->new(
    schema_class  => 'T37L::Schema',
    connect_attrs => { pool_size => 1 },
  );
  push @ALL_H, $h;
  $h->warm_pool;
  reset_records();
  return $h;
}
sub end_harness { my ($h) = @_; eval { $h->disconnect } }

# The pool's one connection, and whether the pool still holds a given one.
sub the_conn { (grep { defined } @{ $_[0]->pool->{_connections} })[0] }
sub held     { my ($h, $conn) = @_; scalar grep { defined && $_ == $conn } @{ $h->pool->{_connections} } }

my $SERIAL = 0;
sub tag { 'k74-' . $$ . '-' . ++$SERIAL }

# The session that runs a statement whose text carries $tag, seen from the
# second session; nothing when no session does.
sub running_on {
  my ($tag) = @_;
  return scalar $admin->selectrow_array(
    'SELECT ID FROM information_schema.PROCESSLIST WHERE ID <> CONNECTION_ID() AND INFO LIKE ? LIMIT 1',
    undef, "%$tag%");
}
sub command_of {
  my ($tid) = @_;
  return scalar $admin->selectrow_array('SELECT COMMAND FROM information_schema.PROCESSLIST WHERE ID = ?', undef, $tid);
}
sub rows_named {
  my ($name) = @_;
  return scalar $admin->selectrow_array("SELECT COUNT(*) FROM `$TABLE` WHERE name = ?", undef, $name);
}

# Ask the session of a handle something, on the handle itself and past the
# pool, once EV::MariaDB has nothing pending on it. Nothing when it cannot be
# asked: a handle that was closed, or one that stays busy.
sub ask {
  my ($conn, $sql) = @_;
  wait_until(sub { !eval { $conn->pending_count } }, 10) or return;
  my ($rows, $err, $done);
  eval { $conn->query($sql, sub { ($rows, $err) = @_; $done = 1 }); 1 } or return;
  wait_until(sub { $done }, 10) or return;
  return $err ? undef : $rows;
}

# The session's own statement counters from its spawn on: the reset that ends
# a borrow (karr k100, core k398) zeroes them, the harness adds the readings
# taken ahead of each reset to the current one. Other clients of the server do
# not show up in them.
sub session_status {
  my ($h, $conn) = @_;
  return $h->session_status($conn);
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

# ---------------------------------------------------------------- server objects
$admin->do("DROP TABLE IF EXISTS `$TABLE`");
$admin->do("CREATE TABLE `$TABLE` (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(50) NOT NULL) ENGINE=InnoDB");

my @RAW_HANDLES;
my $OPENER = $$;
END {
  if (defined $OPENER && $$ == $OPENER) {
    local ($@, $?);
    # The pool's sessions and the handle of part R first: one that sits in a
    # transaction would make the DROP wait for a metadata lock.
    eval { $_->disconnect } for @ALL_H;
    eval { $_->finish } for grep { defined } @RAW_HANDLES;
    eval {
      my $dbh = DBI->connect($DSN, $USER, $PASS, { RaiseError => 1, PrintError => 0 });
      $dbh->do('SET SESSION lock_wait_timeout = 10');
      $dbh->do("DROP TABLE IF EXISTS `$TABLE`");
      $dbh->disconnect;
    };
  }
}

diag "server: $VERSION_STRING, EV::MariaDB " . EV::MariaDB->VERSION;

# ====================================================================== R)
# Issue a query on $mdb: (undef, \%answer) when EV::MariaDB took it -- %answer
# is filled once it is answered --, ($error) when it croaked.
sub try_query {
  my ($mdb, $sql) = @_;
  my %answer;
  my $taken = eval { $mdb->query($sql, sub { @answer{qw( rows err )} = @_; $answer{answered} = 1 }); 1 };
  return $taken ? (undef, \%answer) : (bare($@));
}

subtest 'R) EV::MariaDB itself: a query while an operation of a prepared statement is in flight' => sub {
  my $info = DBIO::MySQL::EV::ConnectInfo::dbi_to_conninfo([ $DSN, $USER, $PASS ]);
  my ($up, @errors);
  my $mdb = EV::MariaDB->new(
    %{ $info->[0] },
    on_connect => sub { $up = 1 },
    on_error   => sub { push @errors, $_[0] },
  );
  push @RAW_HANDLES, $mdb;
  ok wait_until(sub { $up || @errors }, 15) && $up, 'a handle of its own is connected'
    or return diag "connect failed: @errors";
  my $tid = $mdb->thread_id;
  my $tag = tag();

  # --- at top level, no callback of the handle running
  my ($stmt, $perr, $prepared);
  $mdb->prepare("SELECT SLEEP(?), '$tag'", sub { ($stmt, $perr) = @_; $prepared = 1 });
  ok !$prepared, 'prepare: its callback has not run when prepare returns -- it is in flight';
  is $mdb->pending_count, 1, '... and counted as pending';
  my ($refused) = try_query($mdb, 'ROLLBACK');
  is $refused, $REFUSAL, 'a query while a prepare is in flight croaks';
  is $mdb->pending_count, 1, '... and is not queued';
  ok wait_until(sub { $prepared }, 10), 'the prepare is answered all the same';
  ok defined $stmt && !$perr, '... with a statement' or return diag 'prepare failed: ' . ($perr // 'no statement');

  my ($rows, $eerr, $executed);
  $mdb->execute($stmt, [ $SLEEP ], sub { ($rows, $eerr) = @_; $executed = 1 });
  ok !$executed, 'execute: its callback has not run when execute returns -- it is in flight';
  ($refused) = try_query($mdb, 'ROLLBACK');
  is $refused, $REFUSAL, 'a query while an execute was just issued croaks';
  ok wait_until(sub { (running_on($tag) // 0) == $tid }, 10), 'the statement runs on the server';
  ($refused) = try_query($mdb, 'ROLLBACK');
  is $refused, $REFUSAL, 'a query while the statement runs on the server croaks';
  is $mdb->pending_count, 1, '... and is not queued';
  ok wait_until(sub { $executed }, 10), 'the execute is answered all the same';
  is_deeply $rows, [ [ 0, $tag ] ], '... with its rows' or diag 'execute failed: ' . ($eerr // 'no error');

  my $closed;
  $mdb->close_stmt($stmt, sub { $closed = 1 });
  ok $closed, 'close_stmt: its callback HAS run when close_stmt returns -- it is never in flight';
  is $mdb->pending_count, 0, '... and nothing is pending';
  my ($err, $answer) = try_query($mdb, q{SELECT 'behind the close'});
  is $err, undef, 'a query right behind close_stmt is taken';
  ok $answer && wait_until(sub { $answer->{answered} }, 10), '... and answered';
  is_deeply $answer && $answer->{rows}, [ [ 'behind the close' ] ], '... with its own rows';

  # --- inside callbacks of the handle, where the transport meets it: a
  # transaction's coderef runs in the callback of BEGIN, a ->then in the
  # callback of the statement before it
  my (%in, $done);
  $mdb->query('SELECT 1', sub {
    my $stmt2;
    $mdb->prepare('SELECT ?', sub {
      ($stmt2) = @_;
      $mdb->execute($stmt2, [ 7 ], sub {
        @in{qw( execute_cb answer )} = try_query($mdb, q{SELECT 'in the callback of the execute'});
        my $closed2;
        $in{close_croak} = eval { $mdb->close_stmt($stmt2, sub { $closed2 = 1 }); 1 } ? undef : bare($@);
        $in{closed_at_once} = $closed2;
        $done = 1;
      });
      ($in{prepare_cb}) = try_query($mdb, 'ROLLBACK');
    });
    ($in{query_cb}) = try_query($mdb, 'ROLLBACK');
  });
  ok wait_until(sub { $done && $in{answer} && $in{answer}{answered} }, 10), 'a query, a prepare and an execute, each in the callback of the one before';
  is $in{query_cb}, $REFUSAL, 'a query in the callback of a query, behind a prepare issued there, croaks';
  is $in{prepare_cb}, $REFUSAL, 'a query in the callback of a prepare, behind an execute issued there, croaks';
  is $in{execute_cb}, undef, 'a query in the callback of an execute is taken: the handle is idle again there';
  is $in{close_croak}, undef, '... a close_stmt issued behind it is taken too';
  ok $in{closed_at_once}, '... and has called back when it returns';
  is_deeply $in{answer}{rows}, [ [ 'in the callback of the execute' ] ], '... and the query is answered with its own rows';

  is_deeply \@errors, [], 'the handle reported no error of its own';
  is_deeply \@warnings, [], 'nothing warned';
  my $fin;
  eval { $mdb->close_async(sub { $fin = 1 }); 1 } and wait_until(sub { $fin }, 5);
};

# ====================================================================== T)
# One case: a transaction on a pool of one whose coderef inserts row X and
# which fails with a statement with bind values in flight.
#   run($ctx, $s)  the coderef; $s is the case's state: {x} the row's name,
#                  {tag} the slow statement's tag, {source}; it puts the
#                  statement's Future in {stmt} and what was pending on the
#                  handle when it had issued it in {pending}
#   fail($s)       makes the transaction fail from outside the coderef; absent
#                  when the coderef does it itself
#   phase          'prepare' or 'execute': what is in flight when it fails
#   cause          what the transaction's error has to say
sub txn_case {
  my ($label, %case) = @_;

  subtest "T) $label" => sub {
    my $h     = new_harness();
    my $async = $h->async;
    my $conn  = the_conn($h);
    my $tid   = $conn->thread_id;
    my %s     = (x => 'x-' . tag(), tag => tag(), source => $h->schema->source('Item'));
    my $before = session_status($h, $conn);
    ok $before, "$label: premise: the session's counters are read";
    reset_records();

    my $txn = $async->txn_do_async(sub { $case{run}->($_[0], \%s) });
    if ($case{phase} eq 'execute') {
      ok wait_until(sub { (running_on($s{tag}) // 0) == $tid }, 10),
        "$label: premise: the statement runs on the server, inside the transaction"
        or return end_harness($h);
      is command_of($tid), 'Execute', "$label: premise: as the execute of a prepared statement";
      is $conn->pending_count, 1, "$label: premise: and EV::MariaDB waits for its answer";
    }
    $case{fail}->(\%s) if $case{fail};

    # --- the transaction fails
    my ($ok, $err) = outcome($txn);
    is $ok, 0, "$label: the transaction fails" or diag defined $ok ? 'it completed' : "it did not settle: $err";
    like $ok ? '' : "$err", $case{cause}, "$label: with the error of what made it fail";
    is $s{pending}, 1, "$label: premise: an operation of the statement was in flight when it was issued"
      if $case{phase} eq 'prepare';

    # --- the moment it failed: where is the connection, and in what state?
    my %at = (
      held      => held($h, $conn),
      idle      => $h->pool->available,
      # the COM_RESET_CONNECTION the pool sends at once (karr k100, core k398)
      # is no statement of the transaction
      pending   => scalar eval { $h->pool->_connection_is_resetting($conn) ? 0 : $conn->pending_count },
      released  => [ map { [ $_->{tid}, $_->{in_flight} ] } @RELEASED ],
    );
    my $mine = tag();
    my ($cok, $crow) = outcome($async->_query_async(q{SELECT CONNECTION_ID(), ?}, [ $mine ]));

    # --- once the wire is quiet
    ok wait_until(sub { !$at{held} || !eval { $conn->pending_count } }, 15),
      "$label: the statement in flight is answered in the end";
    pause(0.3);   # a second release would have come by now
    my $handed = join ', ', map { short($_->{sql}) . " [$_->{end}]" } @HANDED;
    my ($rollback) = grep { $_->{sql} eq 'ROLLBACK' } @HANDED;
    my $after  = $at{held} ? session_status($h, $conn) : undef;
    my %delta  = $after ? map { ($_ => $after->{"Com_$_"} - $before->{"Com_$_"}) } qw( begin rollback commit ) : ();
    my $open   = $at{held} ? txn_open($conn, $tid) : 0;
    my $trx    = innodb_trx($tid);
    my $x_before = rows_named($s{x});

    is $delta{commit} // 0, 0, "$label: the transaction sent no COMMIT";
    is $x_before, 0, "$label: a second session does not see row X before another transaction runs";

    # --- the next transaction on the pool: rolled back itself
    my $next_tid;
    my ($nok, $nerr) = outcome($async->txn_do_async(sub {
      $next_tid = $_[0]->txn_conn->thread_id;
      die "the next transaction is rolled back too\n";
    }));
    is $nok, 0, "$label: the next transaction on the pool fails as its coderef says"
      or diag defined $nok ? 'it completed' : "it did not settle: $nerr";
    like $nok ? '' : "$nerr", qr/rolled back too/, "$label: with its own error";
    pause(0.2);
    my $x_after = rows_named($s{x});
    # One release each for the transaction, the call issued when it failed and
    # the next transaction.
    cmp_ok scalar(grep { $_->{conn} == Scalar::Util::refaddr($conn) } @RELEASED), q{<=}, 3,
      "$label: the transaction does not hand its connection back twice";

    # --- what was measured
    diag "$label:";
    diag '  the transaction failed with: ' . bare($ok ? 'nothing' : $err);
    diag "  handed to EV::MariaDB: $handed";
    diag '  ROLLBACK was handed over with ' . ($rollback ? $rollback->{pending} : '?') . ' operation(s) pending on the handle'
      . ' and ended: ' . ($rollback ? $rollback->{end} : 'never handed over');
    diag '  the moment it failed: connection ' . ($at{held} ? 'in the pool' : 'not in the pool') . ", idle=$at{idle}, "
      . 'pending on the handle=' . ($at{pending} // 'undef')
      . ', releases [session, pending]=' . join(' ', map { '[' . join(',', map { $_ // 'undef' } @$_) . ']' } @{ $at{released} });
    diag '  a call issued that moment: ' . ($cok ? "ran on session $crow->[0]" : defined $cok ? 'failed: ' . bare($crow) : $crow);
    diag '  the server, once the wire was quiet: ' . (%delta ? "Com_begin +$delta{begin}, Com_rollback +$delta{rollback}, Com_commit +$delta{commit}" : 'session not asked')
      . '; transaction open: ' . ($open // 'undef') . "; InnoDB transactions of the session: $trx";
    diag "  row X seen by a second session: $x_before before the next transaction, $x_after after it "
      . '(BEGIN ... ROLLBACK on session ' . ($next_tid // 'undef') . ", the failed transaction's was $tid)";
    is_deeply \@warnings, [], "$label: no callback died out of EV::MariaDB, nothing warned";

    # --- what holds since karr k74 is solved (they were TODO, red on both
    # servers in all four cases, as the header says; the assertions are the
    # same). Each is met as well by a connection the pool no longer holds: a
    # session that was ended has no transaction open.
    ok !$at{held} || ($delta{rollback} // 0) == 1,
      "$label: ROLLBACK reached the server (the session's Com_rollback)";
    ok !$at{held} || !$at{pending},
      "$label: the pool is not left holding the connection with a statement of the failed transaction in flight";
    ok !$at{held} || (defined $open && !$open),
      "$label: nor with the transaction open";
    ok $cok, "$label: a call issued the moment the transaction failed runs";
    is $x_after, 0, "$label: after the next transaction on the pool row X is NOT there -- nothing of the failed one was committed";
    end_harness($h);
  };
}

# A slow statement with a bind value: prepare, execute, close_stmt.
sub slow_bound { my ($ctx, $s) = @_; $ctx->_query_async("SELECT SLEEP(?), '$s->{tag}'", [ $SLEEP ]) }

# Row X, inserted with a bind value and awaited; $then runs in its callback.
sub insert_x_then {
  my ($ctx, $s, $then) = @_;
  return $ctx->_query_async("INSERT INTO `$TABLE` (name) VALUES (?)", [ $s->{x} ])->then($then);
}

txn_case('T1, a statement with bind values cancelled while it runs on the server (execute in flight)',
  phase => 'execute',
  cause => $CANCELLED,
  run   => sub {
    my ($ctx, $s) = @_;
    return insert_x_then($ctx, $s, sub { $s->{stmt} = slow_bound($ctx, $s); return 'gave up' });
  },
  fail => sub { $_[0]{stmt}->cancel },
);

txn_case('T2, a statement with bind values cancelled in the callback that issued it (prepare in flight)',
  phase => 'prepare',
  cause => $CANCELLED,
  run   => sub {
    my ($ctx, $s) = @_;
    return insert_x_then($ctx, $s, sub {
      $s->{stmt}    = slow_bound($ctx, $s);
      $s->{pending} = $ctx->txn_conn->pending_count;
      $s->{stmt}->cancel;
      return 'gave up';
    });
  },
);

txn_case('T3, no cancel: the coderef dies with its INSERT of row X just issued (prepare in flight)',
  phase => 'prepare',
  cause => qr/the coderef died/,
  run   => sub {
    my ($ctx, $s) = @_;
    $s->{stmt}    = $ctx->insert_async($s->{source}, { name => $s->{x} });
    $s->{pending} = $ctx->txn_conn->pending_count;
    die "the coderef died\n";
  },
);

txn_case(q{T4, no cancel: the coderef's Future fails while a statement with bind values runs on the server (execute in flight)},
  phase => 'execute',
  cause => qr/gave up waiting/,
  run   => sub {
    my ($ctx, $s) = @_;
    return insert_x_then($ctx, $s, sub { $s->{stmt} = slow_bound($ctx, $s); return $s->{gate} = $EVF->new });
  },
  fail => sub { $_[0]{gate}->fail("gave up waiting\n") },
);

# ====================================================================== C)
# A COMMIT that fails retires the connection (karr k81, the claim of
# t/36-cancel-in-flight-mock.t section 13, live). A COMMIT cannot be made to
# fail by a constraint here (MySQL checks them per statement, nothing is
# deferred), so the session of the pinned connection is ended -- its OWN
# session only, by id, from the second session -- after the coderef did its
# work and before core sends the COMMIT. The coderef returns a gate Future, the
# transaction waits on it.
#   the transaction fails (it must not complete, the row must not be committed);
#   the connection is not in the pool afterwards, nothing is idle or checked
#   out, and the next call runs on a session with another id.
subtest 'C) a COMMIT that fails retires the connection' => sub {
  my $h     = new_harness();
  my $async = $h->async;
  my $conn  = the_conn($h);
  my $tid   = $conn->thread_id;
  my %s     = (x => 'x-' . tag(), source => $h->schema->source('Item'));
  reset_records();

  my $gate;
  my $txn = $async->txn_do_async(sub {
    my ($ctx) = @_;
    return insert_x_then($ctx, \%s, sub { return $gate = $EVF->new });
  });
  ok wait_until(sub { $gate }, 10), 'premise: the coderef inserted row X and waits';
  $admin->do("KILL $tid");   # the pinned connection's own session, by id
  ok wait_until(sub { !defined command_of($tid) }, 10), 'premise: that session is gone on the server';
  $gate->done('fine');

  my ($ok, $err) = outcome($txn);
  is $ok, 0, 'the transaction fails' or diag defined $ok ? 'it completed' : "it did not settle: $err";
  like $ok ? '' : "$err", qr/COMMIT failed|cannot queue|not connected|gone away|Lost connection|server has gone/i,
    'with the error of the COMMIT';
  my ($commit) = grep { $_->{sql} eq 'COMMIT' } @HANDED;
  ok $commit, 'premise: the transport handed a COMMIT to EV::MariaDB';

  pause(0.3);
  ok !held($h, $conn), 'the connection is retired, not handed back to the pool';
  is $h->pool->available, 0, 'nothing idle in the pool';
  cmp_ok scalar(grep { $_->{conn} == Scalar::Util::refaddr($conn) } @RELEASED), q{<=}, 1,
    'and it was handed back at most once, to be retired';

  my ($cok, $crow) = outcome($async->_query_async(q{SELECT CONNECTION_ID()}, []));
  ok $cok, 'the next call runs (no checkout hangs)' or diag defined $cok ? bare($crow) : $crow;
  isnt $cok ? $crow->[0] : undef, $tid, 'on a newly opened session, not the one that was ended';
  is rows_named($s{x}), 0, 'nothing of the transaction was committed';

  my ($tok, $trow) = outcome($async->txn_do_async(sub { $_[0]->_query_async('SELECT 1', [ ]) }));
  ok $tok, 'and a transaction on the pool completes' or diag defined $tok ? bare($trow) : $trow;

  diag 'COMMIT handed over with ' . ($commit ? $commit->{pending} : '?') . ' operation(s) pending, ended: '
    . ($commit ? $commit->{end} : 'never handed over');
  diag '  the transaction failed with: ' . bare($ok ? 'nothing' : $err);
  is_deeply \@warnings, [], 'no callback died out of EV::MariaDB, nothing warned';
  end_harness($h);
};

$admin->disconnect;
done_testing;
