use strict;
use warnings;
use Test::More;

# OFFLINE test for the future_io POOL connections (karr k79): how they are
# opened, and what happens to one whose server session is gone.
#
# WHY: a prefork app forks one child per request. The pool connections were opened
# without AutoInactiveDestroy, so a child that simply exited destroyed its
# inherited copies and sent PostgreSQL the terminate message for the PARENT's
# pooled sessions. And the pool cannot see a connection die once it has come
# up (core k230): the dead handle went back to the idle list and was handed
# out again, so with a pool of one every later call failed with "no connection
# to the server", for good.
#
# What this file claims:
#   1. every connection this transport opens -- pooled or listening -- asks
#      DBI->connect for AutoInactiveDestroy => 1, and a caller's connect
#      attributes cannot switch it off;
#   2. a statement whose connection is LOST -- at execute, at pg_ready, at
#      pg_result, or on a handle that died while idle and got past the
#      borrow-time check (karr k90, held at its default here) -- fails its
#      caller, and
#      the connection is retired instead of reissued: the next call runs on a
#      freshly spawned connection;
#   3. a statement error the session SURVIVES -- a syntax error, a client-side
#      bind error -- fails its caller and nothing more: the next call runs on
#      the SAME connection;
#   4. both hold for a transaction's pinned connection, which core hands back
#      through the pool's release.
#
# "Lost" is libpq's own verdict, not the error text: libpq drops the socket
# when it concludes the server connection is gone, and DBD::Pg then answers
# pg_socket -1 -- while $dbh->{Active} stays 1 (both measured live on
# PostgreSQL 18.6 / DBD::Pg 3.20.2 for karr k79; t/65-future-io-pool-live.t
# drives the same claims end to end against a real server). The fake
# below does exactly that, and its error texts are deliberately the same for
# a lost connection and a surviving one where it matters, so only the socket
# can tell them apart.
#
# WHAT RUNS FOR REAL: the real pool (DBIO::Async::Pool on core's PoolBase),
# the real Model-B orchestration (select_async, txn_do_async), and this dist's
# shipped _create_pool_connection / _submit_query / _collect_result /
# _conn_error_is_fatal, asked by dbio-async's query path (karr k92).
# THE SUBSTITUTIONS: DBI->connect hands out fake DBD::Pg handles, and
# _await_readable resolves at once (there is no socket to poll), as in t/61,
# and the borrow-time check _idle_connection_alive answers its default (t/75).

BEGIN {
  eval { require DBIO::PostgreSQL::Storage::Async; 1 }
    or plan skip_all =>
      'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
  plan skip_all => 'the installed DBIO core predates PoolBase::_mark_connection_dead (core k230)'
    unless DBIO::Storage::PoolBase->can('_mark_connection_dead');
  plan skip_all => 'the installed dbio-async predates the _conn_error_is_fatal seam (dbio-async k26)'
    unless DBIO::Async::Storage->can('_conn_error_is_fatal');
}

use Future;

# --- the fake DBD::Pg -----------------------------------------------------------

our (@CONNECTS, @OUTCOMES);
my $next_pid = 7000;

# The same server error text for "lost" and "survived" in the pg_result case:
# the classification must not read it.
my $FATAL = "DBD::Pg::db pg_result failed: FATAL:  terminating connection due to "
          . "administrator command\nserver closed the connection unexpectedly\n";

{
  package FakePool::DBH;

  sub new {
    my ($class, %args) = @_;
    return bless {
      %args,
      Active    => 1,
      pg_socket => 42,
      pg_pid    => ++$next_pid,
      outcome   => 'ok',
    }, $class;
  }

  sub prepare {
    my ($self, $sql, $attrs) = @_;
    return bless { dbh => $self, sql => $sql, NUM_OF_FIELDS => 1 }, 'FakePool::STH';
  }

  # libpq concluded the connection is gone: it drops the socket. DBD::Pg
  # leaves Active alone.
  sub lose { $_[0]{pg_socket} = -1; return }

  sub pg_ready {
    my ($self) = @_;
    if ($self->{outcome} eq 'lost_at_ready') {
      $self->lose;
      die "DBD::Pg::db pg_ready failed: server closed the connection unexpectedly\n";
    }
    return 1;
  }

  sub pg_result {
    my ($self) = @_;
    my $outcome = $self->{outcome};
    if ($outcome eq 'lost') {
      $self->lose;
      die $FATAL;
    }
    die $FATAL if $outcome eq 'fatal_but_alive';
    die qq{DBD::Pg::db pg_result failed: ERROR:  syntax error at or near "SELEC"\n}
      if $outcome eq 'error';
    return 1;
  }

  # SQLSTATE, read after pg_result (karr k83): none -- every scripted failure
  # above dies instead.
  sub state { q{} }

  sub disconnect {
    my ($self) = @_;
    $self->{Active} = 0;
    $self->{disconnected}++;
    return 1;
  }
}

