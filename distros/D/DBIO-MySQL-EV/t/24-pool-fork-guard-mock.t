use strict;
use warnings;
use Test::More;
use Scalar::Util qw( refaddr weaken );
use List::Util ();
use File::Temp ();
use POSIX ();
use Time::HiRes ();

# OFFLINE regression for karr k46: the pool's fork guard (ADR 0010, amendment
# k46).
#
# WHY it matters: EV::MariaDB closes nothing in a forked child, but EV re-arms
# the default loop there and EV::MariaDB's I/O callback does not check the pid.
# A child that resumes the EV loop while a pooled statement was in flight at
# fork time reads the reply off the socket it shares with the parent: the child
# runs the parent's callback, and the parent's statement -- and every later one
# on that session -- hangs. Measured live (fact 4 of ADR 0010).
#
# What this file claims, for a child that resumes the loop with three pooled
# connections -- one idle, one checked out for a bound query whose execute is
# in flight, one pinned by txn_do_async with a statement in flight:
#   1. the child finishes its copy of EVERY one of them, before its loop
#      delivers anything, and so consumes none of the parent's replies;
#   2. finish calls the in-flight callbacks with "connection finished" (as the
#      real client does), and nothing the parent attached runs on that in the
#      child: no close_stmt, no ROLLBACK, no release into the pool, no settled
#      query / transaction Future, no caller callback;
#   3. in the parent -- the owner -- the guard does nothing, also when EV runs
#      its fork watchers there: no handle is finished, and every statement in
#      flight at fork time completes with its own result;
#   4. the guard does not keep the pool alive;
#   5. nor the loop: an active EV::fork watcher alone keeps EV::run from ever
#      returning, so a program that runs the loop until its queries are done
#      would hang on the guard -- in the parent, and in a child after the
#      guard fired. EV::run must return once nothing else keeps it running.
#
# And for a child that USES the pool (karr k54). Since core karr k233 its first
# acquire takes the pool over: PoolBase::_verify_pid drops the parent's
# connections and the child spawns its own. The fork watcher runs at the start
# of the child's next loop iteration, so it can come after that takeover or
# before it, and neither order may break anything:
#   6. acquire first, then the loop: the watcher must leave the child's own
#      connection alone -- finishing it mid-connect would leave the child's
#      acquire pending for good -- and the child never gets a parent handle;
#   7. the loop first, then acquire: the watcher finishes the parent's handles
#      while they are still the pool's, and the child's acquire then gets a
#      fresh connection of its own, not a finished inherited one;
#   8. acquire first, with parent handles in flight and pinned at fork time:
#      those are no longer in the pool when the watcher runs, but the pending
#      statements keep them alive, their watchers still on the parent's
#      sockets. They must be finished all the same, or the child reads the
#      parent's replies -- the k46 bug, back for this order -- while the
#      child's own connection keeps working.
# 6-8 need core k233; with a core before it they skip, saying so.
#   9. with any core: when the parent built the pool but never opened a
#      connection, the child's acquire opens the first one and arms the watcher
#      in the child. The watcher must finish nothing there -- everything in the
#      pool is the child's. Before k233 the child never owns the pool, so only
#      k46's check against the pid that armed the watcher keeps its connection
#      alive.
#
# ForkMDB stands in for EV::MariaDB behind the pool's raw-handle seam. Its
# completions run on real EV timers, so in the child libev itself decides that
# the fork watchers run before them; a result can be held until the test
# releases it. It dies as the real client does: "connection not valid after
# fork" for an operation in a forked process, "not connected" after finish,
# "another operation is in progress" on overlap. It cannot share a socket
# between two processes -- the parent-side hang is what t/24-pool-fork-live.t
# shows against a real server. The socket it does have is one end of a
# socketpair nothing is ever written to: what the pool asks of an idle
# connection before handing it out (karr k58), answered as a session that is
# still there.

BEGIN {
  eval { require EV; 1 }     or plan skip_all => 'EV not installed';
  eval { require Future; 1 } or plan skip_all => 'Future not installed';
}

use DBIO::MySQL::EV::Storage;
use DBIO::MySQL::EV::Pool;

