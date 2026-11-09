use strict;
use warnings;
use Test::More;

# ADR 0030 section 4: DBIO::Test::AsyncHarness, the parameterised
# live-harness base that replaces the two near-identical copies in
# dbio-postgresql-ev and dbio-mysql-ev.
#
# This file is OFFLINE and stays offline. The harness is a LIVE tool, so what
# core can and must pin here is everything AROUND the connection: that the four
# declarations parameterise it, that an undeclared subclass says which
# declaration it forgot instead of failing somewhere downstream, that the
# live gate reads the right environment variable and the right modules, that
# await neither hangs nor leaves an alarm armed, and that _tick_loop is only
# demanded when a Future is actually not ready. No DSN is set, nothing connects.

use DBIO::Test::AsyncHarness;

# A fully declared subclass -- the shape a transport dist reduces to.
{
  package T::AH::Full;
  use base 'DBIO::Test::AsyncHarness';
  __PACKAGE__->harness_env_prefix('DBIO_TEST_FAKE');
  __PACKAGE__->harness_async_mode('ev');
  __PACKAGE__->harness_required_modules([qw( No::Such::Transport::Module )]);
  __PACKAGE__->harness_schema_class('T::AH::Schema');

  our $ticks = 0;
  sub _tick_loop { $ticks++ }

  # A subclass that declares nothing.
  package T::AH::Bare;
  use base 'DBIO::Test::AsyncHarness';

  # A subclass with no event loop at all (the 'immediate'/'forked' shape).
  package T::AH::NoLoop;
  use base 'DBIO::Test::AsyncHarness';
  __PACKAGE__->harness_env_prefix('DBIO_TEST_FAKE');
  __PACKAGE__->harness_async_mode('immediate');
  __PACKAGE__->harness_schema_class('T::AH::Schema');
}

# A minimal hand-rolled Future stand-in: this test must not depend on Future
# being installed (it is a `suggests`), and await only ever asks is_ready/get.
{
  package T::AH::Future;
  sub new    { bless { ready => $_[1], value => $_[2] }, $_[0] }
  sub ready_after {
    my ($class, $n, $value) = @_;
    return bless { countdown => $n, value => $value }, $class;
  }
  sub is_ready {
    my $self = shift;
    return 1 if $self->{ready};
    return 0 if !defined $self->{countdown};
    return $self->{ready} = 1 if $self->{countdown}-- <= 0;
    return 0;
  }
  sub get { $_[0]->{value} }
}

# ---------------------------------------------------------------------------
# 1. The declarations parameterise the harness.
# ---------------------------------------------------------------------------
is( T::AH::Full->env_var('DSN'), 'DBIO_TEST_FAKE_DSN',
  'env_var composes the DSN name from the declared prefix' );
is( T::AH::Full->env_var('USER'), 'DBIO_TEST_FAKE_USER',
  'env_var composes the USER name too' );
is( T::AH::Full->harness_async_mode, 'ev', 'the async mode is class data' );
is_deeply( T::AH::Full->harness_required_modules, ['No::Such::Transport::Module'],
  'the required-module list is class data' );
is( T::AH::Full->harness_default_timeout, 30,
  'the default timeout is inherited from the base' );
is_deeply( T::AH::NoLoop->harness_required_modules, [],
  'a subclass that names no modules inherits an empty list, not undef' );

# ---------------------------------------------------------------------------
# 2. An undeclared subclass names the declaration it is missing. The whole
#    point of the parameterisation is that a copy-paste dist gets told what to
#    fill in, rather than an undef reaching %ENV or ->connect.
# ---------------------------------------------------------------------------
{
  eval { T::AH::Bare->env_var('DSN') };
  like $@, qr/T::AH::Bare must declare harness_env_prefix/,
    'a missing env prefix is reported by name, against the subclass';

  eval { T::AH::Bare->_harness_declaration('harness_schema_class') };
  like $@, qr/T::AH::Bare must declare harness_schema_class/,
    'so is a missing schema class';
}

# ---------------------------------------------------------------------------
# 3. The live gate: the DSN variable AND every required module.
# ---------------------------------------------------------------------------
{
  local %ENV = %ENV;
  delete $ENV{DBIO_TEST_FAKE_DSN};
  ok !T::AH::Full->live_available, 'not live without the DSN variable';

  $ENV{DBIO_TEST_FAKE_DSN} = 'dbi:Fake:';
  ok !T::AH::Full->live_available,
    'still not live with the DSN set but the transport module missing';

  # Same environment, no required modules declared -> the DSN alone is enough.
  ok( T::AH::NoLoop->live_available,
    'a transport needing no extra module is live on the DSN alone' );

  eval { T::AH::Full->new };
  like $@, qr/DBIO_TEST_FAKE_DSN is unset or the transport is missing/,
    'new refuses when the harness is not live';
  like $@, qr/gate with skip_all_unless_live/, 'and points at the gate to use';
}

