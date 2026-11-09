use strict;
use warnings;
use Test::More;

# OFFLINE regression for karr k52: the pool's connect-action replay
# (_run_pool_connect_statement, core k68) waits on the EV loop, and must refuse
# that wait where DBIO::PostgreSQL::EV::Future's await refuses it (karr k44) --
# inside a callback of one of this transport's connections with more results
# due there.
#
# WHY: core spawns a pool connection synchronously, from acquire, when the pool
# has room and nothing idle, and replays the owning storage's on_connect_do /
# on_connect_call on it before handing it out. A pool call made inside a
# txn_do coderef that has already sent a $ctx statement therefore ran the EV
# loop inside the BEGIN callback of the pinned connection, with that
# statement's result due. EV::Pg keeps the callback it delivers to at the head
# of its queue until it returns, so the nested loop handed the result to the
# BEGIN callback again and then spun: measured against PostgreSQL 18.6, EV::Pg
# reported "exception in callback: ... is already done and cannot be ->done"
# and the process ran at 100% CPU until it was killed.
#
# What this file claims:
#   1. Through the REAL storage, pool and core transaction scaffold over a
#      stand-in EV::Pg, with an owner that replays one connect statement on
#      every new pool connection: a txn_do coderef that sent a $ctx statement
#      and then made a pool call that spawns gets that call's Future failed
#      with the refusal; nothing was read on the pinned connection while its
#      callback ran; the half-opened connection is retired with nothing sent on
#      it; the transaction rolls back after the $ctx statement; the pool is
#      left with its one connection, idle.
#   2. Not over-strict: the same pool call chained with then onto the $ctx
#      statement -- nothing more due on the pinned connection -- spawns,
#      replays, runs, and the transaction commits. A spawn outside any callback
#      replays too.
#   3. The seam itself: refused on entry, before anything is sent, while a
#      delivering connection has more than one result pending; allowed with
#      one; and refused before the next iteration when a result becomes due
#      there while the replay waits.
#   4. No callback of this transport dies out of EV::Pg.
#
# Before the fix 1 fails (the pool call resolves, the stand-in counts the read
# on the pinned connection, the transaction commits) and 3 fails (the replay
# runs to completion); 2 passes before and after.
#
# THE ONE SUBSTITUTION is EV::Pg, as in t/43: a stand-in the real pool builds
# through its real, fork-safe constructor. It connects and answers on EV
# timers, one statement at a time outside pipeline mode, delivering a result
# while pending_count still counts that callback. When a nested loop would read
# the next result on a connection whose callback is still running, it counts
# that read (nested_reads) and delivers nothing then -- the real EV::Pg hands
# the result to the wrong callback and spins, which a test cannot survive.

BEGIN {
  package EV::Pg;
  use Carp ();
  use Scalar::Util ();

  our $DELAY = 0.001;   # seconds until the connect / a result arrives
  our @OPENED;          # the id of every handle made, in order
  our %WIRE;            # id => [ SQL sent on it, in order ]
  our %FINISHED;        # id => 1 once finish was called

  my $ID = 0;

  sub new {
    my ($class, %args) = @_;
    my $self = bless {
      on_connect => $args{on_connect},
      on_error   => $args{on_error},
      up         => 0,
      queue      => [],
      busy       => 0,
      id         => ++$ID,
    }, $class;
    push @OPENED, $self->{id};
    Scalar::Util::weaken(my $weak = $self);
    $self->{connecting} = EV::timer($DELAY, 0, sub {
      return unless $weak;
      delete $weak->{connecting};
      $weak->{up} = 1;
      $weak->{on_connect}->() if $weak->{on_connect};
    });
    return $self;
  }

  sub on_error {
    my $s = shift;
    $s->{on_error} = $_[0] if @_;
    return $s->{on_error};
  }

  sub is_connected  { $_[0]{up} ? 1 : 0 }
  sub pending_count { scalar @{ $_[0]{queue} } }
  sub backend_pid   { $_[0]{id} }
  sub socket        { -1 }
  sub transaction_status { $_[0]{up} ? ($_[0]{busy} ? 1 : 0) : 4 }

  sub query_params {
    my ($self, $sql, $bind, $cb) = @_;
    Carp::croak('not connected') unless $self->{up};
    die "PQsendQueryParams failed: another command is already in progress\n"
      if $self->{busy};
    push @{ $WIRE{ $self->{id} } }, $sql;
    push @{ $self->{queue} }, { sql => $sql, cb => $cb };
    $self->{busy} = 1;
    $self->_arm;
    return;
  }

  sub query { my ($self, $sql, $cb) = @_; $self->query_params($sql, [], $cb) }

  sub finish {
    my ($self) = @_;
    $FINISHED{ $self->{id} } = 1;
    delete $self->{connecting};
    while (my $entry = shift @{ $self->{queue} }) {
      next if $self->{delivering} && $entry == $self->{delivering};
      eval { $entry->{cb}->(undef, 'connection finished'); 1 }
        or warn "EV::Pg: exception in callback during cancel: $@";
    }
    $self->{up} = 0;
    return;
  }

  sub _arm {
    my ($self) = @_;
    return if $self->{timer} || !@{ $self->{queue} };
    Scalar::Util::weaken(my $weak = $self);
    $self->{timer} = EV::timer($DELAY, 0, sub { $weak->_complete_head if $weak });
    return;
  }

  sub _complete_head {
    my ($self) = @_;
    delete $self->{timer};
    if ($self->{delivering}) {
      # A nested loop reads the next result while this connection's callback
      # runs. Counted; the rest is left until that callback has returned.
      $self->{nested_reads}++;
      return;
    }
    my $head = $self->{queue}[0] or return;
    my @result =
        $head->{sql} =~ /^SELECT\s+(\d+)/ ? ([ [ $1 ] ])
      :                                     ('');
    $self->{busy} = 0;
    $self->{delivering} = $head;
    eval { $head->{cb}->(@result); 1 } or warn "EV::Pg: exception in callback: $@";
    delete $self->{delivering};
    shift @{ $self->{queue} } if @{ $self->{queue} } && $self->{queue}[0] == $head;
    $self->_arm;
    return;
  }

  $INC{'EV/Pg.pm'} = __FILE__;
}

