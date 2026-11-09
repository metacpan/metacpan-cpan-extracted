use strict;
use warnings;
use Test::More;

use DBIO::Storage::PoolBase;
use DBIO::Test::Future ();

# karr k255, found in dbio-async (its k29, the TODO in its t/25 section 6).
# A caller queued for a busy pool may stop waiting before a connection comes
# free: it cancels the Future it holds (Future.pm propagates the cancel down the
# ->then chain to the pool's waiter), or its waiter is settled from outside --
# dbio-async fails a blocking wait that can never end. release and
# _retire_in_use_connection handed the freed connection to the head of the
# queue whatever that waiter's state:
#
#   * a cancelled Future.pm ignores ->done, so the connection went nowhere --
#     neither idle nor borrowed, still counted against max_size. In a pool of
#     one every later acquire queued behind it and hung for good;
#   * a waiter already settled refuses ->done: release itself died (Future.pm
#     "already failed and cannot be ->done", DBIO::Test::Future "already
#     settled");
#   * _retire_in_use_connection spawned a fresh connection for such a waiter
#     and lost that one the same way.
#
# The claims, for a pool of one: a freed connection goes to the next caller
# still waiting, or back to idle when none is; release does not die; and the
# next acquire resolves at once. Every scenario runs against DBIO::Test::Future
# and, when installed, Future.pm; a cancel only against Future.pm, since
# DBIO::Test::Future has no cancel.

{
  package K255::Conn;
  sub new { bless { id => $_[1] }, $_[0] }
}

{
  package K255::Pool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection   { K255::Conn->new(++$_[0]{n}) }
  sub _shutdown_connection { push @{ $_[0]{closed} }, $_[1]{id} }
}

sub new_pool {
  my ($fc) = @_;
  return K255::Pool->new(conninfo => 'x', size => 1, future_class => $fc);
}

# A caller that stopped waiting, the way $how says. Returns what the caller
# held, which the test keeps alive to the end of the scenario.
sub dead_waiter {
  my ($pool, $how) = @_;
  if ($how eq 'cancelled') {
    my $f = $pool->acquire;
    $f->cancel;
    return $f;
  }
  # Settled from outside: the pool's own waiter, failed by somebody else.
  my $w = $pool->_acquire_slot;
  $w->fail("gave up waiting\n");
  return $w;
}

# Did $f resolve with a value -- not pending, not failed, not cancelled?
sub resolved {
  my ($f) = @_;
  return 0 unless $f->is_ready && !$f->is_failed;
  return 0 if $f->can('is_cancelled') && $f->is_cancelled;
  return 1;
}

# The id of the connection $f resolved with, or undef.
sub resolved_id { resolved($_[0]) ? $_[0]->get->{id} : undef }

my @future_classes = ('DBIO::Test::Future');
push @future_classes, 'Future' if eval { require Future; 1 };
note 'Future.pm not installed: checked with DBIO::Test::Future only'
  if @future_classes == 1;

for my $fc (@future_classes) {
  my @hows = ('failed from outside');
  unshift @hows, 'cancelled' if $fc->can('cancel');

  for my $how (@hows) {
    my $label = "$fc, waiter $how";

    # -----------------------------------------------------------------------
    # release: the dead waiter is skipped, the live one behind it gets the
    # connection -- the same one, no second connection.
    # -----------------------------------------------------------------------
    {
      my $pool = new_pool($fc);
      my $conn = $pool->acquire->get;
      my $dead = dead_waiter($pool, $how);
      my $live = $pool->acquire;
      ok !$live->is_ready, "$label: a second caller is queued behind it";

      ok eval { $pool->release($conn); 1 }, "$label: release does not die"
        or diag $@;
      ok resolved($live), "$label: the caller still waiting gets the connection";
      is resolved_id($live), 1, "$label: the one released, not a new one";
      is $pool->size, 1, "$label: the pool still holds one connection";
      is $pool->available, 0, "$label: it is borrowed, not idle";
    }

    # -----------------------------------------------------------------------
    # release with nobody left waiting: the connection goes back to idle, and
    # the next acquire in the pool of one resolves at once, on it.
    # -----------------------------------------------------------------------
    {
      my $pool = new_pool($fc);
      my $conn = $pool->acquire->get;
      my $dead = dead_waiter($pool, $how);

      ok eval { $pool->release($conn); 1 }, "$label, nobody else waiting: release does not die"
        or diag $@;
      is $pool->available, 1, "$label, nobody else waiting: the connection is idle again";

      my $next = $pool->acquire;
      ok resolved($next), "$label, nobody else waiting: the next acquire resolves at once";
      is resolved_id($next), 1,
        "$label, nobody else waiting: on the released connection";
      is $pool->size, 1, "$label, nobody else waiting: no second connection was spawned";
    }

    # -----------------------------------------------------------------------
    # _retire_in_use_connection: the replacement goes to the live waiter
    # behind the dead one.
    # -----------------------------------------------------------------------
    {
      my $pool = new_pool($fc);
      my $conn = $pool->acquire->get;
      my $dead = dead_waiter($pool, $how);
      my $live = $pool->acquire;

      $pool->_retire_in_use_connection($conn);
      ok resolved($live), "$label, retired: the caller still waiting gets a connection";
      is resolved_id($live), 2, "$label, retired: a freshly spawned one";
      is $pool->size, 1, "$label, retired: the pool holds exactly that one";
    }

    # -----------------------------------------------------------------------
    # _retire_in_use_connection with nobody left waiting: nothing is spawned
    # for the dead waiter, and the next acquire spawns on demand.
    # -----------------------------------------------------------------------
    {
      my $pool = new_pool($fc);
      my $conn = $pool->acquire->get;
      my $dead = dead_waiter($pool, $how);

      $pool->_retire_in_use_connection($conn);
      is $pool->size, 0, "$label, retired, nobody else waiting: nothing is spawned for it";

      my $next = $pool->acquire;
      ok resolved($next), "$label, retired, nobody else waiting: the next acquire resolves at once";
      is resolved_id($next), 2,
        "$label, retired, nobody else waiting: on a fresh connection";
    }
  }

  # -------------------------------------------------------------------------
  # Several dead waiters in a row, cancelled and settled mixed: all are
  # skipped, in queue order, and the first live one gets the connection.
  # -------------------------------------------------------------------------
  {
    my $pool = new_pool($fc);
    my $conn = $pool->acquire->get;
    my @dead = map { dead_waiter($pool, $_) }
      $fc->can('cancel') ? ('cancelled', 'failed', 'cancelled') : ('failed', 'failed');
    my $first  = $pool->acquire;
    my $second = $pool->acquire;

    $pool->release($conn);
    ok resolved($first), "$fc, several dead waiters: the first live caller gets the connection";
    ok !$second->is_ready, "$fc, several dead waiters: the one behind it keeps waiting";

    $pool->release($first->get);
    ok resolved($second), "$fc, several dead waiters: and gets it on the next release";
  }
}

done_testing;