{
  package ForkMDB;
  use Socket ();

  my $next_thread = 500;

  sub new {
    my ($class, %args) = @_;
    socketpair(my $client, my $server, Socket::AF_UNIX(), Socket::SOCK_STREAM(), Socket::PF_UNSPEC())
      or die "socketpair: $!";
    my $self = bless {
      on_connect => $args{on_connect},
      client     => $client,
      server     => $server,
      thread_id  => ++$next_thread,
      opener     => $$,
      connected  => 0,
      inflight   => undef,
      stmts      => {},
      next_stmt  => 0,
      hold       => undef,
      held       => [],
      timers     => {},
      tick       => 0,
      attempted  => [],   # every operation called, also those that died
      delivered  => [],   # every result handed to a callback: who read it
      finished   => [],   # every finish: in which process
    }, $class;
    $self->_later(sub { $self->{connected} = 1; $self->{on_connect}->() if $self->{on_connect} });
    return $self;
  }

  sub _later {
    my ($self, $cb) = @_;
    my $id = ++$self->{tick};
    $self->{timers}{$id} = EV::timer(0, 0, sub { delete $self->{timers}{$id}; $cb->() });
    return;
  }

  sub _guard {
    my ($self, $what) = @_;
    push @{ $self->{attempted} }, { what => $what, pid => $$ };
    die "connection not valid after fork\n" if $self->{opener} != $$;
    die "not connected\n" if !$self->{connected} || @{ $self->{finished} };
    die "another operation is in progress\n" if $self->{inflight};
    return;
  }

  sub _start {
    my ($self, $what, $sql, $cb, $answer) = @_;
    my $op = $self->{inflight} = { what => $what, cb => $cb };
    my $run = sub {
      return unless $self->{inflight} && $self->{inflight} == $op;
      undef $self->{inflight};
      push @{ $self->{delivered} }, { what => $what, pid => $$ };
      $cb->($answer->());
    };
    if ($self->{hold} && ($what eq 'execute' || $what eq 'query')
        && defined $sql && $sql =~ $self->{hold}) {
      push @{ $self->{held} }, $run;
    }
    else {
      $self->_later($run);
    }
    return;
  }

  sub prepare {
    my ($self, $sql, $cb) = @_;
    $self->_guard('prepare');
    $self->_start(prepare => $sql, $cb, sub {
      my $id = ++$self->{next_stmt};
      $self->{stmts}{$id} = $sql;
      return ($id);
    });
    return;
  }

  sub execute {
    my ($self, $stmt, $bind, $cb) = @_;
    $self->_guard('execute');
    my $sql  = $self->{stmts}{$stmt} // die "invalid statement handle\n";
    my @wire = @$bind;
    $self->_start(execute => $sql, $cb, sub { return ([ [ "own:$self->{thread_id}", @wire ] ]) });
    return;
  }

  sub close_stmt {
    my ($self, $stmt, $cb) = @_;
    $self->_guard('close_stmt');
    $self->_start(close_stmt => undef, $cb, sub { delete $self->{stmts}{$stmt}; return (1) });
    return;
  }

  sub query {
    my ($self, $sql, $cb) = @_;
    $self->_guard('query');
    $self->_start(query => $sql, $cb, sub {
      return ([ [ "own:$self->{thread_id}" ] ]) if $sql =~ /\A\s*SELECT/i;
      return ($sql =~ /\A\s*UPDATE/i ? 1 : 0);
    });
    return;
  }

  # As measured on the real client in a forked child: every operation in flight
  # is called back synchronously with "connection finished"; nothing is sent.
  sub finish {
    my ($self) = @_;
    push @{ $self->{finished} }, { pid => $$ };
    %{ $self->{timers} } = ();
    @{ $self->{held} } = ();
    if (my $op = delete $self->{inflight}) { $op->{cb}->(undef, 'connection finished') }
    return;
  }

  # As strict as EV::MariaDB 0.08 (karr k67).
  sub close_async { Carp::croak('Usage: EV::MariaDB::close_async(self, cb)') unless @_ == 2; Carp::croak('not connected') unless $_[0]{connected}; $_[1]->(1); return }

  # The result arrives: the socket becomes readable in whichever process runs
  # the loop next.
  sub release_held {
    my ($self) = @_;
    $self->{hold} = undef;
    $self->_later($_) for splice @{ $self->{held} };
    return;
  }

  sub is_connected { $_[0]{connected} && !@{ $_[0]{finished} } }
  sub socket        { @{ $_[0]{finished} } ? -1 : fileno $_[0]{client} }
  sub pending_count { $_[0]{inflight} ? 1 : 0 }
  sub thread_id    { $_[0]{thread_id} }
  sub open_stmts   { scalar keys %{ $_[0]{stmts} } }
  sub count_in     { my ($self, $key, $pid) = @_; scalar grep { $_->{pid} == $pid } @{ $self->{$key} } }
}