{
  package FakePool::STH;

  # Each statement that reaches a live connection takes the next scripted
  # outcome ('ok' when none is left). A handle whose socket is gone refuses
  # at once, as DBD::Pg does.
  sub execute {
    my ($self, @bind) = @_;
    my $dbh = $self->{dbh};
    die "DBD::Pg::st execute failed: no connection to the server\n"
      if $dbh->{pg_socket} < 0;
    my $outcome = shift(@main::OUTCOMES) // 'ok';
    die "DBD::Pg::st execute failed: called with 2 bind variables when 1 are needed\n"
      if $outcome eq 'exec_error';
    if ($outcome eq 'exec_lost') {
      $dbh->lose;
      die "DBD::Pg::st execute failed: server closed the connection unexpectedly\n";
    }
    $dbh->{outcome} = $outcome;
    return 1;
  }

  # Every row names the "backend" it ran on, like pg_backend_pid().
  sub fetchall_arrayref { return [ [ $_[0]{dbh}{pg_pid} ] ] }
}

{
  no warnings 'redefine';
  *DBI::connect = sub {
    my ($class, $dsn, $user, $password, $attrs) = @_;
    my $dbh = FakePool::DBH->new;
    push @CONNECTS, { dsn => $dsn, user => $user, attrs => { %$attrs }, dbh => $dbh };
    return $dbh;
  };
}

{
  package FakePool::Transport;
  use base 'DBIO::PostgreSQL::Storage::Async';

  # A transport substitution: no socket to poll, the "result" is there.
  sub _await_readable { return Future->done }

  # The borrow-time check _idle_connection_alive (karr k90) is held at the
  # seam's default here: this file pins the statement path, the net that still
  # catches a death the check cannot see -- one after the check, or one the
  # server never announced on the socket. The fake's pg_socket is no real fd
  # to select on; t/75 pins the check itself, over real sockets.
  sub _idle_connection_alive { 1 }
}

# --- helpers --------------------------------------------------------------------

sub fresh {
  my $s = FakePool::Transport->new(undef);
  $s->connect_info([ 'dbi:Pg:dbname=pool_test', 'u', 'p', { pool_size => 1, pg_enable_utf8 => 1 } ]);
  @CONNECTS = ();
  @OUTCOMES = ();
  return $s;
}

# Run one pooled query with the scripted outcomes. Returns the "backend pid"
# it ran on, or (undef, $error).
sub call {
  my ($s, @outcomes) = @_;
  push @OUTCOMES, @outcomes;
  my $f = $s->select_async('t', ['x'], {});
  die 'the fake transport is synchronous; the query should be ready' unless $f->is_ready;
  return $f->is_done ? ($f->get)[0][0] : (undef, scalar $f->failure);
}

sub pool_state {
  my ($s) = @_;
  return [ $s->pool->size, $s->pool->available ];
}

# ---------------------------------------------------------------------------
# 1. Connect attributes. What is pinned is what the transport asks the DBD
#    for: DBI->connect is replaced for the whole file.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  ok defined call($s), 'a pooled query ran';
  is scalar(@CONNECTS), 1, '... on one freshly opened pool connection';
  my $attrs = $CONNECTS[0]{attrs};
  is $attrs->{AutoInactiveDestroy}, 1,
    'the pool connection is opened with AutoInactiveDestroy => 1: a forked child '
    . 'that drops its copy leaves the parent\'s session alone';
  is $attrs->{AutoCommit}, 1, '... AutoCommit => 1 (transactions are explicit BEGIN/COMMIT)';
  is $attrs->{RaiseError}, 1, '... RaiseError => 1';
  is $attrs->{PrintError}, 0, '... PrintError => 0';
  is $attrs->{pg_enable_utf8}, 1, '... the caller\'s DBD attributes pass through';
  ok !exists $attrs->{pool_size}, '... pool_size is not a DBD attribute and is not passed';

  @CONNECTS = ();
  $s->_create_pool_connection({ dsn => 'dbi:Pg:dbname=pool_test', attrs => { AutoInactiveDestroy => 0 } });
  is $CONNECTS[0]{attrs}{AutoInactiveDestroy}, 1,
    'a caller\'s AutoInactiveDestroy => 0 does not switch fork safety off';

  @CONNECTS = ();
  $s->_listen_open->get;
  is $CONNECTS[0]{attrs}{AutoInactiveDestroy}, 1,
    'the listen connection is opened fork-safe too -- the same connect shape';
}

# ---------------------------------------------------------------------------
# 2. A lost connection is retired, not reissued. A pool of one makes that
#    sharp: a dead handle that went back to the idle list would be the ONLY
#    connection the next call could get.
# ---------------------------------------------------------------------------

