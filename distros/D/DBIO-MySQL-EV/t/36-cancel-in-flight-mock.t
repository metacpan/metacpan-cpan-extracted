use strict;
use warnings;
use Test::More;

# OFFLINE test for karr k73: a statement Future cancelled while its statement
# is in flight -- on the pooled path and inside txn_do_async.
#
# WHY: cancelling the Future a caller was given, or losing it in a wait_any
# against a timeout, is the only way a caller has to stop waiting, and it is a
# client-side act: EV::MariaDB knows nothing of it. The statement is on the
# server, its answer is on its way, and the callback this transport handed to
# EV::MariaDB stays in EV::MariaDB's queue -- the connection is busy, not free
# and not dead. A statement with bind values is busier still: it is prepare,
# execute and close_stmt, three exclusive operations, each started from the
# callback of the one before. Handed out in that state, the connection fails
# its next caller: EV::MariaDB refuses a prepare while anything is in flight,
# and a query while a statement operation is. What is at stake: the connection
# goes back to the pool exactly once -- not at the cancel, and not never --,
# with nothing in flight and no prepared statement left open on the server; the
# late answer does not reach the statement that runs next on it; and a
# transaction is rolled back, never committed.
#
# What this file claims, through the REAL storage, pool, executor and core
# transaction scaffold over a stand-in EV::MariaDB:
#   1. pooled, on a warm and on a cold pool, a statement with bind values and
#      one without: the cancel alone releases nothing and the connection is
#      not idle; what the transport began it finishes -- a prepared statement
#      is closed --, and the connection stays checked out until the last
#      answer; that answer releases it, once, with nothing in flight and no
#      statement open; the Future stays cancelled; the next call runs on the
#      same connection and gets its own rows;
#   2. pooled, pool of one, the next call issued BEFORE the late answer (before
#      or after the cancel): it is not sent while the cancelled statement is in
#      flight; the late answer hands the connection on to it without settling
#      it; it is sent then and settles with its own rows; one release each;
#   3. pooled, the late answer is not a result: a server error the session
#      survives leaves the connection in the pool, released once; a lost
#      connection is retired once, and the call waiting for it runs on a newly
#      opened one;
#   4. pooled insert_async, which is INSERT and SELECT LAST_INSERT_ID() on one
#      pooled connection (MySQL has no RETURNING), cancelled while any of its
#      operations is in flight: the cancel releases nothing; the connection
#      comes back once, after the last answer; the next insert gets the id of
#      its own row. Whether a cancelled insert still sends what it had not
#      sent yet is NOT claimed -- it does, the row is inserted and
#      LAST_INSERT_ID() is read; the file notes the wire it saw;
#   5. pinned, a statement of a txn_do_async coderef sent as a plain query (no
#      bind values) and cancelled in flight -- in the coderef, after it
#      returned, as the loser of a wait_any, or with its LAST_INSERT_ID() in
#      flight: nothing is sent ahead of the cancelled statement, ROLLBACK goes
#      on the wire behind it and never COMMIT; the late answer does not end
#      the transaction; it fails with core's "cancelled before it was
#      answered" error, or with the error that won the wait_any; the
#      connection comes back once, no transaction open, and the next call gets
#      its own rows;
#   6. pinned, a plain query behind the cancelled one (EV::MariaDB pipelines
#      queries): the late answer does not settle it, and it settles with its
#      own rows;
#   7. pinned, a statement cancelled while EV::MariaDB has only queued it (it
#      was issued in a callback of the connection): the transaction rolls back
#      and the connection comes back once. Whether such a statement is still
#      sent is NOT claimed (it is, inside the transaction that is then rolled
#      back) -- the file notes what it saw;
#   8. (12) statements waiting behind one in flight (execute_when_idle): one
#      cancelled before its turn, one whose dispatch croaks when its turn
#      comes, one whose handle was finished meanwhile -- each is failed or
#      dropped on its own Future, never sent, and does not stall the ones
#      behind it (karr k81);
#   9. no callback of this transport dies out of EV::MariaDB, and nothing
#      warns.
#
# 1 to 4 are a REGRESSION for karr k73. Until then the pooled path released at
# the cancel: Future.pm carries a cancel down the ->then chain to the Future
# whose on_ready releases the connection, and a cancelled Future is ready. The
# connection was idle with the cancelled statement in flight, and the next
# call on it failed with EV::MariaDB's refusal. The caller now gets a Future
# whose cancel stops at it (DBIO::MySQL::EV::Storage::_mysql_caller_future).
#
# SOLVED, karr k74 (9, 11, 12, 13): the cancelled statement of a transaction has BIND
# VALUES -- which is nearly every statement. Core sends ROLLBACK as soon as it
# knows of the cancel; EV::MariaDB refuses a query ("cannot queue query:
# exclusive operation in progress") while a prepare or an execute is in flight,
# and the connection used to go back to the pool with the transaction OPEN.
# The root is not the cancel: a coderef that dies with such a statement in
# flight is the same (9 has that variant; live in
# t/37-txn-rollback-refused-live.t). The transport now queues the ROLLBACK
# behind the statements in flight on its connection (QueryExecutor
# execute_when_idle) and retires a connection whose ROLLBACK fails (11). The
# queue of waiting statements does not stall on one that sends nothing (12),
# and a COMMIT that fails retires its connection as well (13). The fake's
# close_stmt is not in flight, as the real one never is (live measurement,
# t/37 part R): it has called back by the time it returns, so the ROLLBACK
# waits for the prepare or execute in flight, and goes out from the callback
# that settles the statement (karr k81).
#
# (10) The cancelled Future is the very one the coderef returned. Future.pm
# runs no ->then callback of a cancelled Future, and txn_do_async used to hang
# the end of the transaction off a ->then of the coderef's Future: no
# ROLLBACK, no COMMIT, no release. Core ends the transaction from the
# cancellation itself now (karr core k274): the transaction settles once the
# wire has answered, and its connection is handed back or retired, never left
# with the transaction open.
#
# THE ONE SUBSTITUTION is EV::MariaDB itself, as in t/32, whose fake this one
# starts from: a real socketpair for its socket, the lost session, "not
# connected", a close_async that croaks without a callback. Added here is
# EV::MariaDB's scheduling, since that is what a cancelled statement meets.
# What the fake assumes of EV::MariaDB 0.08, and where each part comes from:
#   - Nothing a Future does reaches EV::MariaDB. A callback handed to it stays
#     in its queue until the operation is answered; skip_pending is the one
#     call that drops queued callbacks (POD), and this transport never calls
#     it. So the callback of a cancelled statement is still called, with that
#     statement's answer -- the assumption this whole file stands on. READ
#     (POD, and MariaDB.xs: push_cb / pop_cb), and MEASURED live by
#     t/36-cancel-in-flight-live.t: the server goes on running a cancelled
#     statement, and it is answered with its result.
#   - query can be queued at any time and callbacks fire in the order queued
#     (POD, METHODS and PIPELINING). A query taken while the handle waits for
#     an answer is sent once that answer was read, and one taken while a
#     callback of the handle runs once that callback returned (MariaDB.xs:
#     query() advances the pipeline only with state IDLE and callback_depth
#     0; pipeline_advance and maybe_pipeline do it after every callback). The
#     second half was MEASURED live for karr k48 (ADR 0001). Of the first,
#     that such a query is taken and answered behind the one in flight is
#     MEASURED live by t/36-cancel-in-flight-live.t (5, 6); when it is put on
#     the wire is READ.
#   - prepare, execute and close_stmt are exclusive: each croaks "another
#     operation is in progress" while the handle is not idle, and "cannot
#     start operation while pipeline results are pending" while a query's
#     answer is due (MariaDB.xs, CHECK_READY; POD). MEASURED against MariaDB
#     10.11.19 for ADR 0010, fact 1.
#   - query croaks "cannot queue query: exclusive operation in progress" while
#     a prepare, execute or close_stmt is in flight (MariaDB.xs: state >=
#     STATE_STMT_PREPARE; the POD says a query is buffered behind an exclusive
#     operation and names ping and select_db, which are below that line).
#     MEASURED live by t/37-txn-rollback-refused-live.t, part R, for a prepare
#     and an execute in flight (MySQL 8.0.30, MariaDB 11.8.8); the live
#     t/13-async-e2e.t keeps to one statement in flight on a pinned connection
#     to stay clear of that refusal. Section 9 stands on it.
#     The fake's close_stmt matches that (karr k81): it has called back by the
#     time it returns and is never in flight. It used to wait for an answer
#     like the other two; what this file showed with a close in flight (the
#     last step of a statement with bind values in 1 and 2, the stage 'close
#     doomed' in 4, a ROLLBACK waiting for a close in 9) was shown for a state
#     the real client is never in, and is gone: a statement with bind values
#     is now two answers, and the answer to its execute sends the close and
#     settles the statement in one step.
#   - An operation's callback runs with the handle idle again and with
#     pending_count already taken down, under an eval that only warns
#     (MariaDB.xs: the *_done handlers, deliver_result, invoke_cb). READ; for
#     the callback of an execute MEASURED live (the same part R).
#   - A lost session is t/32's, measured for ADR 0010, fact 3: the operation
#     that finds the session ended fails through its callback and the socket
#     is given up (-1); is_connected stays true.
# And of the server: LAST_INSERT_ID() is the session's, and BEGIN commits a
# transaction that is still open (MySQL's implicit commit; documented, not
# measured here).
#
# With $EV::MariaDB::HOLD set no answer is delivered until the test delivers
# it (t_deliver), so each step can be looked at; the connect is not held. A
# statement is named by its table -- BEGIN, COMMIT and ROLLBACK by their verb,
# SELECT LAST_INSERT_ID() as LII -- and the "server" answers a SELECT with a
# row naming that table, so every statement's rows are its own. It keeps the
# transaction state, the prepared statements it holds, and which inserted rows
# were committed.

