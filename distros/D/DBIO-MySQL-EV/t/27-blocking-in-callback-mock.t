use strict;
use warnings;
use Test::More;

# OFFLINE test for karr k51 (option c, which replaces k48's option b): a
# blocking call made inside a callback of one of the transport's own
# connections WAITS and RETURNS. It is not refused any more.
#
# WHY it used to be refused (k48): every blocking method is ->get on its
# *_async sibling, and DBIO::MySQL::EV::Future's get runs the EV loop until the
# Future is ready. EV::MariaDB 0.08 only QUEUES a query issued on a handle
# while a callback of that handle runs (callback_depth > 0), and sends it once
# that callback has returned. A then on this transport's Futures and a txn_do
# coderef ran inside such a callback, so a blocking call there whose statement
# has no bind values (sent as a plain query) waited for a statement that was
# never sent. k48 made that wait die with "Blocking wait refused".
#
# WHAT k51 changes: the transport settles its Futures from an idle watcher of
# the EV loop, not from inside the EV::MariaDB callback. What a then or a
# txn_do coderef runs is therefore outside every callback of the handle
# (depth 0), and a statement it sends goes out at once. THIS FILE REPLACES THE
# CLAIM OF ITS PREVIOUS VERSION: it asserted that these waits die with
# "Blocking wait refused" (k48); it now asserts that they return. The refusal
# of the exhausted pool (k53, t/33) is untouched and stays.
#
# What this file claims:
#   1. Returned, not refused, not hung:
#      a. a sync bindless select in a then on this transport, pool of one;
#      b. a sync bindless insert there (INSERT ... () VALUES ());
#      c. a sync bindless $ctx->select in a txn_do coderef -- txn_do commits;
#      d. a bindless $ctx->select_async queued on the txn connection from a
#         callback of ANOTHER connection that runs nested inside the txn
#         coderef's wait.
#   2. The mechanism: a then callback runs with the handle's callback depth at
#      0, and Futures settle in the order their callbacks came (dispatch order
#      on one connection).
#   3. No change where nothing hung before: a sync call with bind values on the
#      same connection, a sync bindless call that gets another connection, a
#      sync call from a plain EV timer, $ctx->insert in a txn coderef, and a
#      top-level call after a callback of the connection died.
#
# 1 fails against the k48 code (each case dies with the refusal), and so does
# the depth assertion of 2 (the callback ran at depth 1). Red before the fix:
# 12 of 39 assertions.
#
# QueueMDB stands in for EV::MariaDB, modelling the one thing k48 is about:
# a callback of a handle runs with the handle's depth raised; query() queues,
# and sends at once only when the handle is idle and its depth is 0; the queue
# is sent after one of the handle's callbacks returns (at any depth) or an
# exclusive operation of it completes; prepare / execute / close_stmt are
# exclusive and start at once; and while anything is pending on the handle it
# keeps an active watcher, as the real read watcher does. Completions arrive
# on EV timers.
#
# Every wait is bounded by an EV watchdog with keepalive(0) -- a wait that
# hangs sits in libev's C code, where an alarm never fires (karr k46). When it
# fires it fails everything pending on every fake handle, as a dropped server
# connection would, so a hang shows up as a failed assertion and the file goes
# on.

use EV;
use DBIO::MySQL::EV::Future;
use DBIO::MySQL::EV::Storage;
use DBIO::MySQL::EV::Pool;

my $LIMIT   = 3;
my $REFUSED = qr/\QBlocking wait refused\E/;
my $ASYNC   = qr/_async.*->then/s;
my $SEL     = 'SELECT `id`, `name` FROM `artist`';
my $INS     = 'INSERT INTO `artist` () VALUES ()';
my $LII     = 'SELECT LAST_INSERT_ID()';
my @COLS    = qw( id name );

