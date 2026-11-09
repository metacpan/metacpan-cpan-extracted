use strict;
use warnings;
use Test::More;

# OFFLINE regression for karr k50: a pooled query whose Future has a callback
# that dies still gives its connection back to the pool.
#
# WHY: _dispatch_query's completion callback settled the Future and only then
# released the connection. Future runs on_done / on_ready / on_fail callbacks
# without catching a die (then does catch, and turns it into a failed Future),
# so a dying one escaped $f->done / $f->fail, EV::Pg caught it with a warning,
# and the release after it never ran: the connection stayed checked out for
# good, and a pool of N was wedged after N of them. The callback may sit on the
# Future the caller holds -- select_async(...)->on_done(...) -- since the die
# climbs the then chain up to the settle.
#
# What this file claims:
#   a. a pooled query whose Future's on_done, on_ready or on_fail dies still
#      settles with its own result or error -- the die does not change it;
#   b. its connection is back in the pool, once, and the next acquire on that
#      pool of one resolves -- the next query completes on it;
#   c. the die is not swallowed: it still reaches EV::Pg, which warns it, once.
# And two properties the fix must keep (ADR 0001 addendum, karr k44), both
# green before and after:
#   d. a then callback on the Future still runs while its connection is
#      checked out: a call it makes gets another connection, never the one
#      whose result is being delivered (DBIO::PostgreSQL::EV::Future/await);
#   e. the release still happens inside the delivery frame: a caller waiting
#      for the connection gets it while its callback is still running, and a
#      blocking wait there is refused rather than left to spin in EV::Pg.
#
# Without the fix b fails for all three callbacks: nothing is idle, and the
# next acquire waits for a connection nobody returns. That wait is bounded --
# the EV Future dies when nothing left in the loop could settle it (karr k44),
# and a keepalive(0) watchdog fails it should something keep the loop alive --
# so the regression shows as a failure, not a hang.
#
# DyingCbPg stands in for EV::Pg in the order it does things: connect
# completes on an EV timer; each queued callback completes on an EV timer,
# counted as pending until it has returned, and is called under an eval that
# only warns, as EV::Pg's CALL_SV_GUARDED does (0.02 and 0.07 alike).

use EV;
use DBIO::PostgreSQL::EV::Storage;

# These tests are not about the session reset of a pool connection (karr k99):
# NoSessionReset puts the connection back at once, as before the reset existed.
use FindBin;
use lib "$FindBin::Bin/lib";
use NoSessionReset;
use DBIO::PostgreSQL::EV::Pool;
use DBIO::PostgreSQL::EV::Future;

{
  package DyingCbPg;
  use Scalar::Util ();

  # The next statement fails with this server error, once.
  our $FAIL_NEXT;

  sub new {
    my ($class, %args) = @_;
    my $self = bless { %args, up => 0, queue => [], extra => 0 }, $class;
    Scalar::Util::weaken(my $weak = $self);
    my $t;
    $t = EV::timer(0.001, 0, sub {
      undef $t;
      return unless $weak;
      $weak->{up} = 1;
      $weak->{on_connect}->() if $weak->{on_connect};
    });
    return $self;
  }

  sub is_connected  { $_[0]{up} }
  sub pending_count { scalar(@{ $_[0]{queue} }) + $_[0]{extra} }
  sub socket        { -1 }   # no socket for the pool to look at (karr k72)
  sub finish        { $_[0]{up} = 0; $_[0]{queue} = []; return }

  sub query_params {
    my ($self, $sql, $bind, $cb) = @_;
    push @{ $self->{queue} }, $cb;
    $self->_arm;
    return;
  }

  sub _arm {
    my $self = shift;
    return if $self->{timer} || !@{ $self->{queue} };
    Scalar::Util::weaken(my $weak = $self);
    $self->{timer} = EV::timer(0.001, 0, sub { $weak->_complete_head if $weak });
    return;
  }

  sub _complete_head {
    my $self = shift;
    delete $self->{timer};
    my $cb = $self->{queue}[0] or return;
    my $fail = $FAIL_NEXT;
    undef $FAIL_NEXT;
    my @result = defined $fail ? (undef, $fail) : ([ [ 1, 'one' ] ]);
    eval { $cb->(@result); 1 } or warn "EV::Pg: exception in callback: $@";
    shift @{ $self->{queue} };   # advanced only after the callback returned
    $self->_arm;
    return;
  }
}

# The real pool builds its handles through this seam (t/04).
{
  no warnings 'redefine';
  *DBIO::PostgreSQL::EV::Pool::_new_connection = sub { shift; DyingCbPg->new(@_) };
}

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

