use strict;
use warnings;
use Test::More;

# OFFLINE test for karr k61 (core karr k252): a dispatch that hands back NO
# FUTURE -- undef, a plain value -- without dying.
#
# WHY IT MATTERS. _query_async and insert_async take a pooled connection and
# hang its release on the Future their dispatch returns. A dispatch that dies
# before it has one is covered since karr k50 (t/28): the die becomes a failed
# Future, and that Future takes the release. A dispatch that RETURNS without a
# Future is a different case. Nothing was thrown, so there is no error to pass
# on, and nothing to hang the release on either: the connection stays checked
# out, and the caller is told about whatever tripped over the missing Future
# -- Future.pm refusing an empty exception, or a method called on a plain
# value -- not about the method that owed the Future. A pool of N is wedged
# for good after N such calls.
#
# Who returns no Future: the wire seam of the pooled path is the executor, and
# a storage keeps the one it was given ({executor}); insert_async's is
# _run_crud_pinned, which a subclass or a composed async layer may override.
#
# What this file claims, for each of the two paths and each of three answers
# -- the dispatch dies, returns undef, returns a plain value:
#   a. the call answers through a failed Future; it does not throw;
#   b. the error is the dispatch's own when it died, and otherwise names the
#      backend class and the method that owed the Future;
#   c. nothing of the failed call reached the wire;
#   d. the connection went back to the pool exactly once and sits on the idle
#      list -- a pool of one has one idle connection;
#   e. the next call on that pool of one gets the connection and completes.
#
# The die answer holds without core's _seam_future (karr k50); it is here so
# that the three answers are held side by side on both paths. For undef and a
# plain value b, d and e fail without it: the release is never registered, and
# the next call waits for a connection nobody returns. That wait is bounded --
# DBIO::MySQL::EV::Future dies when nothing left in the loop could settle it
# (karr k48), and a keepalive(0) watchdog fails it should something keep the
# loop alive -- so the regression shows as a failure, not a hang.
#
# WHAT IS REAL. The transport -- _query_async, insert_async, _release_on_ready
# -- the real DBIO::MySQL::EV::Pool with every release recorded, the real
# DBIO::MySQL::EV::QueryExecutor behind the answering one, and core's
# _seam_future; section 0 pins that. TimerMDB stands in for EV::MariaDB (the
# t/26 fake): every operation completes on an EV timer.

use EV;
use Scalar::Util 'refaddr';
use DBIO::Storage::Async;
use DBIO::MySQL::EV::Storage;
use DBIO::MySQL::EV::Pool;
use DBIO::MySQL::EV::QueryExecutor;

# Every statement that reached the fake wire.
my @WIRE;