BEGIN {
  eval { require EV; 1 }     or plan skip_all => 'EV not installed';
  eval { require Future; 1 } or plan skip_all => 'Future not installed';
}

BEGIN {
  package EV::MariaDB;
  use Carp ();
  use Socket ();
  use Scalar::Util ();

  our $HOLD;        # true: answers wait for t_deliver
  our @MADE;        # every handle made, in order (weak)
  our @COMMITTED;   # the table of every row the server has committed
  our %ROW_ID;      # table => the id of the row last inserted into it
  our %FAIL;        # table => message: the server answers such a statement with it
  our %CROAK;       # table => message: sending such a statement croaks, nothing is sent

  my $serial  = 0;
  my $next_id = 100;   # the server's auto-increment counter, one for all tables

  sub new {
    my ($class, %args) = @_;
    socketpair(my $client, my $server, Socket::AF_UNIX(), Socket::SOCK_STREAM(), Socket::PF_UNSPEC())
      or die "socketpair: $!";
    my $self = bless {
      serial     => ++$serial,
      on_connect => $args{on_connect},
      on_error   => $args{on_error},
      client     => $client,
      server     => $server,
      conn       => 1,
      connected  => 0,
      depth      => 0,       # callback_depth
      op         => undef,   # the exclusive operation in flight
      queue      => [],      # queries taken, not sent yet
      sent       => [],      # queries sent, result not read yet
      reading    => 0,       # waiting for the result at the head of sent
      stmts      => {},      # the prepared statements the server holds
      next       => 0,
      wire       => [],      # what the server received, in order
      intrans    => 0,
      rows       => [],      # inserted in the open transaction
      lii        => 0,       # the session's LAST_INSERT_ID()
    }, $class;
    push @MADE, $self;
    Scalar::Util::weaken($MADE[-1]);
    my $t;
    $t = EV::timer(0.001, 0, sub {
      undef $t;
      $self->{connected} = 1;
      $self->_callback($self->{on_connect});
      $self->_advance;
    });
    return $self;
  }

  sub serial        { $_[0]{serial} }
  sub is_connected  { $_[0]{conn} && $_[0]{connected} ? 1 : 0 }   # true after death, as the real one
  sub pending_count { ($_[0]{op} ? 1 : 0) + @{ $_[0]{queue} } + @{ $_[0]{sent} } }
  sub socket        { $_[0]{conn} && $_[0]{client} ? fileno $_[0]{client} : -1 }

  # BEGIN, COMMIT and ROLLBACK are named by their verb, LAST_INSERT_ID() is LII,
  # and every other statement by its table.
  sub _name {
    my ($sql) = @_;
    return 'LII' if $sql =~ /LAST_INSERT_ID/;
    return $1    if $sql =~ /\b(?:FROM|INTO|UPDATE)\s+`?(\w+)/;
    return $sql =~ /^(\w+)/ ? $1 : $sql;
  }

  # A callback of the handle: callback_depth is raised while it runs, and an
  # exception is caught and warned (G_EVAL).
  sub _callback {
    my ($self, $cb, @args) = @_;
    $self->{depth}++;
    eval { $cb->(@args) if $cb; 1 } or warn "EV::MariaDB: exception in callback: $@";
    $self->{depth}--;
    return;
  }

  # maybe_pipeline / pipeline_advance: an idle handle sends every query it has
  # taken, then waits for the first result.
  sub _advance {
    my ($self) = @_;
    return if !$self->{conn} || !$self->{connected} || $self->{op} || $self->{reading};
    for my $q (splice @{ $self->{queue} }) {
      push @{ $self->{wire} }, $q->{name};
      push @{ $self->{sent} }, $q;
    }
    $self->{reading} = 1 if @{ $self->{sent} };
    $self->_arm;
    return;
  }

  sub query {
    my ($self, $sql, $cb) = @_;
    Carp::croak('not connected') unless $self->{conn};
    Carp::croak('cannot queue query: exclusive operation in progress') if $self->{op};
    Carp::croak($CROAK{ _name($sql) }) if defined $CROAK{ _name($sql) };
    push @{ $self->{queue} }, { sql => $sql, name => _name($sql), cb => $cb };
    $self->_advance unless $self->{depth};
    return;
  }

  # CHECK_READY, for every exclusive operation.
  sub _exclusive {
    my ($self, $kind, $name, $cb, %op) = @_;
    Carp::croak('not connected') unless $self->{conn} && $self->{connected};
    Carp::croak('another operation is in progress') if $self->{op} || $self->{reading};
    Carp::croak('cannot start operation while pipeline results are pending') if @{ $self->{sent} };
    Carp::croak($CROAK{$name}) if defined $CROAK{$name};
    # COM_RESET_CONNECTION is no statement: the server's wire does not list it
    push @{ $self->{wire} }, "$kind $name" unless $kind eq q{reset};
    $self->{op} = { %op, kind => $kind, name => $name, cb => $cb };
    $self->_arm;
    return;
  }

  sub prepare {
    my ($self, $sql, $cb) = @_;
    return $self->_exclusive(prepare => _name($sql), $cb, sql => $sql);
  }

  sub execute {
    my ($self, $id, $bind, $cb) = @_;
    my $sql = $self->{stmts}{$id};
    Carp::croak('invalid statement handle') unless defined $sql;
    return $self->_exclusive(execute => _name($sql), $cb, sql => $sql);
  }

  # Sent by the pool at the end of every borrow (karr k100, core k398).
  sub reset_connection {
    my ($self, $cb) = @_;
    return $self->_exclusive(reset => q{RESET}, $cb, sql => q{RESET});
  }

  sub close_stmt {
    my ($self, $id, $cb) = @_;
    my $sql = $self->{stmts}{$id};
    Carp::croak('invalid statement handle') unless defined $sql;
    # The real close_stmt has called back by the time it returns and is never
    # in flight (t/37 part R): the statement is gone, the wire has seen it, and
    # the callback runs now, inside the call, as a callback of the handle.
    Carp::croak('not connected') unless $self->{conn} && $self->{connected};
    Carp::croak('another operation is in progress') if $self->{op} || $self->{reading};
    Carp::croak('cannot start operation while pipeline results are pending') if @{ $self->{sent} };
    push @{ $self->{wire} }, 'close ' . _name($sql);
    delete $self->{stmts}{$id};
    $self->_callback($cb, 1);
    return;
  }

  sub finish {
    my ($self) = @_;
    $self->{conn} = 0;
    my $had = delete $self->{client};
    close $had if $had;
    return;
  }

  sub close_async {
    my ($self, $cb) = @_;
    Carp::croak('Usage: EV::MariaDB::close_async(self, cb)') unless @_ == 2;
    Carp::croak('not connected') unless $self->{conn};
    $self->finish;
    $cb->(1);
    return;
  }

  # --- delivery ---------------------------------------------------------------

  sub _arm {
    my ($self) = @_;
    return if $HOLD || $self->{timer} || !$self->t_in_flight;
    Scalar::Util::weaken(my $weak = $self);
    $self->{timer} = EV::timer(0.001, 0, sub { $weak->_deliver if $weak });
    return;
  }

  # Is an answer of the server due on the handle?
  sub t_in_flight { $_[0]{op} || $_[0]{reading} ? 1 : 0 }

  # The server's answer to what is in flight arrives now.
  sub t_deliver {
    my ($self) = @_;
    Carp::croak('t_deliver: nothing is in flight') unless $self->t_in_flight;
    $self->_deliver;
    # The transport settles Futures from the loop's idle watcher (karr k51), so
    # what this answer settles is settled when the step has run.
    EV::run(EV::RUN_NOWAIT());
    return;
  }

  # Answers are delivered again after a hold: arm every handle that waits.
  sub t_resume { $_ && $_->_arm for @MADE; return }

  sub _deliver {
    my ($self) = @_;
    delete $self->{timer};
    if (my $op = delete $self->{op}) {
      $self->_callback($op->{cb}, $self->_outcome($op));
    }
    elsif ($self->{reading}) {
      my $q = shift @{ $self->{sent} };
      $self->{reading} = 0;
      $self->_callback($q->{cb}, $self->_outcome($q));
    }
    $self->_advance;
    $self->_arm;
    return;
  }

  sub _outcome {
    my ($self, $stmt) = @_;
    if ($self->{ended}) {
      # The client library finds the session ended and gives its socket up.
      my $had = delete $self->{client};
      close $had if $had;
      return (undef, $had ? 'Lost connection to server during query' : 'Server has gone away');
    }
    return $self->_serve($stmt);
  }

  # --- the server -------------------------------------------------------------

  sub _serve {
    my ($self, $stmt) = @_;
    my ($kind, $sql, $name) = @$stmt{qw( kind sql name )};
    $kind //= 'query';

    if ($kind eq 'prepare') {
      my $id = ++$self->{next};
      $self->{stmts}{$id} = $sql;
      return ($id);
    }
    if ($kind eq q{reset}) {
      # the session is clean: transaction rolled back, statements dropped
      @{ $self->{rows} } = ();
      $self->{intrans} = 0;
      $self->{stmts}   = {};
      $self->{lii}     = 0;
      return (1);
    }
    if ($kind eq 'close') {
      delete $self->{stmts}{ $stmt->{id} };
      return (1);
    }

    if ($sql eq 'BEGIN') {
      # BEGIN commits a transaction that is still open (an implicit commit).
      push @COMMITTED, splice @{ $self->{rows} };
      $self->{intrans} = 1;
      return (0);
    }
    if ($sql eq 'COMMIT') {
      return (undef, $FAIL{COMMIT}) if defined $FAIL{COMMIT};   # the transaction stays open
      push @COMMITTED, splice @{ $self->{rows} };
      $self->{intrans} = 0;
      return (0);
    }
    if ($sql eq 'ROLLBACK') {
      return (undef, $FAIL{ROLLBACK}) if defined $FAIL{ROLLBACK};   # the transaction stays open
      @{ $self->{rows} } = ();
      $self->{intrans} = 0;
      return (0);
    }
    return ([ [ $self->{lii} ] ]) if $name eq 'LII';
    return (undef, $FAIL{$name}) if defined $FAIL{$name};
    if ($sql =~ /^INSERT/) {
      $self->{lii} = $ROW_ID{$name} = ++$next_id;
      push @{ $self->{intrans} ? $self->{rows} : \@COMMITTED }, $name;
      return (1);
    }
    return ([ [ 'row-of', $name ] ]) if $sql =~ /^SELECT/;
    return (0);
  }

  # The server ends the session (KILL, a restart, wait_timeout): the client's
  # socket reads EOF, and every operation from here on finds the session gone.
  sub t_end_session {
    my ($self) = @_;
    my $server = delete $self->{server};
    close $server if $server;
    $self->{ended} = 1;
    return;
  }

  $INC{'EV/MariaDB.pm'} = __FILE__;
}

use DBIO::MySQL::EV::Storage;
use DBIO::MySQL::EV::Pool;

alarm 120;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

my $EVF = 'DBIO::MySQL::EV::Future';

my $CANCELLED = qr/cancelled before it was answered/;

# The real pool, with every release recorded: which connection came back, and
# in what state -- an operation still due on it, a transaction open, a prepared
# statement left on the server.
{
  package T36::Pool;
  our @ISA = ('DBIO::MySQL::EV::Pool');

  sub release {
    my ($self, $conn) = @_;
    push @{ $self->{t_released} }, {
      conn      => $conn->serial,
      in_flight => $conn->pending_count,
      in_txn    => $conn->{intrans},
      stmts     => scalar keys %{ $conn->{stmts} },
    };
    return $self->SUPER::release($conn);
  }
}

# A result source with an auto-increment id, so that insert_async puts the
# LAST_INSERT_ID() it read into the hashref it resolves.
{
  package T36::Source;
  sub new             { bless { name => $_[1] }, $_[0] }
  sub name            { $_[0]{name} }
  sub columns         { qw( id name ) }
  sub columns_info    { { id => { is_auto_increment => 1 }, name => {} } }
  sub primary_columns { qw( id ) }
}

# A real storage and pool of one over the fake EV::MariaDB.
sub pool_of_one {
  my $storage = DBIO::MySQL::EV::Storage->new(undef);
  $storage->connect_info([ { host => 'fake', database => 'fake', pool_size => 1 }, {} ]);
  bless $storage->pool, 'T36::Pool';
  return $storage;
}

# Wait for $f on the EV loop: (1, @result) once it is done, (0, $error) once it
# failed. A Future still pending after 5 seconds is failed by the watchdog.
sub wait_for {
  my ($f) = @_;
  EV::now_update();   # a timer counts from the loop's last "now", maybe long ago
  EV::MariaDB->t_resume;
  my $dog = EV::timer(5, 0, sub { $f->fail("watchdog: still pending after 5s\n") unless $f->is_ready });
  $dog->keepalive(0);
  my @r;
  return (1, @r) if eval { @r = $f->get; 1 };
  return (0, $@);
}

# Run the EV loop until $cond holds; false if it does not within 5 seconds.
sub spin_until {
  my ($cond) = @_;
  EV::now_update();
  my $late = 0;
  my $dog  = EV::timer(5, 0, sub { $late = 1 });
  EV::run(EV::RUN_ONCE()) until $late || $cond->();
  return !$late;
}

# Let every timer the fake still has run out, so a callback that would fire
# late -- and release a second time -- has fired before the pool is counted.
sub settle {
  my $done = 0;
  EV::now_update();
  EV::MariaDB->t_resume;
  my $t = EV::timer(0.05, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

# The server's answer to what is in flight on $conn arrives now. With nothing
# in flight there is nothing to deliver, and that is a failure.
sub deliver {
  my ($conn) = @_;
  return $conn->t_deliver if $conn->t_in_flight;
  fail 'an answer was due on the connection, but nothing is in flight on it';
  return;
}

# Every answer the server still owes on $conn, one after the other.
sub run_out {
  my ($conn) = @_;
  my $n = 0;
  $conn->t_deliver while $conn->t_in_flight && ++$n <= 20;
  return $n;
}

sub the_conn { $_[0]->pool->{_connections}[0] }
sub wire     { [ @{ $_[0]{wire} } ] }
sub released { [ @{ $_[0]->pool->{t_released} || [] } ] }
sub clean    { { conn => $_[0]->serial, in_flight => 0, in_txn => 0, stmts => 0 } }
# The answers the server owes for a statement: a plain query one, prepare and
# execute two. close_stmt is a third wire step but no answer (it is never in
# flight, see the fake's close_stmt).
sub answers  { $_[0] eq 'bound' ? 2 : 1 }
sub pooled   { scalar grep { $_ == $_[1] } @{ $_[0]->pool->{_connections} } }

# A SELECT with a bind value is prepare, execute and close_stmt; one without is
# a plain query. $on is the storage, or a transaction context.
my %SELECT = (
  bound => sub { my ($on, $name) = @_; $on->select_async($name, [qw( tag name )], { tag => 1 }) },
  plain => sub { my ($on, $name) = @_; $on->select_async($name, [qw( tag name )]) },
);

# What a statement puts on the wire, one answer for each.
sub on_wire {
  my ($kind, $name) = @_;
  return $kind eq 'bound' ? map({ "$_ $name" } qw( prepare execute close )) : ($name);
}

# A pool of one whose connection is spawned and idle, a clean wire, a clean
# server, nothing released yet.
sub fresh {
  my $storage = pool_of_one();
  my ($ok, @r) = wait_for($SELECT{plain}->($storage, 'warm'));
  die "warming the pool failed: $r[0]" unless $ok;
  settle();
  my $conn = the_conn($storage);
  @{ $conn->{wire} } = ();
  @{ $storage->pool->{t_released} } = ();
  @EV::MariaDB::COMMITTED = ();
  %EV::MariaDB::ROW_ID = ();
  @warnings = ();
  return ($storage, $conn);
}

# The state of a Future.
sub state_of {
  my ($f) = @_;
  return !$f->is_ready ? 'pending' : $f->is_cancelled ? 'cancelled' : $f->is_failed ? 'failed' : 'done';
}

sub nothing_warned {
  my ($label) = @_;
  is_deeply \@warnings, [], "$label: no callback died out of EV::MariaDB, nothing warned";
  @warnings = ();
}

# With answers delivered again: the pool has its one connection, idle, with no
# transaction open, no answer due and no statement left open -- and the next
# call, a statement with a bind value, runs on it and gets its own rows.
sub next_call_is_its_own {
  my ($label, $storage, $conn) = @_;
  local $EV::MariaDB::HOLD = 0;
  settle();
  is $storage->pool->size, 1, "$label: the pool still has its one connection";
  is $storage->pool->available, 1, "$label: idle";
  is $conn->{intrans}, 0, "$label: no transaction open on it";
  is $conn->pending_count, 0, "$label: no answer due on it";
  is scalar keys %{ $conn->{stmts} }, 0, "$label: no prepared statement left open on it";

  my $before = @{ released($storage) };
  my ($ok, @r) = wait_for($SELECT{bound}->($storage, 'next'));
  ok $ok, "$label: the next call completes" or diag "it failed: $r[0]";
  is_deeply \@r, [ [ 'row-of', 'next' ] ], "$label: with its own rows";
  is_deeply [ @{ wire($conn) }[-3 .. -1] ], [ on_wire(bound => 'next') ], "$label: on the same connection";
  settle();
  is @{ released($storage) } - $before, 1, "$label: and releases it once";
  is $storage->pool->available, 1, "$label: idle again";
  nothing_warned($label);
}

# --- 1. pooled: cancelled in flight, then its answers arrive --------------------

for my $kind (qw( bound plain )) {
  for my $temp (qw( warm cold )) {
    my $label = "pooled, $kind, $temp pool";
    my ($storage, $conn) = $temp eq 'warm' ? fresh() : (pool_of_one());
    local $EV::MariaDB::HOLD = 1;
    my @q1 = on_wire($kind => 'q1');

    my $q1 = $SELECT{$kind}->($storage, 'q1');
    if ($temp eq 'cold') {
      ok spin_until(sub { ($conn = the_conn($storage)) && @{ $conn->{wire} } }),
        "$label: the connection came up and the statement was sent"
        or next;
    }
    is_deeply wire($conn), [ $q1[0] ], "$label: the statement is in flight";

    $q1->cancel;
    is state_of($q1), 'cancelled', "$label: the caller's Future is cancelled";
    is_deeply released($storage), [],
      "$label: the cancel releases nothing -- EV::MariaDB is still busy with the statement";
    is $storage->pool->available, 0, "$label: the connection is not idle while an answer is due";
    is $conn->pending_count, 1, "$label: EV::MariaDB still holds the statement's callback";

    for my $step (1 .. answers($kind) - 1) {
      deliver($conn);
      is_deeply wire($conn), [ @q1[0 .. $step] ],
        "$label: the transport goes on with what it began ($q1[$step])";
      is_deeply released($storage), [], "$label: and the connection stays checked out meanwhile";
    }

    deliver($conn);
    is_deeply wire($conn), \@q1,
      "$label: the last answer is followed by the close of the prepared statement (when there is one), at once";
    is_deeply released($storage), [ clean($conn) ],
      "$label: the last answer releases the connection, once, with nothing in flight and no statement open";
    is state_of($q1), 'cancelled', "$label: the Future stays cancelled";

    next_call_is_its_own($label, $storage, $conn);
    is_deeply wire($conn), [ @q1, on_wire(bound => 'next') ], "$label: nothing else went on the wire";
  }
}

# --- 2. pooled, pool of one: the next call is issued before the late answer -----

for my $kind (qw( bound plain )) {
  for my $order ('cancel, then the next call', 'the next call, then cancel') {
    my $label = "pool of one, $kind, $order";
    my ($storage, $conn) = fresh();
    local $EV::MariaDB::HOLD = 1;
    my @q1 = on_wire($kind => 'q1');
    my @q2 = on_wire(bound => 'q2');

    my $q1 = $SELECT{$kind}->($storage, 'q1');
    my $q2;
    if ($order =~ /^cancel/) {
      $q1->cancel;
      $q2 = $SELECT{bound}->($storage, 'q2');
    }
    else {
      $q2 = $SELECT{bound}->($storage, 'q2');
      $q1->cancel;
    }
    is state_of($q1), 'cancelled', "$label: the first call is cancelled";
    is_deeply wire($conn), [ $q1[0] ],
      "$label: the next call is not sent -- the connection is not handed out before the late answer";
    is_deeply released($storage), [], "$label: nothing is released yet";
    is state_of($q2), 'pending', "$label: the next call waits"
      or diag $q2->is_failed ? 'it failed: ' . $q2->failure : 'it is ' . state_of($q2);

    deliver($conn) for 1 .. answers($kind);   # every answer the cancelled statement is owed
    deliver($conn);                           # and the reset of the session (karr k100, core k398)
    is state_of($q2), 'pending', "$label: the late answer does not settle the next call";
    is_deeply wire($conn), [ @q1, $q2[0] ], "$label: the next call is sent now, on that connection";
    is_deeply released($storage), [ clean($conn) ],
      "$label: the late answer released the connection once, with nothing in flight";
    is $storage->pool->available, 0, "$label: it went straight to the waiting call, not to the idle list";

    deliver($conn) for 1 .. answers('bound');   # the next call's own answers
    is state_of($q2), 'done', "$label: the next call completes"
      or diag $q2->is_failed ? 'it failed: ' . $q2->failure : 'it did not settle';
    is_deeply [ $q2->is_done ? $q2->get : () ], [ [ 'row-of', 'q2' ] ], "$label: with its own rows";
    is state_of($q1), 'cancelled', "$label: the first call stays cancelled";
    is_deeply released($storage), [ clean($conn), clean($conn) ], "$label: one release for each call";

    next_call_is_its_own($label, $storage, $conn);
  }
}

# --- 3. pooled: the late answer is an error, or the connection is lost ----------

for my $kind (qw( bound plain )) {
  my $label = "late server error, $kind";
  my ($storage, $conn) = fresh();
  local $EV::MariaDB::HOLD = 1;
  local $EV::MariaDB::FAIL{q1} = q{Table 'fake.q1' doesn't exist};

  my @q1 = on_wire($kind => 'q1');
  my $q1 = $SELECT{$kind}->($storage, 'q1');
  $q1->cancel;
  is_deeply released($storage), [], "$label: the cancel releases nothing";
  is run_out($conn), answers($kind) + 1,   # + the reset of the session (karr k100, core k398)
    "$label: the statement is answered, with an error";
  is state_of($q1), 'cancelled', "$label: the Future stays cancelled, it does not fail";
  is_deeply released($storage), [ clean($conn) ],
    "$label: the connection is released once, with no statement left open";
  ok pooled($storage, $conn), "$label: and stays in the pool -- the session survived";

  next_call_is_its_own($label, $storage, $conn);
}

for my $kind (qw( bound plain )) {
  my $label = "connection lost, $kind";
  my ($storage, $conn) = fresh();
  local $EV::MariaDB::HOLD = 1;

  my $q1 = $SELECT{$kind}->($storage, 'q1');
  $q1->cancel;
  my $q2 = $SELECT{bound}->($storage, 'q2');
  is state_of($q2), 'pending', "$label: the next call waits for the connection"
    or diag $q2->is_failed ? 'it failed: ' . $q2->failure : 'it is ' . state_of($q2);

  $conn->t_end_session;
  deliver($conn);   # the operation in flight finds the session gone
  is state_of($q1), 'cancelled', "$label: the Future stays cancelled";
  is_deeply released($storage), [ clean($conn) ], "$label: the lost connection is handed back once";
  ok !pooled($storage, $conn), "$label: and retired, not idled";
  is $storage->pool->available, 0, "$label: nothing is idle";

  my $fresh;
  ok spin_until(sub { ($fresh = the_conn($storage)) && @{ $fresh->{wire} } }),
    "$label: the waiting call got a connection"
    or next;   # nothing to look at without one
  isnt $fresh->serial, $conn->serial, "$label: a newly opened one";
  is_deeply wire($conn), [ (on_wire($kind => 'q1'))[0] ], "$label: nothing more was sent on the lost one";
  is_deeply wire($fresh), [ 'prepare q2' ], "$label: the waiting call was sent on the new one";
  run_out($fresh);
  is_deeply [ $q2->is_done ? $q2->get : () ], [ [ 'row-of', 'q2' ] ],
    "$label: and completes with its own rows";
  is_deeply released($storage), [ clean($conn), clean($fresh) ], "$label: one release for each call";

  next_call_is_its_own($label, $storage, $fresh);
}

# --- 4. pooled insert_async: INSERT and LAST_INSERT_ID() on one connection ------

for my $stage ('prepare doomed', 'execute doomed', 'LII') {
  my $label = "pooled insert, cancelled with '$stage' in flight";
  my ($storage, $conn) = fresh();
  local $EV::MariaDB::HOLD = 1;

  my $insert = $storage->insert_async('doomed', { name => 'x' });
  for (1 .. 4) {
    last if $conn->{wire}[-1] eq $stage;
    deliver($conn);
  }
  is $conn->{wire}[-1], $stage, "$label: premise: that operation is in flight";

  $insert->cancel;
  is state_of($insert), 'cancelled', "$label: the caller's Future is cancelled";
  is_deeply released($storage), [], "$label: the cancel releases nothing";
  is $storage->pool->available, 0, "$label: the connection is not idle while an answer is due";

  run_out($conn);   # every answer the server still owes
  is state_of($insert), 'cancelled', "$label: the Future stays cancelled";
  is_deeply released($storage), [ clean($conn) ],
    "$label: the connection comes back once, after the last answer, with no statement left open";
  note "$label: the wire was @{[ join ', ', @{ wire($conn) } ]} -- what a cancelled insert "
    . 'still sends is not claimed here';

  {
    local $EV::MariaDB::HOLD = 0;
    my ($ok, $row) = wait_for($storage->insert_async(T36::Source->new('mine'), { name => 'n' }));
    ok $ok, "$label: the next insert completes" or diag "it failed: $row";
    is_deeply $ok ? $row : undef, { name => 'n', id => $EV::MariaDB::ROW_ID{mine} },
      "$label: with the id of its own row";
  }

  next_call_is_its_own($label, $storage, $conn);
}

# --- 5. pinned: a plain-query statement of a txn_do_async coderef, cancelled ----

# The transaction is at the point where its coderef has run and its statement
# is cancelled with @doomed -- what that statement has sent -- on the wire, the
# last of it in flight; $txn must now roll back behind it.
sub rolls_back_behind {
  my ($label, $storage, $conn, $txn, $stmt, $error, @doomed) = @_;

  is state_of($stmt), 'cancelled', "$label: the statement's Future is cancelled";
  my @wire = @{ wire($conn) };
  pop @wire if $wire[-1] eq 'ROLLBACK';
  is_deeply \@wire, [ 'BEGIN', @doomed ],
    "$label: nothing is sent ahead of the cancelled statement, and no COMMIT";
  is state_of($txn), 'pending', "$label: the transaction waits";
  is_deeply released($storage), [], "$label: the connection stays pinned";

  deliver($conn);   # the cancelled statement's answer
  is_deeply wire($conn), [ 'BEGIN', @doomed, 'ROLLBACK' ],
    "$label: ROLLBACK is on the wire behind the cancelled statement, not COMMIT";
  is state_of($txn), 'pending', "$label: the late answer does not end the transaction";
  is_deeply released($storage), [], "$label: still pinned while ROLLBACK is in flight";

  deliver($conn);   # ROLLBACK's
  is state_of($txn), 'failed', "$label: the transaction fails";
  if (ref $error) { like $txn->is_failed ? $txn->failure : '', $error, "$label: saying a statement was cancelled" }
  else            { is   $txn->is_failed ? $txn->failure : '', $error, "$label: with the error that cancelled it" }
  is state_of($stmt), 'cancelled', "$label: the statement stays cancelled";
  is_deeply released($storage), [ clean($conn) ],
    "$label: the connection comes back once, no transaction open, nothing in flight";
  is_deeply \@EV::MariaDB::COMMITTED, [], "$label: nothing was committed";

  next_call_is_its_own($label, $storage, $conn);
  is_deeply wire($conn), [ 'BEGIN', @doomed, 'ROLLBACK', on_wire(bound => 'next') ],
    "$label: nothing else went on the wire";
}

for my $when ('in the coderef', 'after the coderef returned', 'with its LAST_INSERT_ID() in flight') {
  my $label = "txn, cancelled $when";
  my ($storage, $conn) = fresh();
  local $EV::MariaDB::HOLD = 1;

  my $stmt;
  my $txn = $storage->txn_do_async(sub {
    my ($ctx) = @_;
    $stmt = $ctx->insert_async('doomed', {});
    $stmt->cancel if $when eq 'in the coderef';
    return 'gave up';
  });
  deliver($conn);   # BEGIN's answer: the coderef runs
  my @doomed = ('doomed');
  if ($when =~ /LAST_INSERT_ID/) {
    deliver($conn);   # the INSERT's answer: LAST_INSERT_ID() goes out
    push @doomed, 'LII';
  }
  $stmt->cancel if $when ne 'in the coderef';

  rolls_back_behind($label, $storage, $conn, $txn, $stmt, $CANCELLED, @doomed);
}

{
  my $label = 'txn, lost a wait_any';
  my ($storage, $conn) = fresh();
  local $EV::MariaDB::HOLD = 1;

  my ($stmt, $timeout);
  my $txn = $storage->txn_do_async(sub {
    my ($ctx) = @_;
    $stmt    = $ctx->insert_async('doomed', {});
    $timeout = $EVF->new;
    return $EVF->wait_any($stmt, $timeout);
  });
  deliver($conn);   # BEGIN's answer: the coderef runs
  $timeout->fail("timed out\n");

  rolls_back_behind($label, $storage, $conn, $txn, $stmt, "timed out\n", 'doomed');
}

# --- 6. pinned: the plain query behind the cancelled one ------------------------

{
  my $label = 'txn, a query behind the cancelled one';
  my ($storage, $conn) = fresh();
  local $EV::MariaDB::HOLD = 1;

  my ($doomed, $behind);
  my $txn = $storage->txn_do_async(sub {
    my ($ctx) = @_;
    $doomed = $ctx->insert_async('doomed', {});
    $behind = $SELECT{plain}->($ctx, 'behind');
    return $behind;
  });
  deliver($conn);   # BEGIN's answer: the coderef runs
  # The coderef runs outside the BEGIN's callback (karr k51): the first query
  # is sent at once, the one behind it waits in EV::MariaDB's queue until the
  # first answer has been read (it used to be sent in the same batch, queued
  # while the BEGIN's callback ran).
  is_deeply wire($conn), [qw( BEGIN doomed )], "$label: EV::MariaDB sent the first, the second waits behind it";

  $doomed->cancel;
  is_deeply wire($conn), [qw( BEGIN doomed )], "$label: the cancel sends nothing";

  deliver($conn);   # the cancelled statement's answer
  is_deeply wire($conn), [qw( BEGIN doomed behind )], "$label: the second is sent once the first answer was read";
  is state_of($behind), 'pending', "$label: the late answer does not settle the query behind it";
  ok !grep({ /^(?:ROLLBACK|COMMIT)\z/ } @{ wire($conn) }), "$label: nor end the transaction";

  deliver($conn);   # the second query's own answer
  is state_of($behind), 'done', "$label: the query behind completes";
  is_deeply [ $behind->is_done ? $behind->get : () ], [ [ 'row-of', 'behind' ] ],
    "$label: with its own rows";
  is $conn->{wire}[-1], 'ROLLBACK', "$label: then ROLLBACK -- a statement of the transaction was cancelled";
  ok !grep({ $_ eq 'COMMIT' } @{ wire($conn) }), "$label: COMMIT was never sent";
  is_deeply released($storage), [], "$label: the connection stays pinned";

  deliver($conn);   # ROLLBACK's
  is state_of($txn), 'failed', "$label: the transaction fails";
  like $txn->is_failed ? $txn->failure : '', $CANCELLED, "$label: saying a statement was cancelled";
  is_deeply released($storage), [ clean($conn) ],
    "$label: the connection comes back once, no transaction open, nothing in flight";
  is_deeply \@EV::MariaDB::COMMITTED, [], "$label: nothing was committed";

  next_call_is_its_own($label, $storage, $conn);
}

# --- 7. pinned: cancelled while EV::MariaDB has only queued it ------------------

{
  my $label = 'txn, cancelled while queued';
  my ($storage, $conn) = fresh();

  my ($first, $queued, $unsent);
  my ($ok, $err) = wait_for($storage->txn_do_async(sub {
    my ($ctx) = @_;
    $first  = $ctx->insert_async('first', {});
    $queued = $SELECT{plain}->($ctx, 'queued');
    $unsent = !grep { $_ eq 'queued' } @{ $conn->{wire} };
    $queued->cancel;
    return $first;
  }));
  settle();
  ok $unsent, "$label: premise: the statement was not sent when it was cancelled";
  ok !$ok, "$label: the transaction fails";
  like $ok ? '' : "$err", $CANCELLED, "$label: saying a statement was cancelled";
  is state_of($first), 'done', "$label: the other statement completed";
  is state_of($queued), 'cancelled', "$label: the cancelled one stays cancelled";
  my @wire = @{ wire($conn) };
  is_deeply [ @wire[0, 1] ], [qw( BEGIN first )], "$label: the other statement ran";
  is $wire[-1], 'ROLLBACK', "$label: ROLLBACK ended the transaction";
  ok !grep({ $_ eq 'COMMIT' } @wire), "$label: COMMIT was never sent";
  note "$label: the wire was @{[ join ', ', @wire ]} -- whether a statement cancelled in "
    . "EV::MariaDB's queue is still sent is not claimed here";
  is_deeply released($storage), [ clean($conn) ],
    "$label: the connection comes back once, no transaction open, nothing in flight";
  is_deeply \@EV::MariaDB::COMMITTED, [], "$label: nothing was committed";

  next_call_is_its_own($label, $storage, $conn);
}

# --- 9. the cancelled / abandoned statement has bind values (karr k74) ----------
#
# A claim of this section, kept from the time it was a TODO: the pool is never
# left holding the connection with the transaction open, and nothing of the
# transaction is committed later. Kept as it was (the assertions are not
# weakened); what the fix adds are the wire assertions: the ROLLBACK does go
# out, and only behind the statement in flight -- the fix is a
# ROLLBACK that waits, not one that is dropped.
# Variants: cancelled in the coderef / after it returned, and (not a cancel)
# the coderef dies with the statement just issued.

for my $when ('in the coderef', 'after the coderef returned', 'the coderef dies') {
  my $label = "txn, a statement with bind values: $when";
  my ($storage, $conn) = fresh();
  local $EV::MariaDB::HOLD = 1;

  my $stmt;
  my $txn = $storage->txn_do_async(sub {
    my ($ctx) = @_;
    $stmt = $ctx->insert_async('doomed', { name => 'x' });
    $stmt->cancel if $when eq 'in the coderef';
    die "coderef gave up\n" if $when eq 'the coderef dies';
    return 'gave up';
  });
  deliver($conn);   # BEGIN's answer: the coderef runs
  $stmt->cancel if $when eq 'after the coderef returned';
  is state_of($stmt), $when eq 'the coderef dies' ? 'pending' : 'cancelled',
    "$label: the statement's Future is " . ($when eq 'the coderef dies' ? 'pending' : 'cancelled');
  is_deeply wire($conn), [ 'BEGIN', 'prepare doomed' ],
    "$label: premise: its prepare is in flight, and nothing was sent behind it";

  run_out($conn);   # every answer the server still owes
  is state_of($txn), 'failed', "$label: the transaction fails";
  like $txn->is_failed ? $txn->failure : '',
    $when eq 'the coderef dies' ? qr/coderef gave up/ : $CANCELLED,
    "$label: saying what made it fail";
  unlike $txn->is_failed ? $txn->failure : '', qr/Rollback failed/, "$label: and not that its ROLLBACK failed";
  ok !grep({ $_ eq 'COMMIT' } @{ wire($conn) }), "$label: COMMIT was never sent";
  # The insert of a coderef that died still reads its LAST_INSERT_ID(), inside
  # the transaction and ahead of the ROLLBACK; a cancelled one does not.
  is_deeply [ grep { /^(?:close doomed|LII|ROLLBACK)\z/ } @{ wire($conn) } ],
    [ 'close doomed', ($when eq 'the coderef dies' ? 'LII' : ()), 'ROLLBACK' ],
    "$label: ROLLBACK went out, behind the statement in flight (its close goes out first)";
  cmp_ok scalar @{ released($storage) }, '<=', 1, "$label: the connection is not handed back twice";

  ok !pooled($storage, $conn) || !$conn->{intrans},
    "$label: the pool is not left holding the connection with the transaction open";
  is $conn->{intrans}, 0, "$label: the server has no transaction open on it";

  # The next transaction on the pool: its BEGIN commits what is still open on
  # the connection it gets.
  {
    local $EV::MariaDB::HOLD = 0;
    my ($ok, @r) = wait_for($storage->txn_do_async(sub { 'next' }));
    ok $ok, "$label: the next transaction completes" or diag "it failed: $r[0]";
    settle();
  }
  is_deeply \@EV::MariaDB::COMMITTED, [],
    "$label: and commits nothing of the transaction that failed";
}

# --- 10. the coderef returned the cancelled Future ------------------------------

{
  my $label = 'txn, the coderef returned the cancelled Future';
  my ($storage, $conn) = fresh();
  local $EV::MariaDB::HOLD = 1;

  my $stmt;
  my $txn = $storage->txn_do_async(sub {
    my ($ctx) = @_;
    return $stmt = $ctx->insert_async('doomed', {});
  });
  deliver($conn);   # BEGIN's answer: the coderef runs
  $stmt->cancel;
  is state_of($stmt), 'cancelled', "$label: the statement's Future is cancelled";
  is_deeply wire($conn), [qw( BEGIN doomed )],
    "$label: nothing is sent while the cancelled statement is in flight";

  # The wire answers everything it still owes: the cancelled statement, and
  # whatever ends the transaction, if anything does.
  run_out($conn);
  cmp_ok scalar @{ released($storage) }, '<=', 1, "$label: the connection is not handed back twice";
  is_deeply \@EV::MariaDB::COMMITTED, [], "$label: nothing was committed";

  my $pooled = pooled($storage, $conn);
  isnt state_of($txn), 'pending', "$label: the transaction settles once the wire has answered";
  ok !$pooled || $storage->pool->available == 1,
    "$label: its connection is handed back or retired, not left checked out";
  ok !$pooled || !$conn->{intrans},
    "$label: and the pool is not left holding it with the transaction open";
  nothing_warned($label);
}

# --- 11. a ROLLBACK that fails retires the connection (karr k74) ----------------
#
# The claim: a connection whose ROLLBACK did not succeed may still hold the
# transaction, so it never goes back to the pool -- whether the ROLLBACK went
# out at once (the coderef died, nothing in flight) or waited behind a
# statement with bind values. The next call gets a newly opened connection.

for my $in_flight (0, 1) {
  my $label = 'txn, ROLLBACK fails, ' . ($in_flight ? 'behind a statement in flight' : 'nothing in flight');
  my ($storage, $conn) = fresh();
  local $EV::MariaDB::HOLD = 1;
  local $EV::MariaDB::FAIL{ROLLBACK} = 'ROLLBACK refused by the server';

  my $stmt;   # kept: a dropped statement Future is a "lost sequence Future" warning
  my $txn = $storage->txn_do_async(sub {
    my ($ctx) = @_;
    $stmt = $ctx->insert_async('doomed', { name => 'x' }) if $in_flight;
    die "coderef gave up\n";
  });
  deliver($conn);   # BEGIN's answer: the coderef runs
  run_out($conn);
  is state_of($txn), 'failed', "$label: the transaction fails";
  like $txn->is_failed ? $txn->failure : '', qr/coderef gave up.*Rollback failed.*ROLLBACK refused/s,
    "$label: with its cause and the failed ROLLBACK";
  ok scalar(grep { $_ eq 'ROLLBACK' } @{ wire($conn) }), "$label: premise: the ROLLBACK was sent";
  ok !pooled($storage, $conn), "$label: the connection is retired, not handed back to the pool";
  is $storage->pool->available, 0, "$label: nothing idle in the pool";

  {
    local $EV::MariaDB::HOLD = 0;
    local $EV::MariaDB::FAIL{ROLLBACK};
    my ($ok, @r) = wait_for($SELECT{bound}->($storage, 'next'));
    ok $ok, "$label: the next call completes" or diag "it failed: $r[0]";
    settle();
    my $fresh_conn = the_conn($storage);
    isnt $fresh_conn && $fresh_conn->serial, $conn->serial, "$label: on a newly opened connection";
  }
  nothing_warned($label);
}

# --- 12. statements that wait for an idle connection: the queue never stalls ----
#
# The claim (karr k74): QueryExecutor::execute_when_idle keeps one order per
# connection, and a waiting statement that sends nothing when its turn comes --
# its Future was cancelled while it waited -- does not strand the ones behind
# it. Nothing is in flight after such an entry, so no settling would ever start
# the next one: the queue has to go on by itself, until an entry is in flight
# or none is left.

for my $skipped (1, 2) {
  my $label = "waiting behind a statement in flight, the first $skipped cancelled before their turn";
  my ($storage, $conn) = fresh();
  local $EV::MariaDB::HOLD = 1;
  my $executor = $storage->_executor;

  my $busy    = $executor->execute($conn, 'SELECT tag FROM busy WHERE tag = ?', [ 1 ]);
  my @dropped = map { $executor->execute_when_idle($conn, "SELECT tag FROM dropped$_", []) } 1 .. $skipped;
  my $second  = $executor->execute_when_idle($conn, 'SELECT tag FROM second', []);
  my $third   = $executor->execute_when_idle($conn, 'SELECT tag FROM third', []);
  is_deeply wire($conn), [ 'prepare busy' ],
    "$label: premise: only the statement in flight is on the wire, the others wait";
  $_->cancel for @dropped;

  run_out($conn);
  is state_of($busy), 'done', "$label: the statement in flight is answered";
  is state_of($second), 'done', "$label: the statement behind the cancelled ones goes out and is answered";
  is_deeply [ $second->is_done ? $second->get : () ], [ [ 'row-of', 'second' ] ], "$label: with its own rows";
  is state_of($third), 'done', "$label: and so is the one behind it";
  is_deeply wire($conn), [ on_wire(bound => 'busy'), 'second', 'third' ],
    "$label: in the order they were queued, each after the one before it; a cancelled one is never sent";
  is $conn->pending_count, 0, "$label: nothing is left in flight";
  nothing_warned($label);
}

# --- 12b. a waiting statement whose dispatch croaks, or whose handle is finished -
#
# The claim (karr k81, k74): a statement that waits behind one in flight and
# croaks when its turn comes -- a prepare or a query EV::MariaDB refuses, or a
# handle that was finished meanwhile -- is reported as the failure of ITS
# Future, with the croak's text, instead of dying inside the callback that
# settled the statement before it (where it would be warned and the Future
# would hang); it is never sent, and it does not hold up the ones behind it.

for my $kind (qw( bound plain )) {
  my $label = "waiting behind a statement in flight, its dispatch croaks ($kind)";
  my ($storage, $conn) = fresh();
  local $EV::MariaDB::HOLD = 1;
  local $EV::MariaDB::CROAK{boom} = 'refused: boom';
  my $executor = $storage->_executor;

  my $busy   = $executor->execute($conn, 'SELECT tag FROM busy WHERE tag = ?', [ 1 ]);
  my $boom   = $executor->execute_when_idle($conn, 'SELECT tag FROM boom', $kind eq 'bound' ? [ 1 ] : []);
  my $second = $executor->execute_when_idle($conn, 'SELECT tag FROM second', []);
  is state_of($boom), 'pending', "$label: premise: it waits";

  run_out($conn);
  is state_of($boom), 'failed', "$label: its Future fails, it does not hang";
  like $boom->is_failed ? $boom->failure : '', qr/refused: boom/, "$label: with the croak's text";
  is state_of($busy), 'done', "$label: the statement in flight is answered";
  is state_of($second), 'done', "$label: the statement behind the one that croaked goes out and is answered";
  is_deeply wire($conn), [ on_wire(bound => 'busy'), 'second' ],
    "$label: the one that croaked was never sent";
  is $conn->pending_count, 0, "$label: nothing is left in flight";
  nothing_warned($label);
}

{
  my $label = "waiting behind a statement in flight, its handle is finished meanwhile";
  my ($storage, $conn) = fresh();
  local $EV::MariaDB::HOLD = 1;
  my $executor = $storage->_executor;

  my $busy   = $executor->execute($conn, 'SELECT tag FROM busy WHERE tag = ?', [ 1 ]);
  my $first  = $executor->execute_when_idle($conn, 'SELECT tag FROM first', []);
  my $second = $executor->execute_when_idle($conn, 'SELECT tag FROM second', [ 1 ]);
  $conn->finish;   # the handle is gone; the answer already due still comes in the fake

  run_out($conn);
  is state_of($first), 'failed', "$label: the first waiting Future fails, it does not hang";
  like $first->is_failed ? $first->failure : '', qr/not connected/, "$label: saying the handle is not connected";
  is state_of($second), 'failed', "$label: and so does the next -- the queue goes on to it";
  is_deeply wire($conn), [ 'prepare busy' ], "$label: nothing was sent behind the statement in flight";
  nothing_warned($label);
}

# --- 13. a COMMIT that fails retires the connection (karr k74) ------------------
#
# The claim, the same invariant as 11: a connection that may still hold a
# transaction never goes back to the pool. Whether a COMMIT that did not
# succeed left the transaction open nobody knows -- so its connection is
# retired, and the next call gets a newly opened one. Two ways to fail: the
# server answers the COMMIT with an error, or EV::MariaDB refuses to take it
# (an operation of a statement sent past the transaction's context is in
# flight -- core waits only for the statements the context handed out).
# COMMIT is NOT queued behind anything: core has waited for the context's
# statements before it sends it.

for my $how ('the server fails it', 'EV::MariaDB refuses it') {
  my $label = "txn, COMMIT fails: $how";
  my ($storage, $conn) = fresh();
  local $EV::MariaDB::HOLD = 1;
  local $EV::MariaDB::FAIL{COMMIT} = $how eq 'the server fails it' ? 'COMMIT refused by the server' : undef;

  my $txn = $storage->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->insert_async('kept', { name => 'x' })->then(sub {
      # Past the context, straight on the handle: nothing waits for it.
      $ctx->txn_conn->prepare('SELECT tag FROM stray WHERE tag = ?', sub { })
        if $how eq 'EV::MariaDB refuses it';
      return 'fine';
    });
  });
  deliver($conn);   # BEGIN's answer: the coderef runs
  # Every answer up to the one that ends the transaction; what is in flight
  # then stays in flight.
  my $n = 0;
  deliver($conn) while !$txn->is_ready && $conn->t_in_flight && ++$n <= 20;

  is state_of($txn), 'failed', "$label: the transaction fails";
  like $txn->is_failed ? $txn->failure : '',
    $how eq 'the server fails it' ? qr/COMMIT failed: COMMIT refused by the server/ : qr/cannot queue query/,
    "$label: saying so";
  is_deeply \@EV::MariaDB::COMMITTED, [], "$label: premise: nothing was committed";
  ok !pooled($storage, $conn), "$label: the connection is retired, not handed back to the pool";
  is $storage->pool->available, 0, "$label: nothing idle in the pool";

  {
    local $EV::MariaDB::HOLD = 0;
    local $EV::MariaDB::FAIL{COMMIT};
    my ($ok, @r) = wait_for($storage->txn_do_async(sub { 'next' }));
    ok $ok, "$label: the next transaction completes" or diag "it failed: $r[0]";
    settle();
    my $fresh_conn = the_conn($storage);
    isnt $fresh_conn && $fresh_conn->serial, $conn->serial, "$label: on a newly opened connection";
  }
  is_deeply \@EV::MariaDB::COMMITTED, [],
    "$label: and its BEGIN commits nothing of the transaction whose COMMIT failed";
  nothing_warned($label);
}

# --- 14. every statement of a pinned connection waits behind a prepare/execute --
#
# The claim (karr k81, maintainer 2026-10-25): EV::MariaDB refuses a query
# while a prepare or an execute is in flight, so not only the ROLLBACK
# (section 9) but every statement issued on a pinned connection behind a
# statement with bind values waits until that statement has settled -- in the
# order issued -- instead of running into the refusal. Behind plain queries
# nothing waits: EV::MariaDB pipelines them (section 6).

{
  my $label = 'txn, statements issued behind a statement with bind values';
  my ($storage, $conn) = fresh();
  local $EV::MariaDB::HOLD = 1;

  my @f;
  my $txn = $storage->txn_do_async(sub {
    my ($ctx) = @_;
    push @f, $SELECT{bound}->($ctx, 'a'), $SELECT{plain}->($ctx, 'b'), $SELECT{bound}->($ctx, 'c');
    return $EVF->needs_all(@f);
  });
  deliver($conn);   # BEGIN's answer: the coderef runs
  is_deeply wire($conn), [ 'BEGIN', 'prepare a' ],
    "$label: premise: only the statement in flight is on the wire, the others wait";
  is_deeply [ map { state_of($_) } @f ], [qw( pending pending pending )],
    "$label: none of them failed on EV::MariaDB's refusal";

  run_out($conn);
  is_deeply [ map { state_of($_) } @f ], [qw( done done done )], "$label: all complete";
  is_deeply [ map { [ $_->get ] } @f ],
    [ [ [ 'row-of', 'a' ] ], [ [ 'row-of', 'b' ] ], [ [ 'row-of', 'c' ] ] ], "$label: each with its own rows";
  is_deeply wire($conn),
    [ 'BEGIN', on_wire(bound => 'a'), 'b', on_wire(bound => 'c'), 'COMMIT' ],
    "$label: in the order issued, each behind the one before it, then COMMIT";
  is state_of($txn), 'done', "$label: the transaction commits";
  nothing_warned($label);
}

{
  my $label = 'txn, plain queries behind a plain query go one behind the other';
  my ($storage, $conn) = fresh();
  local $EV::MariaDB::HOLD = 1;

  my @f;
  my $txn = $storage->txn_do_async(sub {
    my ($ctx) = @_;
    push @f, $SELECT{plain}->($ctx, 'p1'), $SELECT{plain}->($ctx, 'p2');
    return $EVF->needs_all(@f);
  });
  deliver($conn);
  # Not in one batch since karr k51: the coderef runs outside the BEGIN's
  # callback, so p1 is sent at once and p2 waits in EV::MariaDB's queue for
  # p1's result (EV::MariaDB 0.08 pipelines only what it has taken before it
  # sends).
  is_deeply wire($conn), [qw( BEGIN p1 )], "$label: p1 is on the wire, p2 behind it";
  deliver($conn);
  is_deeply wire($conn), [qw( BEGIN p1 p2 )], "$label: p2 follows once p1's answer was read";
  run_out($conn);
  is state_of($txn), 'done', "$label: and the transaction completes";
  nothing_warned($label);
}

# --- 15. the ROLLBACK's wait has a limit (karr k81) -----------------------------
#
# The claim: a statement in flight whose answer never comes must not keep the
# transaction's ROLLBACK, and with it the connection, waiting for ever. After
# rollback_wait_timeout seconds the ROLLBACK is not sent, the connection is
# retired and the transaction's Future fails with a reason. An answer that
# comes in time is not affected.

{
  my $label = 'txn, the statement in flight never answers';
  my ($storage, $conn) = fresh();
  is $storage->rollback_wait_timeout, 30, "$label: the default is 30 seconds";
  $storage->rollback_wait_timeout(0.1);
  local $EV::MariaDB::HOLD = 1;

  my $stmt;
  my $txn = $storage->txn_do_async(sub {
    my ($ctx) = @_;
    $stmt = $SELECT{bound}->($ctx, 'stuck');
    die "coderef gave up\n";
  });
  deliver($conn);   # BEGIN's answer: the coderef runs
  is_deeply wire($conn), [ 'BEGIN', 'prepare stuck' ], "$label: premise: the prepare is in flight";

  my ($ok, $err) = wait_for($txn);   # no answer is ever delivered
  ok !$ok, "$label: the transaction fails after the limit, it does not hang";
  like "$err", qr/coderef gave up/, "$label: with its cause";
  like "$err", qr/did not answer within 0\.1s/, "$label: and the reason of the wait";
  ok !grep({ $_ eq 'ROLLBACK' } @{ wire($conn) }), "$label: the ROLLBACK was not sent";
  ok !pooled($storage, $conn), "$label: the connection is retired";

  # The statement answers late: nothing more happens on the wire.
  run_out($conn);
  ok !grep({ $_ eq 'ROLLBACK' } @{ wire($conn) }), "$label: a late answer does not send the ROLLBACK";
  nothing_warned($label);
}

{
  my $label = 'txn, the statement in flight answers within the limit';
  my ($storage, $conn) = fresh();
  $storage->rollback_wait_timeout(0.2);
  local $EV::MariaDB::HOLD = 1;

  my $stmt;
  my $txn = $storage->txn_do_async(sub {
    my ($ctx) = @_;
    $stmt = $SELECT{bound}->($ctx, 'slow');
    die "coderef gave up\n";
  });
  deliver($conn);
  run_out($conn);
  is $conn->{wire}[-1], 'ROLLBACK', "$label: the ROLLBACK went out behind it";
  {
    local $EV::MariaDB::HOLD = 0;
    EV::MariaDB->t_resume;
    my ($ok, $err) = wait_for($txn);
    like "$err", qr/\Acoderef gave up/, "$label: the transaction fails with its own error only";
    unlike "$err", qr/did not answer/, "$label: not with the wait";
    settle();
    my $t = 0;
    my $w = EV::timer(0.3, 0, sub { $t = 1 });
    EV::run(EV::RUN_ONCE()) until $t;   # the limit passes
  }
  ok pooled($storage, $conn), "$label: the connection went back to the pool";
  nothing_warned($label);
}

{
  my $label = 'executor, a timeout fails the Future with a DBIO::Exception';
  my ($storage, $conn) = fresh();
  local $EV::MariaDB::HOLD = 1;
  my $executor = $storage->_executor;

  my $busy = $executor->execute($conn, 'SELECT tag FROM busy WHERE tag = ?', [ 1 ]);
  my $wait = $executor->execute_when_idle($conn, 'ROLLBACK', [], 0.05);
  my ($ok, $err) = wait_for($wait);
  ok !$ok, "$label: it fails";
  isa_ok $err, 'DBIO::Exception', "$label: the error";
  like "$err", qr/did not answer within 0\.05s/, "$label: naming the wait";
  run_out($conn);
  is_deeply wire($conn), [ on_wire(bound => 'busy') ], "$label: the statement was never sent";
  is state_of($busy), 'done', "$label: the statement in flight is unaffected";
  nothing_warned($label);
}

done_testing;
