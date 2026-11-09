use strict;
use warnings;
use Test::More;
use Scalar::Util qw( weaken );

BEGIN {
  eval { require Future; 1 } or plan skip_all => 'Future not installed';
  eval { require EV; 1 }     or plan skip_all => 'EV not installed';
}

use DBIO::MySQL::EV::QueryExecutor;
use DBIO::MySQL::EV::Storage;
use DBIO::MySQL::EV::Pool;

# OFFLINE regression for karr k45: the executor must close every statement it
# prepares, and must not let the connection go before the close is done.
#
# WHY it matters: EV::MariaDB's statement id is a plain integer, so nothing
# frees the server-side statement when Perl lets go of it. Without close_stmt
# the server keeps each one until the connection closes; a long-lived pool runs
# into the SERVER-WIDE max_prepared_stmt_count and from then on the server
# refuses every prepare, for every client. And close_stmt is exclusive
# (ADR 0010 fact 1): a handle with a close in flight is not idle, so a pool that
# got it back before the close finished would hand it to a caller whose prepare
# dies with "another operation is in progress".
#
# What this file claims:
#   1. executor: a bound query is prepare -> execute -> close_stmt, on success,
#      on an execute error and on an execute that croaks; the Future is NOT
#      ready while the close is in flight; it carries the execute's outcome,
#      exactly once, also when the close croaks (before or after calling back)
#      or reports an error of its own; a failed prepare has nothing to close;
#      a bindless query is a plain query; the bind arrayref is not held while
#      the close is in flight (ADR 0044).
#   2. pool: through the REAL DBIO::MySQL::EV::Pool (size 1) and the storage's
#      _query_async / insert_async / _notify_send, N concurrent bound queries
#      leave no statement open on the handle and never overlap an exclusive
#      operation; the connection is not back in the pool while its close runs.
#
# StrictMDB stands in for EV::MariaDB. Every operation completes on a later
# step of a hand-driven queue (the test decides when), prepare / execute /
# close_stmt are exclusive and die while anything is in flight, and -- stricter
# than the real client -- so does query. It keeps the set of statements the
# "server" holds, which is what the real Prepared_stmt_count counts.

our @PENDING;

sub later { push @PENDING, $_[0]; return }

# Run the oldest pending completion.
sub step { my $cb = shift @PENDING or return 0; $cb->(); settle(); return 1 }

# The executor settles a Future from the loop's idle watcher, not inside the
# handle's callback (karr k51): run the loop once, without blocking, so what
# the step answered is settled before the test looks (the hand-driven queue
# stands in for the loop).
sub settle { EV::run(EV::RUN_NOWAIT()); return }

# Run everything, including what the completions schedule.
sub drain {
  my $n = 0;
  while (step()) { die "drain: runaway queue\n" if ++$n > 10_000 }
  return;
}

{
  package StrictMDB;

  sub new {
    my ($class, %args) = @_;
    my $self = bless {
      on_connect => $args{on_connect},
      connected  => 0,
      inflight   => undef,
      stmts      => {},
      next_stmt  => 0,
      ops        => [],
      closed     => [],
      violations => [],
    }, $class;
    main::later(sub { $self->{connected} = 1; $self->{on_connect}->() if $self->{on_connect} });
    return $self;
  }

  sub is_connected { $_[0]{connected} }
  # As strict as EV::MariaDB 0.08 (karr k67).
  sub close_async  { Carp::croak('Usage: EV::MariaDB::close_async(self, cb)') unless @_ == 2; Carp::croak('not connected') unless $_[0]{connected}; $_[1]->(1); return }
  sub finish       { Carp::croak('Usage: EV::MariaDB::finish(self)') unless @_ == 1; return }
  sub open_stmts   { scalar keys %{ $_[0]{stmts} } }
  sub ops          { join ' ', @{ $_[0]{ops} } }

  sub _guard {
    my ($self, $what) = @_;
    if (my $op = $self->{inflight}) {
      push @{ $self->{violations} }, "$what while $op was in flight";
      die "another operation is in progress\n";
    }
    return;
  }

  # Start $what; its callback gets $answer->() on a later step, with the
  # handle already idle again (as the real client).
  sub _start {
    my ($self, $what, $cb, $answer) = @_;
    $self->{inflight} = $what;
    push @{ $self->{ops} }, $what;
    main::later(sub {
      undef $self->{inflight};
      my @r = $answer->();
      $cb->(@r) if $cb;
    });
    return;
  }

  sub prepare {
    my ($self, $sql, $cb) = @_;
    $self->_guard('prepare');
    $self->_start(prepare => $cb, sub {
      return (undef, $self->{fail_prepare}) if $self->{fail_prepare};
      my $id = ++$self->{next_stmt};
      $self->{stmts}{$id} = $sql;
      return ($id);
    });
    return;
  }

  sub execute {
    my ($self, $stmt, $bind, $cb) = @_;
    die "$self->{croak_execute}\n" if $self->{croak_execute};
    $self->_guard('execute');
    my $sql = $self->{stmts}{$stmt} // die "invalid statement handle\n";
    my @wire = @$bind;   # serialised at dispatch; the arrayref is not kept
    $self->_start(execute => $cb, sub {
      return (undef, $self->{fail_execute}) if $self->{fail_execute};
      return $self->_answer($sql);
    });
    return;
  }

  sub close_stmt {
    my ($self, $stmt, $cb) = @_;
    my $mode = $self->{croak_close} // '';
    die "close_stmt refused\n" if $mode eq 'before';
    if ($mode eq 'after') {        # calls back synchronously, then croaks
      delete $self->{stmts}{$stmt};
      $cb->(1);
      die "close_stmt croaked after calling back\n";
    }
    $self->_guard('close_stmt');
    $self->_start(close_stmt => $cb, sub {
      push @{ $self->{closed} }, $stmt;
      return (undef, $self->{fail_close}) if $self->{fail_close};
      delete $self->{stmts}{$stmt};
      return (1);
    });
    return;
  }

  sub query {
    my ($self, $sql, $cb) = @_;
    $self->_guard('query');
    $self->_start(query => $cb, sub { $self->_answer($sql) });
    return;
  }

  sub _answer {
    my ($self, $sql) = @_;
    return ([[ 42 ]])        if $sql =~ /LAST_INSERT_ID/;
    return ([[ 1, 'row' ]])  if $sql =~ /^\s*SELECT/i;
    return (1);              # DML: affected rows
  }
}