# ---------------------------------------------------------------------------
# 4. await: ready-at-once needs no loop; a pending Future turns the loop until
#    it is ready; the alarm is disarmed on every exit path.
# ---------------------------------------------------------------------------
{
  local $T::AH::Full::ticks = 0;
  my $h = bless {}, 'T::AH::Full';

  my $done = T::AH::Future->new(1, 'value');
  is $h->await($done), 'value', 'await returns an already-ready Future value';
  is $T::AH::Full::ticks, 0, 'and never turned the loop for it';

  # ready_after(3): is_ready answers false three times, then true. `until`
  # tests before each iteration, so the loop turns exactly three times.
  my $later = T::AH::Future->ready_after(3, 'eventually');
  is $h->await($later), 'eventually', 'await drives the loop until the Future is ready';
  is $T::AH::Full::ticks, 3, 'the loop ran once per not-ready answer, and stopped there';
  is alarm(0), 0, 'await left no alarm armed';
}

# ---------------------------------------------------------------------------
# 5. A Future that never becomes ready fails on the timeout instead of hanging
#    -- and STILL leaves no alarm armed. An alarm surviving a die would kill
#    the process later, under the restored default handler, far from here.
# ---------------------------------------------------------------------------
{
  my $h = bless { timeout => 1 }, 'T::AH::Full';
  my $never = T::AH::Future->new(0);

  eval { $h->await($never) };
  like $@, qr/TIMEOUT awaiting Future/, 'a Future that never resolves times out loudly';
  is alarm(0), 0, 'and the alarm was disarmed even though await died';
}

# ---------------------------------------------------------------------------
# 6. _tick_loop is demanded only when it is actually needed, and says so by
#    name when it is missing.
# ---------------------------------------------------------------------------
{
  my $h = bless {}, 'T::AH::NoLoop';

  is $h->await(T::AH::Future->new(1, 'sync')), 'sync',
    'a transport with no event loop can await an already-resolved Future';

  eval { $h->await(T::AH::Future->new(0)) };
  like $@, qr/T::AH::NoLoop must override _tick_loop/,
    'and is told exactly what to supply when a Future is not ready';
}

# ---------------------------------------------------------------------------
# 7. timeout: instance option beats class default, class default is the
#    fallback.
# ---------------------------------------------------------------------------
{
  is +(bless {}, 'T::AH::Full')->timeout, 30, 'timeout falls back to the class default';
  is +(bless { timeout => 5 }, 'T::AH::Full')->timeout, 5,
    'a per-instance timeout wins';

  T::AH::NoLoop->harness_default_timeout(7);
  is +(bless {}, 'T::AH::NoLoop')->timeout, 7,
    'a subclass may raise the class default';
  is( T::AH::Full->harness_default_timeout, 30,
    'without disturbing its siblings (inherited class data, not global)' );
}

# ---------------------------------------------------------------------------
# 8. run_on_each_pooled_connection guards its own contract before touching a
#    pool: a non-coderef, and a request for more connections than the pool can
#    hold.
# ---------------------------------------------------------------------------
{
  package T::AH::Pool;
  sub new      { bless { max => $_[1] }, $_[0] }
  sub max_size { $_[0]->{max} }

  package T::AH::Pooled;
  use base 'T::AH::Full';
  sub pool { $_[0]->{pool} }
}
{
  my $h = bless { pool => T::AH::Pool->new(2) }, 'T::AH::Pooled';

  eval { $h->run_on_each_pooled_connection(2, 'not a coderef') };
  like $@, qr/\$code must be a coderef/, 'the callback must be a coderef';

  eval { $h->run_on_each_pooled_connection(5, sub { }) };
  like $@, qr/pool max_size \(2\) is smaller than the requested 5/,
    'asking for more connections than the pool can hold is refused up front';
  like $@, qr/raise pool_size in connect_attrs/, 'and says how to fix it';
}

# storage_type names the driver for a schema class that declares none
# (ADR 0067 §4): the harness connects a clone declaring it and leaves the
# shared class undeclared. The driver here is the fake DBIO::Test::Storage,
# which opens nothing.
{
  package T::AH::Gated;
  use base 'T::AH::Full';
  sub live_available { 1 }
}
{
  require DBIO::Test::Schema;
  require DBIO::Test::Storage;
  my %opts = (
    schema_class => 'DBIO::Test::Schema',
    dsn          => 'dbi:DBIO:test:harness',
  );

  eval { T::AH::Gated->new(%opts) };
  like $@, qr/Schema class DBIO::Test::Schema declares no driver/,
    'without storage_type the driverless schema class is refused by core';

  my $h = T::AH::Gated->new(%opts, storage_type => 'DBIO::Test::Storage');
  ok ref $h->schema, 'with storage_type the harness schema is an instance (a clone)';
  isa_ok $h->sync_storage, 'DBIO::Test::Storage', 'its storage, the declared driver';
  is $h->{storage_type}, 'DBIO::Test::Storage',
    'the harness keeps the driver for further connections';
  is(DBIO::Test::Schema->storage_type, '::DBI',
    'the shared schema class still declares no driver');
}

done_testing;