{
  package QueueMDB;
  use Scalar::Util ();
  use Socket ();

  our @ALL;

  sub new {
    my ($class, %args) = @_;
    my $self = bless {
      on_connect => $args{on_connect},
      connected  => 0,
      depth      => 0,       # EV::MariaDB's callback_depth
      op         => undef,   # the exclusive operation in progress
      queue      => [],      # queries not sent yet: [ $sql, $cb ]
      sent       => [],      # queries sent, result not delivered yet
      wire       => [],      # every statement the server received, in order
      stmts      => {},
      next_stmt  => 0,
    }, $class;
    # A live session: a real socket with nothing to read, which is what the
    # pool asks an idle handle about before handing it out (karr k58).
    socketpair($self->{sock}[0], $self->{sock}[1], Socket::AF_UNIX(), Socket::SOCK_STREAM(), Socket::PF_UNSPEC())
      or die "socketpair: $!";
    push @ALL, $self;
    Scalar::Util::weaken($ALL[-1]);
    _later(sub { $self->{connected} = 1; $self->_callback($self->{on_connect}) });
    return $self;
  }

  sub is_connected  { $_[0]{connected} }
  # As strict as EV::MariaDB 0.08 (karr k67).
  sub close_async   { Carp::croak('Usage: EV::MariaDB::close_async(self, cb)') unless @_ == 2; Carp::croak('not connected') unless $_[0]{connected}; $_[1]->(1); return }
  sub finish        { Carp::croak('Usage: EV::MariaDB::finish(self)') unless @_ == 1; return }
  sub socket        { fileno $_[0]{sock}[0] }
  sub pending_count { ($_[0]{op} ? 1 : 0) + @{ $_[0]{queue} } + @{ $_[0]{sent} } }

  sub _later {
    my ($cb) = @_;
    my $t;
    $t = EV::timer(0.001, 0, sub { undef $t; $cb->() });
    return;
  }

  # The handle's own watcher: active while anything is pending on it, so a
  # wait for a statement that is never sent spins instead of finding the loop
  # empty.
  sub _watch {
    my ($self) = @_;
    if ($self->{op} || @{ $self->{queue} } || @{ $self->{sent} }) {
      $self->{watch} ||= EV::timer(0.05, 0.05, sub { });
    }
    else {
      delete $self->{watch};
    }
    return;
  }

  # A callback of the handle: depth raised while it runs, an exception is
  # caught and warned (G_EVAL), and afterwards whatever was queued is sent --
  # at any depth, as maybe_pipeline does.
  sub _callback {
    my ($self, $cb, @args) = @_;
    $self->{depth}++;
    eval { $cb->(@args) if $cb; 1 } or warn "QueueMDB: exception in callback: $@";
    $self->{depth}--;
    $self->_pump;
    return;
  }

  sub _pump {
    my ($self) = @_;
    unless ($self->{op}) {
      for my $q (splice @{ $self->{queue} }) {
        push @{ $self->{wire} }, $q->[0];
        push @{ $self->{sent} }, $q;
      }
      $self->_read_next;
    }
    $self->_watch;
    return;
  }

  sub _read_next {
    my ($self) = @_;
    return if $self->{reading} || !@{ $self->{sent} };
    $self->{reading} = 1;
    _later(sub {
      $self->{reading} = 0;
      my $q = shift @{ $self->{sent} } or return;
      $self->_callback($q->[1], $self->_answer($q->[0]));
      $self->_read_next;
    });
    return;
  }

  sub _answer {
    my ($self, $sql) = @_;
    return ([ [ 7 ] ])         if $sql =~ /LAST_INSERT_ID/;
    return ([ [ 1, 'one' ] ])  if $sql =~ /^SELECT/;
    return (1)                 if $sql =~ /^(?:INSERT|UPDATE|DELETE)/;
    return (0);
  }

  sub query {
    my ($self, $sql, $cb) = @_;
    die "not connected\n" unless $self->{connected};
    die "cannot queue query: exclusive operation in progress\n" if $self->{op};
    push @{ $self->{queue} }, [ $sql, $cb ];
    if ($self->{depth}) { $self->_watch } else { $self->_pump }
    return;
  }

  sub _check_ready {
    my ($self) = @_;
    die "not connected\n" unless $self->{connected};
    die "another operation is in progress\n" if $self->{op};
    die "cannot start operation while pipeline results are pending\n" if @{ $self->{sent} };
    return;
  }

  sub _start {
    my ($self, $what, $cb, $answer) = @_;
    $self->{op} = $what;
    $self->_watch;
    _later(sub {
      undef $self->{op};
      $self->_callback($cb, $answer->());
    });
    return;
  }

  sub prepare {
    my ($self, $sql, $cb) = @_;
    $self->_check_ready;
    $self->_start(prepare => $cb, sub {
      my $id = ++$self->{next_stmt};
      $self->{stmts}{$id} = $sql;
      return ($id);
    });
    return;
  }

  sub execute {
    my ($self, $id, $bind, $cb) = @_;
    $self->_check_ready;
    my $sql = $self->{stmts}{$id};
    push @{ $self->{wire} }, $sql;
    $self->_start(execute => $cb, sub { $self->_answer($sql) });
    return;
  }

  sub close_stmt {
    my ($self, $id, $cb) = @_;
    $self->_check_ready;
    $self->_start(close_stmt => $cb, sub { delete $self->{stmts}{$id}; return (1) });
    return;
  }

  # COM_RESET_CONNECTION, sent by the pool at the end of every borrow (karr
  # k100, core k398): exclusive like prepare, not a statement of the wire.
  sub reset_connection {
    my ($self, $cb) = @_;
    $self->_check_ready;
    $self->_start(reset_connection => $cb, sub { return (1) });
    return;
  }

  # The watchdog's way out of a hang: fail everything pending on every handle.
  sub break_all {
    my ($class, $why) = @_;
    for my $self (grep { defined } @ALL) {
      my @stuck = ( splice(@{ $self->{queue} }), splice(@{ $self->{sent} }) );
      $self->_watch;
      $self->_callback($_->[1], undef, $why) for @stuck;
    }
    return;
  }
}