{
  package TimerMDB;
  use Socket ();

  sub new {
    my ($class, %args) = @_;
    my $self = bless { on_connect => $args{on_connect}, connected => 0, stmts => {}, next => 0 }, $class;
    # A live session: a real socket with nothing to read, which is what the
    # transport asks a handle about after a failed statement (karr k55).
    socketpair($self->{sock}[0], $self->{sock}[1], Socket::AF_UNIX(), Socket::SOCK_STREAM(), Socket::PF_UNSPEC())
      or die "socketpair: $!";
    _later(sub { $self->{connected} = 1; $self->{on_connect}->() });
    return $self;
  }

  sub _later {
    my ($cb) = @_;
    my $t;
    $t = EV::timer(0.001, 0, sub { undef $t; $cb->() });
    return;
  }

  sub _answer {
    my ($sql) = @_;
    return ([ [ 7 ] ])        if $sql =~ /LAST_INSERT_ID/;
    return ([ [ 1, 'one' ] ]) if $sql =~ /^SELECT/;
    return (1)                if $sql =~ /^(?:INSERT|UPDATE|DELETE)/;
    return (0);
  }

  sub is_connected { $_[0]{connected} }
  # As strict as EV::MariaDB 0.08 (karr k67).
  sub close_async  { Carp::croak('Usage: EV::MariaDB::close_async(self, cb)') unless @_ == 2; Carp::croak('not connected') unless $_[0]{connected}; $_[1]->(1); return }
  sub finish       { Carp::croak('Usage: EV::MariaDB::finish(self)') unless @_ == 1; return }
  sub socket       { fileno $_[0]{sock}[0] }
  sub pending_count { 0 }

  sub query {
    my ($self, $sql, $cb) = @_;
    push @WIRE, $sql;
    _later(sub { $cb->(_answer($sql)) });
    return;
  }

  sub prepare {
    my ($self, $sql, $cb) = @_;
    push @WIRE, $sql;
    my $id = ++$self->{next};
    $self->{stmts}{$id} = $sql;
    _later(sub { $cb->($id) });
    return;
  }

  sub execute {
    my ($self, $id, $bind, $cb) = @_;
    my $sql = $self->{stmts}{$id};
    _later(sub { $cb->(_answer($sql)) });
    return;
  }

  sub close_stmt {
    my ($self, $id, $cb) = @_;
    delete $self->{stmts}{$id};
    _later(sub { $cb->(1) });
    return;
  }

  # The reset the pool sends at the end of every borrow (karr k100, core k398);
  # it is no statement of the call under test, so it is not in @WIRE.
  sub reset_connection {
    my ($self, $cb) = @_;
    _later(sub { $cb->(1, undef) });
    return;
  }
}

# What a dispatch answers instead of doing its work, once: 'die', 'undef' or
# 'plain'. Shared by the two dispatches below.
sub answer_instead {
  my ($how, $who) = @_;
  die "$who died\n" if $how eq 'die';
  return undef      if $how eq 'undef';
  return 1;
}

# The real pool, building TimerMDB handles and recording every release.
{
  package RecPool31;
  use base 'DBIO::MySQL::EV::Pool';

  sub _new_connection { shift; TimerMDB->new(@_) }

  sub release {
    my ($self, $conn) = @_;
    push @{ $self->{release_log} }, Scalar::Util::refaddr($conn);
    return $self->SUPER::release($conn);
  }
}

# The real executor, which answers once from {answer} when it is set.
{
  package Executor31;
  use base 'DBIO::MySQL::EV::QueryExecutor';

  sub execute {
    my ($self, @args) = @_;
    if (defined(my $how = delete $self->{answer})) {
      return main::answer_instead($how, 'the executor');
    }
    return $self->SUPER::execute(@args);
  }
}

# The real transport, whose _run_crud_pinned answers an insert once from
# {insert_answer} when it is set.
{
  package NoFuture31;
  use base 'DBIO::MySQL::EV::Storage';

  sub _run_crud_pinned {
    my ($self, $op, @args) = @_;
    if ($op eq 'insert' && defined(my $how = delete $self->{insert_answer})) {
      return main::answer_instead($how, 'the insert');
    }
    return $self->SUPER::_run_crud_pinned($op, @args);
  }
}

# A storage with a pool of one and the answering executor. The storage builds
# its own pool; it is reblessed before it has made a connection.
sub pool_of_one {
  my $storage = NoFuture31->new(undef);
  $storage->connect_info([ { host => 'fake', database => 'fake', pool_size => 1 }, {} ]);
  bless $storage->pool, 'RecPool31';
  $storage->{executor} = Executor31->new(future_class => $storage->future_class);
  return $storage;
}

# Wait for $f on the EV loop: (1, @result) once it is done, (0, $error) once it
# failed. A Future still pending after 5 seconds is failed by the watchdog.
sub wait_for {
  my ($f) = @_;
  my $dog = EV::timer(5, 0, sub { $f->fail("watchdog: still pending after 5s\n") unless $f->is_ready });
  $dog->keepalive(0);
  my @r;
  return (1, @r) if eval { @r = $f->get; 1 };
  return (0, $@);
}

