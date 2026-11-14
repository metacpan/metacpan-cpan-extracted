use strict;
use warnings;
use Test::More;

use Scalar::Util ();
use DBIO::Storage::PoolBase;
use DBIO::Test::Future ();

# karr k256, for dbio-async k30 (ADR 0047 addendum 2026-09-28). A caller that
# finds every connection of the pool checked out is queued with a pending
# Future -- its waiter -- that the next release settles. Two things about that
# Future belong to the transport, and core gives it a seam for each:
#
#   * _new_waiter makes it. Every ->then off a pending Future is made with that
#     Future's own new, so the waiter's class is the class of everything the
#     caller builds on the wait, down to the Future a blocking call ->gets. A
#     plain Future knows no event loop: pending, ->get croaks "is not yet
#     complete and does not provide ->await". dbio-async had to switch the
#     whole pool's future_class and wrap _acquire_slot to reach the waiter.
#   * _withdraw_waiter takes it out of the queue, so no release hands it a
#     connection -- for a caller that gives up (dbio-async fails a blocking
#     wait that can never end). Cancelling the Future withdraws it by itself,
#     when its class can be cancelled.
#
# The claims: the seam is asked exactly when a caller is queued, and its answer
# is the queued Future, whose class the caller's Future takes on; a seam that
# dies or answers no pending Future fails the acquire, which never throws, and
# queues nothing; a withdrawn waiter is out of the queue, not settled, and no
# connection is lost -- the next caller or the idle list gets it; a cancelled
# one is withdrawn at once; and the cancel hook does not keep the pool alive.

{
  package K256::Conn;
  sub new { bless { id => $_[1] }, $_[0] }
}

{
  package K256::Pool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection   { K256::Conn->new(++$_[0]{n}) }
  sub _shutdown_connection { return }
}

# A transport's own waiter class: a subclass of the pool's Future class that
# records the pool it waits for, weakly -- what dbio-async's
# DBIO::Async::Future carries so a blocking ->get can ask the pool about it.
{
  package K256::TestWaiter;
  our @ISA = ('DBIO::Test::Future');
}

# set_udata/udata on real Futures need Future 0.50 or newer.
my $have_future = eval { require Future; Future->VERSION('0.50'); 1 };
if ($have_future) {
  package K256::FutureWaiter;
  our @ISA = ('Future');
}

{
  package K256::WaiterPool;
  use base 'K256::Pool';
  sub _new_waiter {
    my ($self) = @_;
    $self->{asked}++;
    my $class = $self->future_class eq 'Future'
      ? 'K256::FutureWaiter' : 'K256::TestWaiter';
    my $waiter = $class->new;
    # Laid on the Future through udata, which Future::XS objects (no hashes)
    # have as well; in a box, as a copy of a weak reference is a strong one.
    my $box = \(my $pool = $self);
    Scalar::Util::weaken($$box);
    $waiter->set_udata(pool => $box);
    return $waiter;
  }
}

{
  package K256::BadWaiterPool;
  use base 'K256::Pool';
  sub _new_waiter { $_[0]->{answer}->($_[0]) }
}

sub new_pool {
  my ($class, $fc, %args) = @_;
  my $pool = $class->new(conninfo => 'x', size => 1, future_class => $fc);
  $pool->{$_} = $args{$_} for keys %args;
  return $pool;
}

# Did $f resolve with a value -- not pending, not failed, not cancelled?
sub resolved {
  my ($f) = @_;
  return 0 unless $f->is_ready && !$f->is_failed;
  return 0 if $f->can('is_cancelled') && $f->is_cancelled;
  return 1;
}

sub resolved_id { resolved($_[0]) ? $_[0]->get->{id} : undef }

# The error $f failed with, or undef. DBIO::Test::Future has no ->failure, so
# read it the way ->get throws it.
sub failure {
  my ($f) = @_;
  return undef unless $f->is_failed;
  return ($f->failure)[0] if $f->can('failure');
  eval { $f->get };
  return "$@";
}

my @future_classes = ('DBIO::Test::Future');
push @future_classes, 'Future' if $have_future;
note 'Future.pm 0.50 or newer not installed: checked with DBIO::Test::Future only'
  unless $have_future;