{
  no warnings 'redefine';
  *DBIO::MySQL::EV::Pool::_new_connection = sub { shift; QueueMDB->new(@_) };
}

sub build_storage {
  my ($size) = @_;
  my $storage = DBIO::MySQL::EV::Storage->new(undef);
  $storage->connect_info([ { host => 'fake', database => 'fake', pool_size => $size }, {} ]);
  return $storage;
}

sub conns { @{ $_[0]->pool->{_connections} } }

# The idle connections of the pool once the reset of the sessions has answered
# (karr k100, core k398): a connection is idle again after it, not at the release.
sub idle_count {
  my ($storage, $want) = @_;
  my $dog = EV::timer(2, 0, sub {});
  EV::run(EV::RUN_ONCE()) until $storage->pool->available == $want || !$dog->is_active;
  return $storage->pool->available;
}

# A txn coderef hands back a Future: core's txn_do_async cannot take an
# unblessed reference as the coderef's plain return value.
sub done_with { DBIO::MySQL::EV::Future->done(@_) }

# Run $code under the watchdog: (1, @result) when it returned, (0, $error) when
# it died. A wait still blocked after $LIMIT seconds is failed by the watchdog.
my @WARN;
sub bounded {
  my ($label, $code) = @_;
  my $dog = EV::timer($LIMIT, 0, sub {
    QueueMDB->break_all("watchdog: $label still blocked after ${LIMIT}s\n");
  });
  $dog->keepalive(0);
  local $SIG{__WARN__} = sub { push @WARN, $_[0] };
  my @r;
  return (1, @r) if eval { @r = $code->(); 1 };
  return (0, $@);
}

sub no_lost_sequence {
  my ($label) = @_;
  my @lost = grep { /lost a sequence Future/ } @WARN;
  ok !@lost, "$label: no sequence Future was lost" or diag @lost;
  @WARN = ();
  return;
}