# The real pool, with StrictMDB behind its raw-handle seam (as t/08 does).
{
  package StrictPool;
  use base 'DBIO::MySQL::EV::Pool';
  sub _new_connection { shift; StrictMDB->new(@_) }
}

my $executor = DBIO::MySQL::EV::QueryExecutor->new;

# Step until the handle has $what in flight; the op list shows where it is.
sub run_until_inflight {
  my ($mdb, $what) = @_;
  step() while @PENDING && ($mdb->{inflight} // '') ne $what;
  return ($mdb->{inflight} // '') eq $what;
}

# --- 1. executor ----------------------------------------------------------------

# 1a. success: prepare -> execute -> close_stmt, settled only after the close
{
  @PENDING = ();
  my $mdb = StrictMDB->new; drain();
  my @weak;
  my $f;
  {
    my $bind = [ 'alpha' ];
    push @weak, $bind; weaken($weak[-1]);
    $f = $executor->execute($mdb, 'SELECT * FROM t WHERE a = ?', $bind);
  }

  ok run_until_inflight($mdb, 'close_stmt'), 'a close_stmt follows the execute';
  ok !$f->is_ready, 'the Future is NOT ready while the close is in flight';
  is $mdb->open_stmts, 1, 'the statement is still open until the close completes';
  ok !defined $weak[0], 'the bind arrayref is not held while the close is in flight (ADR 0044)';

  drain();
  ok $f->is_done, 'the Future is done once the close completed';
  is_deeply [ $f->get ], [[ 1, 'row' ]], '... with the rows of the execute';
  is $mdb->ops, 'prepare execute close_stmt', 'exactly prepare, execute, close_stmt';
  is_deeply $mdb->{closed}, [ 1 ], 'the statement closed is the one prepared';
  is $mdb->open_stmts, 0, 'no statement left open on the server';
}

# 1b. an execute error closes too, and the Future fails only after the close
{
  @PENDING = ();
  my $mdb = StrictMDB->new; drain();
  $mdb->{fail_execute} = "Duplicate entry '1' for key 'PRIMARY'";
  my $f = $executor->execute($mdb, 'INSERT INTO t (id) VALUES (?)', [ 1 ]);

  ok run_until_inflight($mdb, 'close_stmt'), 'a failed execute is closed too';
  ok !$f->is_ready, 'the Future is NOT ready while that close is in flight';
  drain();
  ok $f->is_failed, 'the Future fails once the close completed';
  like $f->failure, qr/Duplicate entry/, '... with the execute error';
  is $mdb->open_stmts, 0, 'no statement left open after a failed execute';
}

# 1c. an execute that croaks: the statement exists, so it is closed as well,
#     and the Future fails instead of hanging in a swallowed callback
{
  @PENDING = ();
  my $mdb = StrictMDB->new; drain();
  $mdb->{croak_execute} = 'Unsupported bind parameter type';
  my $f = $executor->execute($mdb, 'SELECT ?', [ 1 ]);

  ok run_until_inflight($mdb, 'close_stmt'), 'a croaking execute still gets its statement closed';
  ok !$f->is_ready, 'the Future waits for that close';
  drain();
  ok $f->is_failed, 'the Future fails';
  like $f->failure, qr/Unsupported bind parameter type/, '... with the croak';
  is $mdb->open_stmts, 0, 'no statement left open after a croaking execute';
}

# 1d. a close that croaks without calling back: settled at once, not pending
{
  @PENDING = ();
  my $mdb = StrictMDB->new; drain();
  $mdb->{croak_close} = 'before';
  my $f = $executor->execute($mdb, 'SELECT ?', [ 1 ]);
  my $died = eval { drain(); 1 } ? undef : $@;

  is $died, undef, 'nothing escapes into the event loop';
  ok $f->is_done, 'a close that croaks does not leave the Future pending';
  is_deeply [ $f->get ], [[ 1, 'row' ]], '... it carries the execute result';
}

# 1e. a close that calls back and THEN croaks: settled exactly once
{
  @PENDING = ();
  my $mdb = StrictMDB->new; drain();
  $mdb->{croak_close} = 'after';
  my $f = $executor->execute($mdb, 'SELECT ?', [ 1 ]);
  my $ready = 0;
  $f->on_ready(sub { $ready++ });
  my $died = eval { drain(); 1 } ? undef : $@;

  is $died, undef, 'no "already done" croak: the Future is not settled twice';
  is $ready, 1, 'the Future became ready exactly once';
  ok $f->is_done, '... done, with the execute result';
}

# 1f. a close that reports an error does not change the execute's outcome: an
#     INSERT that ran must not be reported failed (the caller would retry it)
{
  @PENDING = ();
  my $mdb = StrictMDB->new; drain();
  $mdb->{fail_close} = 'Lost connection to server during query';
  my $f = $executor->execute($mdb, 'INSERT INTO t (a) VALUES (?)', [ 'x' ]);
  drain();
  ok $f->is_done, 'a close error leaves the Future done';
  is_deeply [ $f->get ], [ 1 ], '... with the affected rows of the INSERT';
}

# 1g. a failed prepare yields no statement: nothing to close
{
  @PENDING = ();
  my $mdb = StrictMDB->new; drain();
  $mdb->{fail_prepare} = "Table 'test.nope' doesn't exist";
  my $f = $executor->execute($mdb, 'SELECT * FROM nope WHERE a = ?', [ 1 ]);
  drain();
  ok $f->is_failed, 'a failed prepare fails the Future';
  like $f->failure, qr/doesn't exist/, '... with the prepare error';
  is $mdb->ops, 'prepare', 'no execute, no close_stmt without a statement';
}

# 1h. no binds: a plain query, nothing prepared
{
  @PENDING = ();
  my $mdb = StrictMDB->new; drain();
  my $f = $executor->execute($mdb, 'SELECT 1', []);
  drain();
  ok $f->is_done, 'a bindless query resolves';
  is $mdb->ops, 'query', 'a bindless query is a plain query';
}

# --- 2. pool --------------------------------------------------------------------

sub pooled_storage {
  my $storage = DBIO::MySQL::EV::Storage->new(undef);
  $storage->{pool} = StrictPool->new(conninfo => { host => 'dummy' }, size => 1);
  return $storage;
}

# 2a. the connection goes back to the pool only once its close has completed
{
  @PENDING = ();
  my $storage = pooled_storage();
  my $pool    = $storage->{pool};
  my $f = $storage->_query_async('SELECT * FROM t WHERE a = ?', [ 1 ]);
  step() until @{ $pool->{_connections} };
  my $mdb = $pool->{_connections}[0];

  ok run_until_inflight($mdb, 'close_stmt'), 'pooled query: close_stmt in flight';
  is scalar @{ $pool->{_idle} }, 0, 'the connection is NOT back in the pool while it closes';
  ok !$f->is_ready, 'the query Future is not ready yet';
  drain();
  ok $f->is_done, 'the query Future is done after the close';
  is scalar @{ $pool->{_idle} }, 1, 'the connection is back in the pool after the close';
}

# 2b. N concurrent bound queries on a pool of one: every statement closed, and
#     the next waiter never meets a handle with a close still in flight
{
  @PENDING = ();
  my $N = 25;
  my $storage = pooled_storage();
  my $pool    = $storage->{pool};

  my @f;
  push @f, $storage->_query_async('SELECT * FROM t WHERE a = ?', [ $_ ]) for 1 .. $N;
  push @f, $storage->insert_async('artist', { name => "a$_" })       for 1 .. $N;
  push @f, $storage->_notify_send('jobs', "payload $_")               for 1 .. $N;
  drain();

  is scalar @{ $pool->{_connections} }, 1, 'one connection served everything';
  my $mdb = $pool->{_connections}[0];
  is scalar(grep { $_->is_done } @f), 3 * $N, 'every query, insert and notify succeeded'
    or diag explain [ map { $_->failure } grep { $_->is_failed } @f ];
  is_deeply $mdb->{violations}, [], 'no operation ever overlapped a close_stmt'
    or diag explain $mdb->{violations};
  is scalar @{ $mdb->{closed} }, 3 * $N, 'as many statements closed as prepared';
  is $mdb->open_stmts, 0, 'no statement left open on the server';
  is $storage->last_insert_id, 42, 'insert_async still reads LAST_INSERT_ID() on the same session';
}

done_testing;
