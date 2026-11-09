use strict;
use warnings;
use Test::More;

use DBIO::Test::Future ();
use DBIO::Storage::PoolBase;

# karr k241, ADR 0047 addendum 2026-09-27. A connection whose server session
# ended while it sat idle in the pool -- server restart, idle timeout, an
# administrator's kill -- was handed out unchecked: the caller's query failed,
# and only that failure reported it dead (_mark_connection_dead, k230). After a
# server restart every idle connection is dead, so the pool failed one call per
# idle connection before it recovered.
#
# The seam this file pins is PoolBase::_idle_connection_alive, asked about an
# idle connection before acquire hands it out. The claims:
#
#   * by default nothing is checked: an idle connection is reused as before;
#   * a connection the seam does not vouch for is never handed out: it is
#     retired (closed once, no longer counted) and the caller gets a fresh one;
#   * with every idle connection dead, ONE acquire clears them all and the
#     caller still gets a working connection -- not one failure per connection;
#   * a live idle connection behind a dead one is handed out, no spawn;
#   * a check that throws counts as not vouching, and its error reaches the
#     pool's on_error -- acquire itself still resolves;
#   * an on_error that dies reporting it is not swallowed: its death is warned,
#     with the error it was reporting, and acquire still resolves -- it never
#     throws (karr k252; before, the eval around on_error dropped both);
#   * the seam is asked about idle connections only, not about a fresh spawn
#     or a connection handed straight to a queued caller.
#
# THE SUBSTITUTIONS: fake connections whose 'alive' flag stands for the local
# state a transport would read; no event loop, no database.

{
  package K241::Conn;
  sub new { bless { id => $_[1], alive => 1 }, $_[0] }
}

# The default seam: no override.
{
  package K241::PlainPool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection { K241::Conn->new(++$_[0]->{_next_id}) }
  sub _shutdown_connection { push @{ $_[0]->{closed} }, $_[1]->{id} }
}

# A transport that can tell: it reads the connection's local state.
{
  package K241::CheckingPool;
  use base 'K241::PlainPool';

  sub _idle_connection_alive {
    my ($self, $conn) = @_;
    push @{ $self->{asked} }, $conn->{id};
    die "probe broke\n" if $conn->{probe_dies};
    return $conn->{alive};
  }
}

sub new_pool {
  my ($class, $size, @rest) = @_;
  return $class->new(
    conninfo     => 'fake',
    size         => $size,
    future_class => 'DBIO::Test::Future',
    @rest,
  );
}

# Check out $n connections and put them back, so they sit idle in id order.
sub fill_idle {
  my ($pool, $n) = @_;
  my @conns = map { $pool->acquire->get } 1 .. $n;
  $pool->release($_) for @conns;
  return @conns;
}

# ---------------------------------------------------------------------------
# Default: no check, idle connection reused.
# ---------------------------------------------------------------------------
{
  my $pool = new_pool('K241::PlainPool', 1);
  my ($conn) = fill_idle($pool, 1);
  $conn->{alive} = 0;   # nobody looks at it by default

  is $pool->acquire->get->{id}, 1, 'default: the idle connection is handed out, unchecked';
  is_deeply $pool->{closed} // [], [], 'default: nothing is retired';
}

# ---------------------------------------------------------------------------
# Died while idle: retired, and the caller gets a fresh connection.
# ---------------------------------------------------------------------------
{
  my $pool = new_pool('K241::CheckingPool', 1);
  my ($conn) = fill_idle($pool, 1);
  $conn->{alive} = 0;

  my $got = $pool->acquire;
  ok $got->is_ready, 'died idle: acquire resolves';
  is $got->get->{id}, 2, 'died idle: on a fresh connection, never the dead one';
  is_deeply $pool->{closed}, [ 1 ], 'died idle: the dead connection is closed once';
  is $pool->size, 1, 'died idle: the pool counts the fresh connection only';
}