# --- 1a. then + sync bindless select, pool of one ------------------------------
{
  my $storage = build_storage(1);
  my ($ok, @r) = bounded('select in a then', sub {
    $storage->select_async('artist', \@COLS, {}, {})->then(sub {
      return DBIO::MySQL::EV::Future->done([ $storage->select('artist', \@COLS, {}, {}) ]);
    })->get;
  });
  ok $ok, 'a sync bindless select in a then on this transport (pool of one) returns' or diag $r[0];
  is_deeply $r[0], [ [ 1, 'one' ] ], '(its rows)';

  my ($h) = conns($storage);
  is scalar(grep { $_ eq $SEL } @{ $h->{wire} }), 2, 'both SELECTs reached the server';

  my ($next_ok, @rows) = bounded('next select', sub { $storage->select('artist', \@COLS, {}, {}) });
  ok $next_ok, 'the next select works' or diag $rows[0];
  is idle_count($storage, 1), 1, 'and the pool is idle again';
  no_lost_sequence('select in a then');
}

# --- 1b. then + sync bindless insert --------------------------------------------
{
  my $storage = build_storage(1);
  my ($ok, @r) = bounded('insert in a then', sub {
    $storage->select_async('artist', \@COLS, {}, {})->then(sub {
      return DBIO::MySQL::EV::Future->done($storage->insert('artist', {}));
    })->get;
  });
  ok $ok, 'a sync bindless insert in a then (pool of one) returns' or diag $r[0];

  my ($h) = conns($storage);
  my @wire = @{ $h->{wire} };
  my ($at) = grep { $wire[$_] eq $INS } 0 .. $#wire;
  ok defined $at && ($wire[$at + 1] // '') eq $LII,
    'the insert read LAST_INSERT_ID() right after its INSERT, on that connection'
    or diag explain \@wire;
  is $storage->last_insert_id, 7, '(and captured it)';
  is idle_count($storage, 1), 1, 'the pool is idle again';
  no_lost_sequence('insert in a then');
}

# --- 1c. txn_do coderef + sync bindless $ctx->select ---------------------------
{
  my $storage = build_storage(1);
  my ($ok, @r) = bounded('ctx select', sub {
    $storage->txn_do(sub {
      my ($ctx) = @_;
      return done_with([ $ctx->select('artist', \@COLS, {}, {}) ]);
    });
  });
  ok $ok, 'txn_do returns when its coderef makes a sync bindless $ctx->select' or diag $r[0];
  is_deeply $r[0], [ [ 1, 'one' ] ], '(the rows of the select)';

  my ($h) = conns($storage);
  is_deeply [ @{ $h->{wire} }[0 .. 2] ], [ 'BEGIN', $SEL, 'COMMIT' ],
    'the select ran inside the transaction, which committed';
  is idle_count($storage, 1), 1, 'the pool is idle again';
  no_lost_sequence('ctx select');
}

# --- 1d. a statement queued on the txn connection from a callback of another --
{
  my $storage = build_storage(2);
  my ($ok, @r) = bounded('nested connection', sub {
    $storage->txn_do(sub {
      my ($ctx) = @_;
      return $storage->select_async('artist', \@COLS, { id => 1 }, {})->then(sub {
        return $ctx->select_async('artist', \@COLS, {}, {});
      })->get;
    });
  });
  ok $ok, 'a wait in a txn coderef for a statement queued on its connection from another connection\'s callback returns'
    or diag $r[0];
  my ($txn) = conns($storage);
  is_deeply [ @{ $txn->{wire} }[0 .. 2] ], [ 'BEGIN', $SEL, 'COMMIT' ], 'in the transaction, which committed';
  is idle_count($storage, 2), 2, 'both connections are back in the pool';
  no_lost_sequence('nested connection');
}

# --- 2. the mechanism: callbacks run outside the handle's callback, in order ---
{
  my $storage = build_storage(1);
  my ($depth, @order);
  my $f = $storage->select_async('artist', \@COLS, {}, {});
  my ($h) = conns($storage);
  $f->on_done(sub { $depth = $h->{depth}; push @order, 'first' });
  $f->on_done(sub { push @order, 'second' });
  bounded('depth', sub { $f->get });
  is $depth, 0, 'a callback of a statement runs with the handle\'s callback depth at 0, not inside its callback';
  is_deeply \@order, [ qw( first second ) ], 'callbacks of one Future run in the order they were registered';
}

{
  my $storage = build_storage(1);
  my @order;
  bounded('pinned order', sub {
    $storage->txn_do(sub {
      my ($ctx) = @_;
      my @f = map { my $n = $_; $ctx->select_async('artist', \@COLS, {}, {})->on_done(sub { push @order, $n }) } 1 .. 4;
      return DBIO::MySQL::EV::Future->needs_all(@f);
    });
  });
  is_deeply \@order, [ 1 .. 4 ], 'four statements pipelined on one pinned connection settle in dispatch order';
}

# --- 3. no refusal where nothing would hang ------------------------------------
{
  my $storage = build_storage(1);
  my ($ok, @r) = bounded('bound select in a then', sub {
    $storage->select_async('artist', \@COLS, {}, {})->then(sub {
      return [ $storage->select('artist', \@COLS, { id => 1 }, {}) ];
    })->get;
  });
  ok $ok, 'a sync select WITH bind values in a then on the same connection returns' or diag $r[0];
  is_deeply $r[0], [ [ 1, 'one' ] ], '(its rows)';
  no_lost_sequence('bound select in a then');
}

{
  my $storage = build_storage(2);
  my ($ok, @r) = bounded('select on another connection', sub {
    $storage->txn_do(sub { return done_with([ $storage->select('artist', \@COLS, {}, {}) ]) });
  });
  ok $ok, 'a sync bindless select in a txn coderef that gets ANOTHER connection returns' or diag $r[0];
  is_deeply $r[0], [ [ 1, 'one' ] ], '(its rows)';
  my ($txn, $other) = conns($storage);
  is_deeply $txn->{wire}, [ 'BEGIN', 'COMMIT' ], 'and the transaction committed';
  is_deeply $other->{wire}, [ $SEL ], 'the select ran on the other connection';
}

{
  my $storage = build_storage(1);
  my ($depth, $ok, @rows);
  my $t = EV::timer(0, 0, sub {
    $depth = EV::depth();
    $ok = eval { @rows = $storage->select('artist', \@COLS, {}, {}); 1 };
    @rows = ($@) unless $ok;
    EV::break;
  });
  bounded('select in a timer', sub { EV::run });
  is $depth, 1, 'called from a plain EV timer callback';
  ok $ok, 'a sync bindless select returns there' or diag $rows[0];
  is_deeply \@rows, [ [ 1, 'one' ] ], '(its rows)';
}

{
  my $storage = build_storage(1);
  my ($ok, @r) = bounded('ctx insert', sub {
    $storage->txn_do(sub { return done_with($_[0]->insert('artist', { name => 'x' })) });
  });
  ok $ok, '$ctx->insert in a txn coderef returns' or diag $r[0];
  is_deeply $r[0], { name => 'x' }, '(the returned-columns hashref)';
  my ($h) = conns($storage);
  is_deeply [ grep { !/^INSERT/ } @{ $h->{wire} } ], [ 'BEGIN', $LII, 'COMMIT' ],
    'reading LAST_INSERT_ID() on the txn connection, then committing';
  no_lost_sequence('ctx insert');
}

{
  my $storage = build_storage(1);
  my $f = $storage->select_async('artist', \@COLS, {}, {});
  $f->on_done(sub { die "k48 callback died\n" });
  bounded('dying callback', sub { $f->get });
  ok scalar(grep { /k48 callback died/ } @WARN), 'a callback of the connection died';
  @WARN = ();
  my ($ok, @rows) = bounded('select after it', sub { $storage->select('artist', \@COLS, {}, {}) });
  ok $ok, 'a top-level sync bindless select afterwards returns: the dead callback left nothing behind'
    or diag $rows[0];
}

done_testing;