use EV;
use DBIO::PostgreSQL::EV::Future;
use DBIO::PostgreSQL::EV::Storage;

# These tests are not about the session reset of a pool connection (karr k99):
# NoSessionReset puts the connection back at once, as before the reset existed.
use FindBin;
use lib "$FindBin::Bin/lib";
use NoSessionReset;

alarm 60;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

my $EVF     = 'DBIO::PostgreSQL::EV::Future';
my $REPLAY  = q{SET application_name = 'k52'};
my $REFUSED = qr/Blocking wait refused: the pool is opening a new connection/;

# The owning sync storage, as far as this file asks it: one connect statement
# for every new pool connection (the shape of core's _run_pool_connect_actions),
# and the transaction context's ownership check (core k196), which it accepts
# -- refusing a foreign context is t/28's claim, not this file's.
{
  package K52::Owner;
  sub new { bless {}, shift }
  sub _run_pool_connect_actions {
    my ($self, $runner) = @_;
    $runner->($REPLAY, undef);
    return $self;
  }
  sub _assert_async_context_owner { $_[1] }
}

# A delivering connection for the seam-level claims: only pending_count.
{
  package K52::Delivering;
  sub new { bless { pending => $_[1] }, $_[0] }
  sub pending_count { $_[0]{pending} }
}

# A real storage over the stand-in, a pool of two, replaying $REPLAY. The
# owner is returned too: the storage holds it weakly.
sub storage_with_replay {
  my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
  $storage->connect_info([ { dbname => 'fake', pool_size => 2 }, {} ]);
  my $owner = K52::Owner->new;
  $storage->_owner_storage($owner);
  return ($storage, $owner);
}

# Wait for $f on the EV loop: (1, @result) once it is done, (0, $error) once it
# failed. A Future still pending after 5 seconds is failed by the watchdog.
sub wait_for {
  my ($f) = @_;
  EV::now_update();   # a timer counts from the loop's last "now", maybe long ago
  my $dog = EV::timer(5, 0, sub { $f->fail("watchdog: still pending after 5s\n") unless $f->is_ready });
  $dog->keepalive(0);
  my @r;
  return (1, @r) if eval { @r = $f->get; 1 };
  return (0, $@);
}