# The five claims, for one path and one answer. $arm sets the answer on
# $storage, $call starts a call of the path under test.
sub fails_and_releases {
  my ($label, $storage, $arm, $call, $error, $expect) = @_;
  my $pool = $storage->pool;
  @WIRE = ();

  $arm->();
  my $f = eval { $call->() };
  ok ref $f, "$label: the call answers with a Future, it does not throw"
    or diag "it threw: $@";
  return unless ref $f;

  my ($ok, @r) = wait_for($f);
  ok !$ok, "$label: the Future fails";
  like $r[0], $error, "$label: with an error that says who owed the Future";

  is_deeply \@WIRE, [], "$label: nothing of the call reached the wire";
  is scalar @{ $pool->{release_log} // [] }, 1,
    "$label: its connection went back to the pool exactly once";
  # Back on the idle list once the reset of its session has answered.
  my $dog = EV::timer(2, 0, sub {});
  EV::run(EV::RUN_ONCE()) until $pool->available == 1 || !$dog->is_active;
  is $pool->available, 1, "$label: and sits on the idle list";

  ($ok, @r) = wait_for($call->());
  ok $ok, "$label: the next call on the pool of one gets the connection"
    or diag "it failed: $r[0]";
  is_deeply \@r, $expect, "$label: and completes";
  is $pool->size, 1, "$label: on the one connection the pool has";
}

# ---------------------------------------------------------------------------
# 0. What gives the rest its meaning: the path around the two dispatches is
#    the transport's own, the insert dispatch is the mock's, and the helper
#    that turns "no Future" into a failure is core's, not a copy kept here.
# ---------------------------------------------------------------------------

for my $method (qw( _query_async _query_async_pinned insert_async _release_on_ready )) {
  is refaddr(NoFuture31->can($method)), refaddr(DBIO::MySQL::EV::Storage->can($method)),
    "the mock does NOT override $method -- the transport itself runs";
}
isnt refaddr(NoFuture31->can('_run_crud_pinned')),
  refaddr(DBIO::MySQL::EV::Storage->can('_run_crud_pinned')),
  'the mock DOES override _run_crud_pinned -- the premise for insert_async';
is refaddr(NoFuture31->can('_seam_future')),
  refaddr(DBIO::Storage::Async->can('_seam_future')),
  '_seam_future is core\'s';

# ---------------------------------------------------------------------------
# 1. Pooled: the executor is the dispatch. The method that owes the Future is
#    the storage's _await_query_result, which hands the statement to it.
# ---------------------------------------------------------------------------

for my $case (
  [ die   => qr/^the executor died$/ ],
  [ undef => qr/^NoFuture31->_await_query_result returned undef, not a Future/ ],
  [ plain => qr/^NoFuture31->_await_query_result returned no Future/ ],
) {
  my ($how, $error) = @$case;
  my $storage = pool_of_one();
  fails_and_releases(
    "pooled, the executor answers $how",
    $storage,
    sub { $storage->{executor}{answer} = $how },
    sub { $storage->select_async('artist', [qw( id name )]) },
    $error,
    [ [ 1, 'one' ] ],
  );
}

# ---------------------------------------------------------------------------
# 2. insert_async: _run_crud_pinned is the dispatch.
# ---------------------------------------------------------------------------

for my $case (
  [ die   => qr/^the insert died$/ ],
  [ undef => qr/^NoFuture31->_run_crud_pinned returned undef, not a Future/ ],
  [ plain => qr/^NoFuture31->_run_crud_pinned returned no Future/ ],
) {
  my ($how, $error) = @$case;
  my $storage = pool_of_one();
  fails_and_releases(
    "insert_async, _run_crud_pinned answers $how",
    $storage,
    sub { $storage->{insert_answer} = $how },
    sub { $storage->insert_async('artist', { name => 'y' }) },
    $error,
    [ { name => 'y' } ],
  );
}

done_testing;