# The real pool, with ForkMDB behind its raw-handle seam (as t/08 and t/23 do):
# _create_connection -- where the guard is armed -- is the real one.
{
  package ForkPool;
  use base 'DBIO::MySQL::EV::Pool';
  sub _new_connection { shift; ForkMDB->new(@_) }
}

my $TICK = EV::timer(0.002, 0.002, sub {});   # RUN_ONCE never blocks for long

# Run the loop until it returns by itself; true if it did. Bounded by a timer
# that does not keep the loop running itself: a loop kept alive by something
# else fails after $max seconds instead of hanging the test.
sub loop_returns {
  my ($max) = @_;
  my $stuck;
  my $bound = EV::timer($max // 2, 0, sub { $stuck = 1; EV::break(EV::BREAK_ALL()) });
  $bound->keepalive(0);
  EV::run();
  return !$stuck;
}

sub drive {
  my ($cond, $max) = @_;
  my $deadline = Time::HiRes::time() + ($max // 3);
  until ($cond->()) {
    return 0 if Time::HiRes::time() > $deadline;
    EV::run(EV::RUN_ONCE());
  }
  return 1;
}

sub settle {
  my $deadline = Time::HiRes::time() + ($_[0] // 0.05);
  EV::run(EV::RUN_ONCE()) while Time::HiRes::time() < $deadline;
  return;
}

my $HELD = qr/k46_held/;

my $storage = DBIO::MySQL::EV::Storage->new(undef);
my $pool    = $storage->{pool} = ForkPool->new(conninfo => { host => 'dummy' }, size => 3);

# Three connections, spawned and connected, back in the pool.
my @conns;
push @conns, $pool->acquire for 1 .. 3;
ok drive(sub { !grep { !$_->is_ready } @conns }), 'three pooled connections are up';
@conns = map { $_->get } @conns;
$pool->release($_) for @conns;
$_->{hold} = $HELD for @conns;
my ($queried, $pinned, $idle) = @conns;   # acquire hands them out FIFO

# One checked out for a bound query: its execute is in flight at fork time.
my $query = $storage->_query_async('SELECT ? AS k46_held', [ 7 ]);
my $query_ready = 0;
$query->on_ready(sub { $query_ready++ });
ok drive(sub { @{ $queried->{held} } }), 'a bound query has its execute in flight';

# One pinned by a transaction: a statement in flight after BEGIN.
my $txn = $storage->txn_do_async(sub {
  my ($ctx) = @_;
  return $ctx->_query_async('UPDATE t SET v = v + 1 /* k46_held */', []);
});
my $txn_ready = 0;
$txn->on_ready(sub { $txn_ready++ });
ok drive(sub { @{ $pinned->{held} } }), 'a pinned transaction has a statement in flight';

is $pool->available, 1, 'one connection idle, two out';
is refaddr($pool->{_idle}[0]), refaddr($idle), '... the idle one is the third';

# --- the child resumes the loop -------------------------------------------------

my $report = File::Temp->new;
my $child  = fork;
die "fork: $!" unless defined $child;
unless ($child) {
  # The replies arrive while the child runs the loop.
  $_->release_held for @conns;
  settle(0.3);
  my @r = (
    (map { $_->count_in(finished  => $$) } @conns),
    (map { $_->count_in(delivered => $$) } @conns),
    (map { $_->count_in(attempted => $$) } @conns),
    ($query->is_ready ? 1 : 0), $query_ready,
    ($txn->is_ready   ? 1 : 0), $txn_ready,
    $pool->available,
  );
  undef $TICK;
  push @r, loop_returns() ? 1 : 0;
  open my $fh, '>', $report->filename or POSIX::_exit(2);
  print {$fh} join("\t", @r), "\n";
  close $fh;
  POSIX::_exit(0);
}
waitpid($child, 0);
is $? >> 8, 0, 'the child resumed the loop and exited';

open my $fh, '<', $report->filename or die "report: $!";
chomp(my $line = <$fh> // '');
my @r = split /\t/, $line;
is scalar(@r), 15, 'the child reported'
  or diag "report: '$line'";

is "@r[0..2]", '1 1 1',
  'the child finished its copy of every pooled handle: idle, checked out, pinned';
is "@r[3..5]", '0 0 0', '... and read none of the parent\'s replies';
is "@r[6..8]", '0 0 0',
  '... and started nothing on them: no close_stmt, no ROLLBACK after "connection finished"';
is "@r[9..10]", '0 0', 'the pooled query\'s Future stayed pending in the child, no callback ran';
is "@r[11..12]", '0 0', 'the transaction\'s Future stayed pending in the child, no callback ran';
is $r[13], 1, 'nothing was released into the child\'s pool';
is $r[14], 1, 'the child\'s loop returned by itself: the guard that fired does not keep it running';

# --- the parent, the owner ------------------------------------------------------

is join(' ', map { $_->count_in(finished => $$) } @conns), '0 0 0',
  'the parent\'s handles were not finished';

# EV runs its fork watchers in this process too once told a fork happened; in
# the owner the guard must do nothing.
EV::default_loop->loop_fork;
settle(0.02);
is join(' ', map { scalar @{ $_->{finished} } } @conns), '0 0 0',
  '... not even when the fork watchers run in the owner';

$_->release_held for @conns;
ok drive(sub { $query->is_ready && $txn->is_ready }), 'the statements in flight at fork time complete in the parent';
ok $query->is_done, 'the pooled query succeeded';
is_deeply [ $query->get ], [ [ "own:$queried->{thread_id}", 7 ] ], '... with its own result';
is $queried->open_stmts, 0, '... and its statement was closed (karr k45)';
ok $txn->is_done, 'the transaction committed';
is_deeply [ $txn->get ], [ 1 ], '... with the result of its own statement';
is "$query_ready/$txn_ready", '1/1', 'each Future became ready exactly once';
is $pool->available, 3, 'every connection is back in the pool';

my $next = $storage->_query_async('SELECT ? AS after_fork', [ 8 ]);
ok drive(sub { $next->is_ready }), 'the pool serves the next query';
ok $next->is_done, '... successfully';

# --- no cycle -------------------------------------------------------------------

undef $_ for $query, $txn, $next;
weaken(my $weak_pool = $pool);
undef $pool;
$storage->disconnect;
ok !defined $weak_pool, 'the pool is freed on disconnect: its fork guard does not keep it alive';

# --- nor the loop ---------------------------------------------------------------
# The usual shape of a program: start the work, run the loop, and expect it to
# return once the work is done. The pool's fork guard is armed by then.

{
  undef $TICK;
  my $s = DBIO::MySQL::EV::Storage->new(undef);
  my $p = $s->{pool} = ForkPool->new(conninfo => { host => 'dummy' }, size => 1);
  my $got;
  my $f = $s->_query_async('SELECT ? AS k46_loop', [ 9 ])->on_done(sub { $got = $_[0] });
  ok loop_returns(3), 'EV::run returned by itself once the query was done: the guard does not keep the loop running';
  ok $f->is_done, '... the query succeeded';
  ok $p->{_mysql_fork}, '... with the pool\'s fork guard armed';
  $s->disconnect;
}

# --- a child that uses the pool (karr k54, after core k233) ----------------------

# A storage over a ForkPool with $n connections, spawned, connected and back in
# the pool -- in this process, the owner.
sub pooled {
  my ($n) = @_;
  my $s = DBIO::MySQL::EV::Storage->new(undef);
  my $p = $s->{pool} = ForkPool->new(conninfo => { host => 'dummy' }, size => $n);
  my @f = map { $p->acquire } 1 .. $n;
  drive(sub { !grep { !$_->is_ready } @f }) or die "the pool did not come up\n";
  my @c = map { $_->get } @f;
  $p->release($_) for @c;
  return ($s, $p, @c);
}

# Fork, run $code in the child and hand back what it returns: key/value pairs,
# plus the child's exit status as 'exit'. The child leaves through POSIX::_exit
# and runs no DESTROY and no END block.
sub in_child {
  my ($code) = @_;
  my $report = File::Temp->new;
  my $pid = fork;
  die "fork: $!" unless defined $pid;
  unless ($pid) {
    my @r = eval { $code->() };
    my $died = @r ? 0 : 1;
    @r = (died => "$@") if $died;
    open my $fh, '>', $report->filename or POSIX::_exit(2);
    print {$fh} join("\t", map { s/[\t\n]/ /gr } @r), "\n";
    close $fh;
    POSIX::_exit($died ? 3 : 0);
  }
  waitpid($pid, 0);
  my $exit = $? >> 8;
  open my $fh, '<', $report->filename or die "report: $!";
  chomp(my $line = <$fh> // '');
  return (exit => $exit, split /\t/, $line);
}

sub sum_in {
  my ($key, @conns) = @_;
  return List::Util::sum0(map { $_->count_in($key => $$) } @conns);
}

# What the child's own connections look like, from inside the child.
sub own_report {
  my ($p, $q) = @_;
  my @own = @{ $p->{_connections} };
  my ($row) = $q->is_done ? $q->get : ();
  return (
    own          => scalar(@own),
    own_mine     => scalar(grep { $_->{opener} == $$ } @own),
    own_finished => sum_in(finished => @own),
    own_tid      => join(',', map { $_->thread_id } @own),
    query_ready  => ($q->is_ready ? 1 : 0),
    query_ok     => ($q->is_done ? 1 : 0),
    answered_by  => ($row ? $row->[0] : ''),
    answer       => ($row ? $row->[1] : ''),
  );
}

# The claims every case makes about the child's own connection.
sub child_owns_its_connection {
  my ($r, $bind, $parent_tid) = @_;
  is $r->{adopted}, 1, 'the child\'s first acquire took the pool over (core k233)';
  is "$r->{own}/$r->{own_mine}", '1/1',
    '... and the pool in the child holds exactly one connection, opened by the child';
  is $r->{own_finished}, 0, 'the fork watcher did not finish the child\'s own connection';
  is "$r->{query_ready}/$r->{query_ok}", '1/1', 'the child\'s query completed, successfully';
  is $r->{answered_by}, "own:$r->{own_tid}", '... answered by the child\'s own connection';
  ok !$parent_tid->{ $r->{own_tid} }, '... which is none of the parent\'s';
  is $r->{answer}, $bind, '... with its own result';
}

my $K233 = DBIO::Storage::PoolBase->can('_verify_pid');
my $tick = EV::timer(0.002, 0.002, sub {});   # RUN_ONCE never blocks for long

SKIP: {
  skip 'core before k233: DBIO::Storage::PoolBase has no _verify_pid, so a forked '
     . 'child does not take the pool over and there is no own connection to protect', 3
    unless $K233;

  # Claim 6 -- acquire first, then the loop. The shape of a child that calls
  # *_async and ->get's it: the takeover and the spawn happen before the child's
  # loop has run, and the fork watcher runs first thing inside that ->get. If it
  # finished the pool's connections regardless of who owns the pool, it would
  # finish the child's fresh connection mid-connect, and the child's query would
  # never complete.
  subtest 'acquire before the fork watcher runs: the child keeps its own connection' => sub {
    my ($s, $p, @parent) = pooled(2);
    my %parent_tid = map { ($_->thread_id => 1) } @parent;

    my %r = in_child(sub {
      my $q = $s->_query_async('SELECT ? AS k54_acquire_first', [ 11 ]);
      my $adopted = $p->{_owner_pid} == $$ ? 1 : 0;
      # The parent's handles, dropped by the takeover, are only weakly
      # remembered: an idle one nothing else holds must still be freed.
      # (grep aliases the stash's own elements; a copy of a weak ref is strong.)
      my $stash = $p->{_mysql_inherited} || [];
      my $stash_live   = grep { defined } @$stash;
      my $stash_strong = grep { defined($_) && !Scalar::Util::isweak($_) } @$stash;
      drive(sub { $q->is_ready });
      return (
        adopted           => $adopted,
        stash_live        => scalar($stash_live),
        stash_strong      => scalar($stash_strong),
        parent_attempted  => sum_in(attempted => @parent),
        own_report($p, $q),
      );
    });

    is $r{exit}, 0, 'the child ran and exited' or diag explain \%r;
    child_owns_its_connection(\%r, 11, \%parent_tid);
    is $r{parent_attempted}, 0, 'the child was handed no parent handle: nothing ran on one there';
    is "$r{stash_live}/$r{stash_strong}", '2/0',
      'the parent\'s dropped handles are remembered, and only weakly: none is kept alive by it';

    is sum_in(finished => @parent), 0, 'in the parent, none of its handles was finished';
    is $p->{_owner_pid}, $$, '... and the parent still owns its pool';
    my $next = $s->_query_async('SELECT ? AS k54_parent', [ 21 ]);
    ok drive(sub { $next->is_ready }) && $next->is_done, '... which serves the next query';
    my ($row) = $next->get;
    ok $parent_tid{ $row->[0] =~ s/^own://r }, '... on one of the parent\'s own connections';
    $s->disconnect;
  };

  # Claim 7 -- the loop first, then acquire. The watcher runs while the pool is
  # still the parent's and finishes everything in it (the k46 behaviour); the
  # takeover that follows must hand the child a fresh connection, not one of
  # the finished inherited ones.
  subtest 'acquire after the fork watcher ran: the child gets a fresh connection' => sub {
    my ($s, $p, @parent) = pooled(2);
    my %parent_tid = map { ($_->thread_id => 1) } @parent;

    my %r = in_child(sub {
      settle(0.05);
      my $finished_first = sum_in(finished => @parent);
      my $q = $s->_query_async('SELECT ? AS k54_acquire_after', [ 12 ]);
      my $adopted = $p->{_owner_pid} == $$ ? 1 : 0;
      drive(sub { $q->is_ready });
      return (
        adopted          => $adopted,
        finished_first   => $finished_first,
        parent_attempted => sum_in(attempted => @parent),
        own_report($p, $q),
      );
    });

    is $r{exit}, 0, 'the child ran and exited' or diag explain \%r;
    is $r{finished_first}, 2,
      'the loop ran first: the watcher finished both parent handles while they were the pool\'s';
    child_owns_its_connection(\%r, 12, \%parent_tid);
    is $r{parent_attempted}, 0, 'nothing ran on a finished parent handle in the child';

    is sum_in(finished => @parent), 0, 'in the parent, none of its handles was finished';
    $s->disconnect;
  };

  # Claim 8 -- the gap the plain ownership guard leaves. At fork time one parent
  # handle has a bound query in flight and one is pinned by a transaction with a
  # statement in flight. The child acquires first: the takeover drops both from
  # the pool, but the pending statements still hold them, with their watchers
  # on the sockets the parent is reading. The watcher, which leaves the pool's
  # (now the child's) connections alone, must finish these, or the child's loop
  # reads the parent's replies. The test holds the handles too, the way the
  # pending statements do, so it can look at them afterwards.
  subtest 'acquire first with parent handles in flight: those are still finished' => sub {
    my $held = qr/k54_held/;
    my ($s, $p, @parent) = pooled(3);
    my %parent_tid = map { ($_->thread_id => 1) } @parent;
    $_->{hold} = $held for @parent;
    my ($queried, $pinned) = @parent;   # acquire hands them out FIFO

    my $query = $s->_query_async('SELECT ? AS k54_held', [ 13 ]);
    ok drive(sub { @{ $queried->{held} } }), 'a bound query has its execute in flight';
    my $txn = $s->txn_do_async(sub {
      return $_[0]->_query_async('UPDATE t SET v = v + 1 /* k54_held */', []);
    });
    ok drive(sub { @{ $pinned->{held} } }), 'a pinned transaction has a statement in flight';

    my %r = in_child(sub {
      # The replies arrive while the child runs its loop.
      $_->release_held for @parent;
      my $q = $s->_query_async('SELECT ? AS k54_child', [ 14 ]);
      my $adopted = $p->{_owner_pid} == $$ ? 1 : 0;
      drive(sub { $q->is_ready });
      settle(0.1);   # time for a parent reply to reach the child, if it can
      return (
        adopted          => $adopted,
        queried_finished => $queried->count_in(finished => $$),
        pinned_finished  => $pinned->count_in(finished => $$),
        parent_delivered => sum_in(delivered => $queried, $pinned),
        parent_attempted => sum_in(attempted => @parent),
        parent_query     => ($query->is_ready ? 1 : 0),
        parent_txn       => ($txn->is_ready ? 1 : 0),
        own_report($p, $q),
      );
    });

    is $r{exit}, 0, 'the child ran and exited' or diag explain \%r;
    is "$r{queried_finished} $r{pinned_finished}", '1 1',
      'the child finished its copy of the checked-out and the pinned parent handle, though the pool had dropped them';
    is $r{parent_delivered}, 0, '... and read none of the parent\'s replies';
    is $r{parent_attempted}, 0, '... and started nothing on them';
    is "$r{parent_query} $r{parent_txn}", '0 0',
      'the parent\'s query and transaction Futures stayed pending in the child';
    child_owns_its_connection(\%r, 14, \%parent_tid);

    is sum_in(finished => @parent), 0, 'in the parent, none of its handles was finished';
    EV::default_loop->loop_fork;
    settle(0.02);
    is sum_in(finished => @parent), 0, '... not even when the fork watchers run in the parent';
    $_->release_held for @parent;
    ok drive(sub { $query->is_ready && $txn->is_ready }),
      'the statements in flight at fork time complete in the parent';
    is_deeply [ $query->get ], [ [ "own:$queried->{thread_id}", 13 ] ],
      '... the query with its own result';
    is_deeply [ $txn->get ], [ 1 ], '... the transaction with its own statement\'s result';
    is $p->available, 3, 'every connection is back in the parent\'s pool';
    $s->disconnect;
  };
}

# Claim 9 -- runs with any core. The parent builds the pool but opens no
# connection, so it never arms the fork watcher. The child's acquire opens the
# pool's first connection and arms the watcher in the child, where it fires at
# the start of the child's first loop iteration. Everything in the pool is then
# the child's, so the watcher must finish nothing: finishing the connection
# mid-connect would leave the child's query pending for good. With a core
# before k233 the parent still owns the pool in the child, so the ownership
# check alone would call the child's connection inherited; k46's check against
# the pid that armed the watcher is what keeps it working there.
subtest 'the child opens the pool\'s first connection: the watcher it arms finishes nothing' => sub {
  my $s = DBIO::MySQL::EV::Storage->new(undef);
  my $p = $s->{pool} = ForkPool->new(conninfo => { host => 'dummy' }, size => 1);
  ok !$p->{_mysql_fork} && !@{ $p->{_connections} },
    'the parent built the pool, opened no connection and armed no watcher';

  my %r = in_child(sub {
    my $q = $s->_query_async('SELECT ? AS k54_first_in_child', [ 15 ]);
    my $armed = $p->{_mysql_fork} ? 1 : 0;
    # The premise, checked rather than assumed: a fork watcher armed in the
    # child before its loop has run does fire in that loop.
    my $probe_fired = 0;
    my $probe = EV::fork(sub { $probe_fired++ });
    $probe->keepalive(0);
    drive(sub { $q->is_ready });
    return (
      armed       => $armed,
      probe_fired => $probe_fired,
      own_report($p, $q),
    );
  });

  is $r{exit}, 0, 'the child ran and exited' or diag explain \%r;
  is $r{armed}, 1, 'the child\'s acquire armed the pool\'s fork watcher in the child';
  is $r{probe_fired}, 1, '... where a fork watcher armed before the loop does fire';
  is "$r{own}/$r{own_mine}", '1/1', 'the pool in the child holds one connection, opened by the child';
  is $r{own_finished}, 0, 'the watcher did not finish the child\'s connection';
  is "$r{query_ready}/$r{query_ok}", '1/1', 'the child\'s query completed, successfully';
  is $r{answered_by}, "own:$r{own_tid}", '... answered by the child\'s connection';
  is $r{answer}, 15, '... with its own result';
  $s->disconnect;
};
undef $tick;

done_testing;