# ---------------------------------------------------------------------------
# Server restart: every idle connection dead. One acquire clears them all.
# ---------------------------------------------------------------------------
{
  my $pool = new_pool('K241::CheckingPool', 3);
  my @conns = fill_idle($pool, 3);
  $_->{alive} = 0 for @conns;

  my $got = $pool->acquire;
  is $got->get->{id}, 4, 'all idle dead: the first acquire already gets a fresh connection';
  is_deeply $pool->{closed}, [ 1, 2, 3 ], 'all idle dead: each dead one retired, oldest first';
  is $pool->size, 1, 'all idle dead: only the fresh connection is counted';
  is $pool->available, 0, 'all idle dead: none of them is left idle';
}

# ---------------------------------------------------------------------------
# A live idle connection behind a dead one is handed out, no spawn.
# ---------------------------------------------------------------------------
{
  my $pool = new_pool('K241::CheckingPool', 3);
  my @conns = fill_idle($pool, 3);
  $conns[0]{alive} = 0;

  is $pool->acquire->get->{id}, 2, 'dead head: the next idle connection is handed out';
  is_deeply $pool->{closed}, [ 1 ], 'dead head: only the dead one is retired';
  is $pool->{_next_id}, 3, 'dead head: nothing is spawned while a live idle one is there';
  is $pool->available, 1, 'dead head: the third stays idle';
}

# ---------------------------------------------------------------------------
# A throwing check: not vouched for, error to on_error, acquire resolves.
# ---------------------------------------------------------------------------
{
  my @errors;
  my $pool = new_pool('K241::CheckingPool', 1, on_error => sub { push @errors, $_[0] });
  my ($conn) = fill_idle($pool, 1);
  $conn->{probe_dies} = 1;

  my $got = $pool->acquire;
  is $got->get->{id}, 2, 'throwing check: the caller gets a fresh connection';
  is_deeply $pool->{closed}, [ 1 ], 'throwing check: the connection it could not vouch for is retired';
  like $errors[0] // '', qr/liveness check failed: probe broke/,
    "throwing check: its error reaches the pool's on_error";
}

# ---------------------------------------------------------------------------
# A throwing check reported to an on_error that dies itself: warned, not
# swallowed; acquire still resolves on a fresh connection (karr k252).
# ---------------------------------------------------------------------------
{
  my @warned;
  local $SIG{__WARN__} = sub { push @warned, $_[0] };
  my $pool = new_pool('K241::CheckingPool', 1, on_error => sub { die "on_error gave up\n" });
  my ($conn) = fill_idle($pool, 1);
  $conn->{probe_dies} = 1;

  my $got = eval { $pool->acquire };
  ok $got && $got->is_ready, 'dying on_error: acquire still resolves, it does not throw'
    or diag $@;
  is $got && $got->get->{id}, 2, 'dying on_error: on a fresh connection';
  is_deeply $pool->{closed}, [ 1 ], 'dying on_error: the unvouched connection is still retired';
  is scalar(@warned), 1, 'dying on_error: one warning';
  like $warned[0] // '', qr/on_error died \(on_error gave up\)/,
    "dying on_error: it carries on_error's own error";
  like $warned[0] // '', qr/liveness check failed: probe broke/,
    '... and the error it was reporting';
}

# ---------------------------------------------------------------------------
# Asked about idle connections only.
# ---------------------------------------------------------------------------
{
  my $pool = new_pool('K241::CheckingPool', 1);

  my $first = $pool->acquire->get;
  is_deeply $pool->{asked} // [], [], 'not asked about a freshly spawned connection';

  my $waiter = $pool->acquire;
  $pool->release($first);
  ok $waiter->is_ready, 'the queued caller gets the released connection';
  is_deeply $pool->{asked} // [], [], 'not asked about a connection handed straight to a queued caller';

  $pool->release($waiter->get);
  $pool->acquire->get;
  is_deeply $pool->{asked}, [ 1 ], 'asked once, about the idle connection it hands out';
}

done_testing;