for my $case (
  [ 'lost at pg_result',     'lost',          qr/server closed the connection/ ],
  [ 'lost at execute',       'exec_lost',     qr/server closed the connection/ ],
  [ 'lost at pg_ready',      'lost_at_ready', qr/server closed the connection/ ],
) {
  my ($label, $outcome, $error_re) = @$case;
  my $s = fresh();
  my ($pid) = call($s);
  ok defined $pid, "$label: the pooled connection is up";
  my $dbh = $CONNECTS[0]{dbh};

  my ($got, $err) = call($s, $outcome);
  ok !defined $got, "$label: the call fails";
  like $err, $error_re, "$label: with DBD::Pg's error";
  is_deeply pool_state($s), [ 0, 0 ],
    "$label: the connection was retired on its way back -- the pool holds nothing";
  ok $dbh->{disconnected}, "$label: ... and closed";

  my ($next, $next_err) = call($s);
  ok defined $next, "$label: the next call completes" or diag $next_err;
  ok defined $next && $next != $pid, "$label: ... on a freshly spawned connection";
  is scalar(@CONNECTS), 2, "$label: ... opened for it";
  is_deeply pool_state($s), [ 1, 1 ], "$label: the pool has its one connection again";
}

# ---------------------------------------------------------------------------
# 3. A handle whose backend died while it sat idle, and which got past the
#    borrow-time check (karr k90; held at its default in this file -- a death
#    after the check, or one the server never announced). The first call
#    after it discovers the death -- and fails -- but the call after that
#    must not get the same handle again.
#    This is the prefork-app case: before the fix, a pool of one failed "no
#    connection to the server" for every call from here on.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  my ($pid) = call($s);
  my $dbh = $CONNECTS[0]{dbh};
  $dbh->lose;                             # pg_terminate_backend, a restart ...

  my ($got, $err) = call($s);
  ok !defined $got, 'died while idle: the first call after it fails';
  like $err, qr/no connection to the server/, '... on the dead handle';
  is_deeply pool_state($s), [ 0, 0 ], '... which is retired, not put back';

  my ($next, $next_err) = call($s);
  ok defined $next, 'died while idle: the call after it completes' or diag $next_err;
  ok defined $next && $next != $pid, '... on a freshly spawned connection';
}

# ---------------------------------------------------------------------------
# 4. A statement error the session survives keeps the connection. The first
#    case uses the SAME error text as a lost connection: what decides is the
#    connection, not the message.
# ---------------------------------------------------------------------------

for my $case (
  [ 'syntax error at pg_result',         'error',           qr/syntax error/ ],
  [ 'bind error at execute',             'exec_error',      qr/bind variables/ ],
  [ 'FATAL text, connection still open', 'fatal_but_alive', qr/terminating connection/ ],
) {
  my ($label, $outcome, $error_re) = @$case;
  my $s = fresh();
  my ($pid) = call($s);

  my ($got, $err) = call($s, $outcome);
  ok !defined $got, "$label: the call fails";
  like $err, $error_re, "$label: with DBD::Pg's error";
  is_deeply pool_state($s), [ 1, 1 ], "$label: the connection is back in the pool, idle";

  my ($next, $next_err) = call($s);
  is $next, $pid, "$label: the next call runs on the SAME connection"
    or diag $next_err // 'another connection';
  is scalar(@CONNECTS), 1, "$label: no connection was opened for it";
}

# ---------------------------------------------------------------------------
# 5. A transaction's pinned connection. Core hands it back through the pool's
#    release once the transaction ends, so the report made by the query path
#    retires it there.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  my ($pid) = call($s);

  # BEGIN runs, the SELECT loses the connection, the ROLLBACK then finds it gone.
  push @OUTCOMES, 'ok', 'lost';
  my $f = $s->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->select_async('t', ['x'], {});
  });
  ok $f->is_ready && $f->is_failed, 'connection lost in a transaction: the transaction fails';
  is_deeply pool_state($s), [ 0, 0 ], '... and its pinned connection is retired, not released';

  my ($next, $next_err) = call($s);
  ok defined $next, '... the next call completes' or diag $next_err;
  ok defined $next && $next != $pid, '... on a freshly spawned connection';
}

{
  my $s = fresh();
  my ($pid) = call($s);

  # BEGIN runs, the SELECT fails with a statement error, ROLLBACK runs.
  push @OUTCOMES, 'ok', 'error', 'ok';
  my $f = $s->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->select_async('t', ['x'], {});
  });
  ok $f->is_ready && $f->is_failed, 'statement error in a transaction: the transaction fails';
  like scalar $f->failure, qr/syntax error/, '... with the statement\'s error (ROLLBACK went through)';
  is_deeply pool_state($s), [ 1, 1 ], '... and its connection is released, idle';

  my ($next) = call($s);
  is $next, $pid, '... the next call runs on the SAME connection';
}

done_testing;