my $EVF     = 'DBIO::PostgreSQL::EV::Future';
my @SELECT  = ('thing', [qw( id name )], {});
my $REFUSED = qr/^Blocking wait refused/;

# A real storage and pool over DyingCbPg, with a pool of one.
sub pool_of_one {
  my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
  $storage->connect_info([ { dbname => 'fake', pool_size => 1 }, {} ]);
  return $storage;
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

# Let every timer DyingCbPg still has run out, so a callback that would fire
# late -- and release a second time -- has fired before the pool is counted.
sub settle {
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.05, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

# Spawn the pool's one connection and wait until it is up.
sub warm {
  my ($storage) = @_;
  my ($up) = wait_for($storage->select_async(@SELECT));
  @warnings = ();
  return $up;
}

# --- a, b, c: a callback on the query's Future dies -----------------------------

my $SERVER_ERROR = "ERROR:  relation \"thing\" does not exist\n";

for my $case (
  [ on_done  => undef,         1, [ [ 1, 'one' ] ] ],
  [ on_ready => undef,         1, [ [ 1, 'one' ] ] ],
  [ on_fail  => $SERVER_ERROR, 0, [ $SERVER_ERROR ] ],
) {
  my ($method, $fail, $expect_ok, $expect) = @$case;
  my $label = "select_async, its $method dies";

  my $storage = pool_of_one();
  ok warm($storage), "$label: the connection is up";
  my $pool = $storage->pool;

  local $DyingCbPg::FAIL_NEXT = $fail;
  my $f = $storage->select_async(@SELECT);
  $f->$method(sub { die "$method died\n" });

  my ($ok, @r) = wait_for($f);
  is !!$ok, !!$expect_ok, "$label: the query " . ($expect_ok ? 'resolves' : 'fails');
  is_deeply \@r, $expect, "$label: with its own " . ($expect_ok ? 'rows' : 'error');
  settle();

  is $pool->available, 1, "$label: its connection is back in the pool, once";
  is $pool->size, 1, "$label: the pool still has its one connection";

  my @died = grep { /exception in callback/ } @warnings;
  is scalar @died, 1, "$label: the die still reaches EV::Pg, once";
  like $died[0] // '', qr/: \Q$method\E died$/, "$label: unchanged";
  @warnings = ();

  my ($next_ok, @next) = wait_for($storage->select_async(@SELECT));
  ok $next_ok, "$label: the next query on the pool of one gets the connection"
    or diag "it failed: $next[0]";
  is_deeply \@next, [ [ 1, 'one' ] ], "$label: and completes";
  settle();
  is $pool->available, 1, "$label: which it gives back";
  is scalar(@warnings), 0, "$label: without a warning" or diag @warnings;
  @warnings = ();
}

# --- d: a then callback runs while the connection is still checked out ----------

{
  my $storage = pool_of_one();
  ok warm($storage), 'then: the connection is up';
  my $pool = $storage->pool;

  my $available;
  my ($ok) = wait_for($storage->select_async(@SELECT)->then(sub {
    $available = $pool->available;
    return $EVF->done(@_);
  }));
  ok $ok, 'then: the chain resolves';
  is $available, 0, 'then: its callback runs while the connection is still checked out';
  settle();
  is $pool->available, 1, 'then: which comes back after it';
}

# --- e: the release hands the connection on inside the delivery frame -----------
#
# A caller already waiting for the pool's one connection gets it from the
# release, synchronously. One more result due on it, a blocking wait there must
# be refused: EV::Pg is still delivering the first query's result.

{
  my $storage = pool_of_one();
  ok warm($storage), 'frame: the connection is up';
  my $pool = $storage->pool;

  my $first = $storage->select_async(@SELECT);   # takes the one connection
  my $err;
  my $waiter = $pool->acquire->then(sub {        # and waits for it
    my ($conn) = @_;
    $conn->{extra} = 1;
    my $never = $EVF->new;
    my $t = EV::timer(5, 0, sub { $never->done });
    $t->keepalive(0);
    $err = eval { $never->get; 1 } ? 'waited' : $@;
    $conn->{extra} = 0;
    $pool->release($conn);
    return $EVF->done;
  });

  my ($first_ok) = wait_for($first);
  ok $first_ok, 'frame: the first query resolves';
  my ($waiter_ok, @w) = wait_for($waiter);
  ok $waiter_ok, 'frame: the waiting caller gets the connection' or diag "it failed: $w[0]";
  like $err // '', $REFUSED, 'frame: while the first result is still being delivered';
  settle();
  is $pool->available, 1, 'frame: and the pool is idle again';
}

done_testing;