for my $fc (@future_classes) {
  my $waiter_class = $fc eq 'Future' ? 'K256::FutureWaiter' : 'K256::TestWaiter';

  # -------------------------------------------------------------------------
  # The default seam: a pending Future of the pool's future_class, and it is
  # what the queue holds.
  # -------------------------------------------------------------------------
  {
    my $pool = new_pool('K256::Pool', $fc);
    my $w = $pool->_new_waiter;
    ok !$w->is_ready, "$fc, default _new_waiter: a pending Future";
    is ref $w, $fc, "$fc, default _new_waiter: of the pool's future_class";

    my $held = $pool->acquire->get;
    my $queued = $pool->_acquire_slot;
    is ref $pool->{_waiters}[0], $fc, "$fc, default: the queued waiter is of the future_class";
    is Scalar::Util::refaddr($queued), Scalar::Util::refaddr($pool->{_waiters}[0]),
      "$fc, default: _acquire_slot hands out the very Future it queued";
  }

  # -------------------------------------------------------------------------
  # An overriding seam: asked only when a caller is queued, its Future is the
  # one queued and handed out, the caller's acquire Future takes on its class,
  # and release settles it like any other waiter.
  # -------------------------------------------------------------------------
  {
    my $pool = new_pool('K256::WaiterPool', $fc);
    my $held = $pool->acquire;
    ok !$pool->{asked}, "$fc, override: not asked when there is room to spawn";

    my $slot = $pool->_acquire_slot;
    is $pool->{asked}, 1, "$fc, override: asked once when a caller is queued";
    isa_ok $slot, $waiter_class, "$fc, override: the queued Future";
    is Scalar::Util::refaddr($slot), Scalar::Util::refaddr($pool->{_waiters}[0]),
      "$fc, override: it is the one in the queue";
    is Scalar::Util::refaddr(${ $slot->udata('pool') }), Scalar::Util::refaddr($pool),
      "$fc, override: carrying what the transport marked it with";

    my $caller = $pool->acquire;
    isa_ok $caller, $waiter_class,
      "$fc, override: the Future a queued acquire returns (chained off the waiter)";

    $pool->release($held->get);
    is resolved_id($slot), 1, "$fc, override: release hands the connection to the transport's waiter";
    $pool->release($slot->get);
    is resolved_id($caller), 1, "$fc, override: and to the next one behind it";

    $pool->release($caller->get);
    my $again = $pool->acquire;
    is $pool->{asked}, 2, "$fc, override: an idle connection is handed out without asking";
    ok resolved($again), "$fc, override: at once";
  }

  # -------------------------------------------------------------------------
  # A seam that dies, or answers no pending Future: acquire does not throw,
  # it fails naming the seam, and nothing is queued.
  # -------------------------------------------------------------------------
  {
    my %answers = (
      'dies'                    => [ sub { die "no waiter today\n" }, qr/no waiter today/ ],
      'returns undef'           => [ sub { undef }, qr/K256::BadWaiterPool->_new_waiter returned undef, not a Future/ ],
      'returns a plain value'   => [ sub { 42 }, qr/K256::BadWaiterPool->_new_waiter returned no Future/ ],
      'returns a ready Future'  => [ sub { $_[0]->future_class->done('x') },
                                     qr/K256::BadWaiterPool->_new_waiter returned a Future that is not pending/ ],
    );
    for my $case (sort keys %answers) {
      my ($answer, $error) = @{ $answers{$case} };
      my $pool = new_pool('K256::BadWaiterPool', $fc, answer => $answer);
      my $held = $pool->acquire->get;

      my $f;
      ok eval { $f = $pool->acquire; 1 }, "$fc, seam $case: acquire does not throw"
        or diag $@;
      ok $f && $f->is_failed, "$fc, seam $case: it returns a failed Future";
      like failure($f) // '', $error, "$fc, seam $case: naming what went wrong";
      is scalar @{ $pool->{_waiters} }, 0, "$fc, seam $case: nothing is queued";

      $pool->release($held);
      is $pool->available, 1, "$fc, seam $case: the connection goes back idle on release";
    }
  }

  # -------------------------------------------------------------------------
  # _withdraw_waiter: out of the queue, not settled, and no connection lost --
  # the next caller gets it, or the idle list when there is none.
  # -------------------------------------------------------------------------
  {
    my $pool = new_pool('K256::Pool', $fc);
    my $conn = $pool->acquire->get;
    my $gone = $pool->_acquire_slot;
    my $next = $pool->acquire;

    is $pool->_withdraw_waiter($gone), 1, "$fc, withdraw: answers true for a queued waiter";
    is scalar @{ $pool->{_waiters} }, 1, "$fc, withdraw: it is out of the queue";
    ok !$gone->is_ready, "$fc, withdraw: and not settled -- that is the caller's";
    is $pool->_withdraw_waiter($gone), 0, "$fc, withdraw: answers false the second time";

    $pool->release($conn);
    ok !$gone->is_ready, "$fc, withdraw: release does not hand it the connection";
    is resolved_id($next), 1, "$fc, withdraw: the caller behind it gets it";
    is $pool->_withdraw_waiter($next), 0,
      "$fc, withdraw: answers false for a waiter already handed a connection";
  }

  {
    my $pool = new_pool('K256::Pool', $fc);
    my $conn = $pool->acquire->get;
    my $gone = $pool->_acquire_slot;
    my $caller_f = $gone->then(sub { $fc->done(@_) });

    # The pattern for a transport that refuses a wait: withdraw, then fail.
    $pool->_withdraw_waiter($gone);
    $gone->fail("refused: nothing can come free\n");
    like failure($caller_f) // '', qr/refused: nothing can come free/,
      "$fc, withdraw then fail: the caller gets the transport's reason";

    $pool->release($conn);
    is $pool->available, 1, "$fc, withdraw then fail: the connection goes back idle";
    is resolved_id($pool->acquire), 1, "$fc, withdraw then fail: and the next acquire resolves at once";
  }
}