# Let every timer the stand-in still has run out.
sub settle {
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.05, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

sub failure_of { my ($f) = @_; return $f && $f->is_failed ? ($f->failure)[0] : '' }

sub no_callback_died {
  my ($label) = @_;
  my @died = grep { /exception in callback/ } @warnings;
  is scalar @died, 0, "$label: no callback died out of EV::Pg"
    or diag @died;
  @warnings = ();
}

# --- 1. a pool call that spawns, inside the coderef, with a $ctx statement due --

{
  my $label = 'spawn with a statement due';
  my ($storage, $owner) = storage_with_replay();
  my $first = @EV::Pg::OPENED;
  my ($ctx_f, $pool_f);
  my ($ok, $err) = wait_for($storage->txn_do_async(sub {
    my ($ctx) = @_;
    $ctx_f  = $ctx->_query_async('SELECT 1', []);        # on the wire at once
    $pool_f = $storage->_query_async('SELECT 2', []);    # the pool spawns
    return $ctx_f->then(sub { $pool_f });
  }));
  settle();

  my ($txn_id, $spawned_id) = @EV::Pg::OPENED[ $first, $first + 1 ];
  ok defined $spawned_id, "$label: the pool call made the pool open a second connection";
  like failure_of($pool_f), $REFUSED, "$label: the pool call fails with the refusal";
  like failure_of($pool_f), qr/1 more result\(s\) due/, "$label: naming what is due";
  ok !$ok, "$label: the transaction fails";
  like $err, $REFUSED, "$label: with the refusal";
  my $txn_pg = $storage->pool->{_connections}[0];
  is $txn_pg && $txn_pg->{nested_reads} // 0, 0,
    "$label: nothing was read on the pinned connection while its BEGIN callback ran";
  is_deeply $EV::Pg::WIRE{$txn_id}, [ $REPLAY, 'BEGIN', 'SELECT 1', 'ROLLBACK' ],
    "$label: the pinned connection ran its own replay, the \$ctx statement, then ROLLBACK";
  is_deeply $EV::Pg::WIRE{$spawned_id} // [], [],
    "$label: nothing was sent on the half-opened connection";
  ok $EV::Pg::FINISHED{$spawned_id}, "$label: which the pool retired";
  is $storage->pool->size, 1, "$label: the pool has its one connection";
  is $storage->pool->available, 1, "$label: idle";
  no_callback_died($label);
  $storage->disconnect;
}

# --- 2. the same call chained onto the $ctx statement ---------------------------

{
  my $label = 'spawn chained';
  my ($storage, $owner) = storage_with_replay();
  my $first = @EV::Pg::OPENED;
  my ($ok, @r) = wait_for($storage->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->_query_async('SELECT 1', [])->then(sub {
      $storage->_query_async('SELECT 2', []);
    });
  }));
  settle();

  my ($txn_id, $spawned_id) = @EV::Pg::OPENED[ $first, $first + 1 ];
  ok $ok, "$label: the transaction commits" or diag "it failed: $r[0]";
  is_deeply \@r, [ [ 2 ] ], "$label: with the pool call's result";
  is_deeply $EV::Pg::WIRE{$txn_id}, [ $REPLAY, 'BEGIN', 'SELECT 1', 'COMMIT' ],
    "$label: a spawn outside any callback replays (the transaction's own connection)";
  is_deeply $EV::Pg::WIRE{$spawned_id}, [ $REPLAY, 'SELECT 2' ],
    "$label: the spawn inside the callback replays before the call runs";
  is $storage->pool->size, 2, "$label: the pool has both connections";
  is $storage->pool->available, 2, "$label: idle";
  no_callback_died($label);
  $storage->disconnect;
}

# --- 3. the seam ------------------------------------------------------------------

# A connected stand-in the replay runs on, outside any pool.
sub connected_pg {
  my $pg = EV::Pg->new(conninfo => 'dbname=fake');
  delete $pg->{connecting};
  $pg->{up} = 1;
  return $pg;
}

{
  my ($storage, $owner) = storage_with_replay();

  my $pg  = connected_pg();
  my $err = do {
    my $delivering = $EVF->_delivering(K52::Delivering->new(2));
    eval { $storage->_run_pool_connect_statement($pg, $REPLAY, undef); 1 } ? '' : $@;
  };
  like $err, $REFUSED, 'seam: refused on entry while a delivering connection has more due';
  is_deeply $EV::Pg::WIRE{ $pg->{id} } // [], [], 'seam: before anything is sent';

  $pg  = connected_pg();
  $err = do {
    my $delivering = $EVF->_delivering(K52::Delivering->new(1));
    eval { $storage->_run_pool_connect_statement($pg, $REPLAY, undef); 1 } ? '' : $@;
  };
  is $err, '', 'seam: allowed while the delivering connection has nothing more due';
  is_deeply $EV::Pg::WIRE{ $pg->{id} }, [ $REPLAY ], 'seam: and the statement ran';

  # The result becomes due while the replay waits for its own.
  local $EV::Pg::DELAY = 0.05;
  $pg = connected_pg();
  my $due = K52::Delivering->new(1);
  EV::now_update();
  my $bump = EV::timer(0.01, 0, sub { $due->{pending} = 2 });
  $err = do {
    my $delivering = $EVF->_delivering($due);
    eval { $storage->_run_pool_connect_statement($pg, $REPLAY, undef); 1 } ? '' : $@;
  };
  like $err, $REFUSED, 'seam: refused before the next iteration once a result becomes due';
  $storage->disconnect;
}

no_callback_died('seam');

done_testing;