# ---------------------------------------------------------------------------
# Cancel: a Future class that can be cancelled has its waiter withdrawn the
# moment the caller cancels -- the caller's own Future, as Future.pm carries
# the cancel down the ->then chain to the waiter. Future.pm only:
# DBIO::Test::Future cannot be cancelled.
# ---------------------------------------------------------------------------
SKIP: {
  skip 'Future.pm not installed', 11 unless $have_future;

  for my $class ('K256::Pool', 'K256::WaiterPool') {
    my $pool = new_pool($class, 'Future');
    my $conn = $pool->acquire->get;
    my $caller = $pool->acquire;
    is scalar @{ $pool->{_waiters} }, 1, "$class, cancel: the caller is queued";

    $caller->cancel;
    is scalar @{ $pool->{_waiters} }, 0,
      "$class, cancel: cancelling the caller's Future withdraws its waiter at once";

    $pool->release($conn);
    is $pool->available, 1, "$class, cancel: the connection goes back idle on release";
    is resolved_id($pool->acquire), 1, "$class, cancel: and the next acquire resolves at once";
  }

  # Cancelling a caller already served changes nothing in the queue.
  {
    my $pool = new_pool('K256::Pool', 'Future');
    my $conn = $pool->acquire->get;
    my $first  = $pool->acquire;
    my $second = $pool->acquire;
    $pool->release($conn);
    ok resolved($first), 'cancel after service: the first caller was served';
    $first->cancel;
    is scalar @{ $pool->{_waiters} }, 1, 'cancel after service: the other caller is still queued';
  }

  # The cancel hook holds the pool weakly: whoever holds a queued waiter does
  # not keep the pool alive through the hook, and the pool's teardown fails the
  # waiter. Taken at the raw waiter from _acquire_slot, not through acquire:
  # acquire's own ->then callback holds the pool until the waiter settles, which
  # is the chain's business, not the hook's.
  {
    my $pool = new_pool('K256::Pool', 'Future');
    my $conn   = $pool->acquire->get;
    my $waiter = $pool->_acquire_slot;
    Scalar::Util::weaken(my $weak = $pool);
    undef $pool;
    ok !defined $weak, 'cancel hook: a queued waiter does not keep the pool alive';
    ok $waiter->is_failed, 'cancel hook: the pool\'s teardown fails the waiter';
  }
}

done_testing;
