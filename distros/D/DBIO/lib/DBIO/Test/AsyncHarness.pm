package DBIO::Test::AsyncHarness;
# ABSTRACT: Parameterised live harness base for DBIO async transports

use strict;
use warnings;

our $VERSION = '0.900004';

use Carp 'croak';
use Test::More ();
use Time::HiRes ();

use base 'Class::Accessor::Grouped';

use namespace::clean;



__PACKAGE__->mk_group_accessors(inherited => qw(
  harness_env_prefix
  harness_async_mode
  harness_required_modules
  harness_schema_class
  harness_default_timeout
));

__PACKAGE__->harness_required_modules([]);
__PACKAGE__->harness_default_timeout(30);

# The declarations are class data with no sensible generic default, so read
# them through one place that says which subclass forgot which one, rather than
# letting an undef reach an environment lookup or a ->connect and fail there.
sub _harness_declaration {
  my ($class, $name) = @_;
  $class = ref($class) || $class;
  my $value = $class->$name;
  croak "$class must declare $name (see DBIO::Test::AsyncHarness)"
    unless defined $value && $value ne '';
  return $value;
}


sub env_var {
  my ($class, $suffix) = @_;
  return $class->_harness_declaration('harness_env_prefix') . '_' . $suffix;
}


sub live_available {
  my $class = shift;
  return 0 unless $ENV{ $class->env_var('DSN') };
  for my $module (@{ $class->harness_required_modules || [] }) {
    (my $file = $module) =~ s{::}{/}g;
    return 0 unless eval { require "$file.pm"; 1 };
  }
  return 1;
}


sub skip_all_unless_live {
  my $class = shift;
  return if $class->live_available;

  my @modules = @{ $class->harness_required_modules || [] };
  Test::More::plan(skip_all =>
      'Set ' . $class->env_var('DSN')
    . (@modules ? ' (and install ' . join(', ', @modules) . ')' : '')
    . ' to run the live '
    . $class->_harness_declaration('harness_async_mode')
    . ' harness tests');
}


sub new {
  my ($class, %opts) = @_;

  croak "$class->new called but "
      . $class->env_var('DSN') . ' is unset or the transport is missing'
      . ' -- gate with skip_all_unless_live'
    unless $class->live_available;

  my $self = bless {
    dsn          => $opts{dsn}  // $ENV{ $class->env_var('DSN') },
    user         => $opts{user} // $ENV{ $class->env_var('USER') } // '',
    pass         => $opts{pass} // $ENV{ $class->env_var('PASS') } // '',
    schema_class => $opts{schema_class}
                 // $class->_harness_declaration('harness_schema_class'),
    storage_type => $opts{storage_type},
    timeout      => $opts{timeout},
  }, $class;

  # The driver, declared on a clone so the schema class stays undeclared
  # (ADR 0067 §4); without one the schema class declares its own.
  my $schema = $self->{schema_class};
  if (defined $self->{storage_type}) {
    $schema = $schema->clone;
    $schema->storage_type($self->{storage_type});
  }

  # Connect an ordinary sync schema, opting THE CONNECTION into the async mode
  # (ADR 0030: the mode is per connection, not per class). The connect actions
  # live on the owning sync storage; the embedded backend's pool replays them
  # per physical connection.
  $self->{schema} = $schema->connect(
    $self->{dsn}, $self->{user}, $self->{pass},
    { %{ $opts{connect_attrs} // {} },
      async => $class->_harness_declaration('harness_async_mode') },
  );

  return $self;
}


sub schema { $_[0]->{schema} }


sub sync_storage { $_[0]->{schema}->storage }


sub async { $_[0]->{schema}->storage->async }


sub pool { $_[0]->async->pool }


sub timeout { $_[0]->{timeout} // $_[0]->harness_default_timeout }


sub await {
  my ($self, $f) = @_;

  # The process has ONE alarm, and it may be somebody's already: a test file
  # guarding itself against a hang, or an await further out whose callback
  # called this one. So the alarm is borrowed: what is running is taken off
  # the clock here, and is back on it on EVERY way out, due when it was due
  # (karr k300). Times are absolute, by Time::HiRes: perl's own alarm answers
  # what is left rounded to a whole second, 9.8 as 10, and putting that back
  # after each await pushes the alarm ahead of a row of quick awaits for good.
  my $timeout  = $self->timeout;
  my $entered  = Time::HiRes::time();
  my $left     = Time::HiRes::alarm(0);
  my $outer_at = $left    ? $entered + $left    : undef;
  my $ours_at  = $timeout ? $entered + $timeout : undef;

  my $err;
  WAIT: {
    # An outer alarm due before ours is not ours to answer. It goes back on
    # the clock as it was and fires at its time under the handler it was set
    # with -- or under none, and ends the process. No handler of ours here.
    if (defined $outer_at and !defined $ours_at || $outer_at < $ours_at) {
      my $due = _alarm_at($outer_at);
      my $ready;
      eval {
        $self->_tick_loop until ($ready = $f->is_ready) || Time::HiRes::time() >= $due;
        1;
      } or $err = $@;
      last WAIT if defined $err || $ready;

      # It was due and the wait goes on: its handler returned. What is left
      # of the wait is under our timeout, counted from when we were entered.
      $left     = Time::HiRes::alarm(0);
      $outer_at = $left ? Time::HiRes::time() + $left : undef;
      redo WAIT;
    }

    {
      local $SIG{ALRM} = sub { die "TIMEOUT awaiting Future in " . ref($self) . "\n" };
      # Our alarm is off the clock on every way out of the eval, a die inside
      # _tick_loop included: left running it would fire later, under whatever
      # handler is there then, far away from the test that set it.
      eval {
        _alarm_at($ours_at) if defined $ours_at;
        $self->_tick_loop until $f->is_ready;
        Time::HiRes::alarm(0);
        1;
      } or do {
        $err = $@;
        Time::HiRes::alarm(0);
      };
    }
    # ... and the outer one back on it -- after our handler is gone, so that
    # one whose time has come meanwhile fires under its own.
    _alarm_at($outer_at) if defined $outer_at;
  }
  croak $err if defined $err;

  return $f->get;
}

# Set the process alarm to go off at $at, a Time::HiRes::time; at once when
# that is past -- the shortest alarm that still is one, since 0 clears it.
# Returns a time by which it has gone off.
sub _alarm_at {
  my ($at) = @_;
  my $in = $at - Time::HiRes::time();
  $in = 0.001 if $in < 0.001;
  Time::HiRes::alarm($in);
  return Time::HiRes::time() + $in;
}


sub _tick_loop {
  my $self = shift;
  croak ref($self) . ' must override _tick_loop to drive its event loop'
      . ' (see DBIO::Test::AsyncHarness)';
}


sub query_on {
  my ($self, $conn, $sql, $bind) = @_;
  return $self->async->_query_async_pinned($conn, $sql, $bind // []);
}


sub warm_pool {
  my $self = shift;
  my $pool = $self->pool;
  my @conns = map { $self->await($pool->acquire) } 1 .. $pool->max_size;
  my @leases = map { $pool->can('_lease') ? $pool->_lease($_) : undef } @conns;
  $pool->release($conns[$_], $leases[$_]) for 0 .. $#conns;
  return;
}


sub run_on_each_pooled_connection {
  my ($self, $n, $code) = @_;
  croak 'run_on_each_pooled_connection($n, $code): $code must be a coderef'
    unless ref $code eq 'CODE';

  my $pool = $self->pool;
  croak "pool max_size (@{[ $pool->max_size ]}) is smaller than the requested "
      . "$n connections -- raise pool_size in connect_attrs"
    if $pool->max_size < $n;

  # Acquire and HOLD $n connections, forcing $n fresh spawns (idle reuse would
  # skip the spawn -- and thus the replay). acquire's readiness gating means
  # each handle is already connected when it arrives.
  my @conns;
  my @leases;
  for (1 .. $n) {
    my $conn = $self->await($pool->acquire);
    push @conns, $conn;
    push @leases, $pool->can('_lease') ? $pool->_lease($conn) : undef;
  }

  # Distinctness guard: $n held connections must be $n different objects.
  my %seen;
  $seen{ $_ }++ for @conns;
  croak "expected $n distinct pooled connections, got @{[ scalar keys %seen ]} "
      . '-- a spawn did not happen, so the replay was not exercised per connection'
    unless keys %seen == $n;

  my @results;
  my $err;
  {
    local $@;
    eval {
      # Capture each connection's resolved list as an arrayref so multi-row
      # results do not flatten together across connections.
      push @results, [ $self->await($code->($_, $self)) ] for @conns;
      1;
    } or $err = $@;
  }

  # Always release the held connections back to the pool, even on failure.
  $pool->release($conns[$_], $leases[$_]) for 0 .. $#conns;

  croak $err if defined $err;
  return @results;
}


sub disconnect {
  my $self = shift;
  eval { $self->async->disconnect };
  eval { $self->{schema}->storage->disconnect } if $self->{schema};
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::AsyncHarness - Parameterised live harness base for DBIO async transports

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  use Test::More;
  use DBIO::PostgreSQL::EV::TestHarness;

  # Skip the whole file cleanly unless a live DSN + the transport are available.
  DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

  my $h = DBIO::PostgreSQL::EV::TestHarness->new(
      connect_attrs => {
          on_connect_do => [ q{SET myapp.replay_tag = 'live'} ],
          pool_size     => 4,
      },
  );

  # Force 3 DISTINCT pool connections to spawn (each replays the connect
  # actions at spawn) and run an async op on each.
  my @tags = $h->run_on_each_pooled_connection(3, sub {
      my ($conn, $harness) = @_;
      return $harness->query_on($conn, q{SELECT current_setting('myapp.replay_tag')});
  });
  is $_->[0][0], 'live', 'connect action replayed on this pooled connection'
      for @tags;

  $h->disconnect;
  done_testing;

=head1 DESCRIPTION

The harness every async transport's live test suite writes: parse the driver's
C<DBIO_TEST_*_DSN>, connect a schema with C<< { async => $mode } >>, reach the
embedded async backend and its pool, drive the event loop until a Future is
ready, and force B<distinct> pool connections to spawn so an C<on_connect>
replay can be asserted per connection.

None of that is driver-specific except four declarations and one seam, so it
lives here once (ADR 0030 section 4) instead of being copied per
transport dist. C<dbio-postgresql-ev> and C<dbio-mysql-ev> had grown two copies
of it that differed only in an environment-variable prefix, two class names and
one redundant extra step.

A transport dist subclasses this, declares what it is, and supplies the one
thing core cannot know -- how to turn its event loop:

  package DBIO::PostgreSQL::EV::TestHarness;
  use base 'DBIO::Test::AsyncHarness';

  __PACKAGE__->harness_env_prefix('DBIO_TEST_PG');
  __PACKAGE__->harness_async_mode('ev');
  __PACKAGE__->harness_required_modules([qw( EV EV::Pg )]);
  __PACKAGE__->harness_schema_class('DBIO::PostgreSQL::EV::TestHarness::_Schema');

  sub _tick_loop { EV::run(EV::RUN_ONCE()) }

=head1 ATTRIBUTES

=head2 harness_env_prefix

Class data. The environment-variable prefix this transport's DSN lives under,
without a trailing underscore: C<DBIO_TEST_PG> means C<DBIO_TEST_PG_DSN>,
C<DBIO_TEST_PG_USER> and C<DBIO_TEST_PG_PASS>. Required.

=head2 harness_async_mode

Class data. The async mode passed as C<< { async => ... } >> on connect (ADR
0030): C<'ev'>, C<'future_io'>, C<'forked'>, ... Required, and deliberately not
defaulted -- which execution model a harness drives is the first thing its
reader needs to know.

=head2 harness_required_modules

Class data. Arrayref of modules that must load for the transport to run, e.g.
C<[qw( EV EV::Pg )]>. Defaults to none, which is correct for a mode that needs
no event loop.

=head2 harness_schema_class

Class data. The schema class L</new> connects when the caller supplies no
C<schema_class>. Required.

=head2 harness_default_timeout

Class data. Wall-clock seconds L</await> waits before failing loudly. Defaults
to 30; a per-instance C<timeout> option to L</new> overrides it.

=head1 METHODS

=head2 env_var

  my $name = $class->env_var('DSN');    # e.g. DBIO_TEST_PG_DSN

The full environment-variable name for C<$suffix> under this harness's
L</harness_env_prefix>.

=head2 live_available

  Harness->live_available or ...;

Class method. True when this transport's C<..._DSN> is set B<and> every module
in L</harness_required_modules> loads -- i.e. the live harness can run.

=head2 skip_all_unless_live

  Harness->skip_all_unless_live;

Class method. When the live harness is unavailable (see L</live_available>),
calls C<< Test::More::plan(skip_all => ...) >>, which skips and exits the test
file cleanly. A no-op when live testing is available.

=head2 new

  my $h = Harness->new(%opts);

Connect a schema with this harness's async mode and make its embedded async
backend reachable. Options:

=over 4

=item * C<dsn> / C<user> / C<pass> -- connect info; default to the
C<..._DSN> / C<..._USER> / C<..._PASS> variables under L</harness_env_prefix>.

=item * C<schema_class> -- the schema class to connect (default
L</harness_schema_class>). Supply your own to register storage layers or
components -- this is how an extension injects its behaviour.

=item * C<storage_type> -- the driver's storage class, for a C<schema_class>
that declares no driver of its own (L<DBIO::Test::Schema>):

  my $h = DBIO::PostgreSQL::EV::TestHarness->new(
      schema_class => 'DBIO::Test::Schema',
      storage_type => 'DBIO::PostgreSQL::Storage',
  );

The harness then connects a clone of the schema class declaring that driver,
and the class itself stays undeclared -- as L<DBIO::Test/init_schema> takes it
(ADR 0067). Without it the schema class must declare its driver itself, or
core refuses the connect. The harness keeps it as C<< $h->{storage_type} >>
for every further connection it makes on the same schema class
(L<DBIO::Test::AsyncParity/parity_sync_schema>).

=item * C<connect_attrs> -- extra connect attributes merged into the
C<< { async => $mode, ... } >> attrs hash, e.g. C<on_connect_do>,
C<on_connect_call>, C<pool_size>. These are exactly the actions replayed on
each pooled connection.

=item * C<timeout> -- wall-clock seconds L</await> waits before failing loudly
(default L</harness_default_timeout>).

=back

Croaks unless L</live_available> -- call L</skip_all_unless_live> first.

=head2 schema

The connected schema instance.

=head2 sync_storage

The sync storage the schema connected to -- the owner of the async backend.
Forces driver determination on first call.

=head2 async

The embedded async backend, possibly with composed extension async layers.
Built lazily on first access via the sync storage's C<async> resolver, which
also wires the owner back-reference.

=head2 pool

The async backend's connection pool (a L<DBIO::Storage::PoolBase>).

=head2 timeout

Wall-clock seconds L</await> waits: the C<timeout> passed to L</new>, else
L</harness_default_timeout>. It may be a fraction of a second. A false value
is no timeout at all: L</await> then sets no alarm, and waits for as long as
it takes.

=head2 await

  my @result = $h->await($future);

Drive the event loop until C<$future> is ready, then return its result (dies on
a failed Future). Guarded by a wall-clock C<alarm> so a hang fails loudly
instead of spinning forever: after L</timeout> seconds it dies with
C<TIMEOUT awaiting Future in $class>.

An already-ready Future is returned without turning the loop at all, so a
transport whose Futures resolve synchronously (C<immediate>, C<forked>) needs no
L</_tick_loop> to use this harness.

B<The alarm is borrowed.> A process has one alarm, and a test file may have set
it already to guard itself against a hang:

  $SIG{ALRM} = sub { BAIL_OUT('a wait did not end') };
  alarm 120;

C<await> used to end with C<alarm 0>, which cleared that alarm at the first
C<await> and left the rest of the file unguarded. Now an alarm
that is running when C<await> is entered is running when it is left, on every
way out -- the Future ready, a die in L</_tick_loop>, the timeout:

=over 4

=item *

It is due when it was due: it goes on with what it had left less the time
spent in C<await>, not from the start again.

=item *

When it is due B<before> the timeout, it is the one that fires, at its time
and under the handler it was set with -- C<await> sets none of its own until
then, so an alarm without a handler ends the process as it would have
anywhere else. If its handler returns, the wait goes on and the timeout is
still in force, counted from when C<await> was entered.

=item *

When the timeout is due first, the outer alarm is off the clock while
C<await> waits. Should its time pass meanwhile -- a callback stayed in the loop
past the timeout -- it fires as soon as C<await> is left.

=item *

An C<await> called from a callback inside another one's L</_tick_loop> treats
that one's timeout the same way, so neither takes the other's.

=back

With no alarm running, none is running afterwards.

The bookkeeping is done with L<Time::HiRes>, in fractions of a second, on the
same timer perl's own C<alarm> sets. What is guaranteed: the outer alarm is
moved by no more than the time C<await> itself takes to read and to set it --
microseconds, each time -- and never by rounding. That matters: perl's
C<alarm> answers what is left rounded to a whole second, 9.8 as 10, and
setting that again after every C<await> would push the alarm ahead of a row
of quick awaits for good. The handler of a Perl signal runs between two operations, so
an alarm that falls due while the loop is inside a blocking C call fires when
that call returns.

=head2 _tick_loop

  sub _tick_loop { EV::run(EV::RUN_ONCE()) }

The one genuinely transport-specific seam: run the event loop for one
iteration. Called by L</await> until the Future is ready.

Croaks unless overridden -- and only from L</await>, and only for a Future that
is not already ready, so a synchronous transport never reaches it.

=head2 query_on

  my @rows = $h->await( $h->query_on($conn, $sql, \@bind) );

Run C<$sql> on the specific pooled connection C<$conn> (pinned, not released),
returning a Future of the raw result rows -- the natural way to assert that a
connect action replayed on B<that> connection. C<$sql> uses C<?> placeholders;
shaping them for the wire is the transport's job and happens inside it (ADR
0032 section 6). Wrap the result with L</await>.

=head2 warm_pool

  $h->warm_pool;

Spawn every pool connection up front and release them all back to the idle
pool, so a later C<acquire> reuses an idle handle instead of spawning one. A
pooled C<*_async> op acquires its connection B<internally>, so a test that wants
the pool already populated cannot arrange it at the call site.

B<Connectedness is not what this buys you.> L<DBIO::Storage::PoolBase/acquire>
chains its readiness seam, so an C<acquire> already hands back a connected
handle; this only decides B<when> the spawn happens.

Each connection is one L</await>, each with the full L</timeout>. An alarm the
test file has set stays set through all of them (see L</await>).

=head2 run_on_each_pooled_connection

  my @results = $h->run_on_each_pooled_connection($n, sub {
      my ($conn, $harness) = @_;
      return $harness->query_on($conn, $sql);   # a Future
  });

The replay-verification seam. Forces C<$n> B<distinct> pool connections to spawn
by acquiring and holding them -- each spawn replays the owning sync storage's
C<on_connect> actions. Then runs C<< $code->($conn, $self) >> on each held
connection, awaits the returned Future, releases every connection, and returns
one entry per connection in spawn order.

Each entry is an B<arrayref> of whatever that connection's Future resolved to --
for a L</query_on> op, the arrayref of raw result rows, so C<< $results[$i][0] >>
is connection C<$i>'s first row. Capturing per connection keeps multi-row
results from flattening across connections.

C<$code> must return a Future. Croaks if the pool's C<max_size> is smaller than
C<$n> (raise C<pool_size> in C<connect_attrs>), or if the pool ever hands back a
non-distinct connection -- which would mean a spawn did not happen and the
replay was never exercised on a fresh connection.

=head2 disconnect

Tear down the async backend -- shutting the pool, which runs the
C<on_disconnect> actions on each live connection -- and the schema storage.

=head1 REUSE BY AN EXTENSION

An async storage extension composes onto a transport via core's storage-layer
composition (ADR 0032); it ships no transport of its own. To live-test that its
C<on_connect_call> replays on pooled connections, it reuses the transport's
harness with its own schema class and its own per-connection assertion:

  my $h = DBIO::PostgreSQL::EV::TestHarness->new(
      schema_class  => 'MyApp::Age::Schema',      # registers the extension layer
      connect_attrs => { on_connect_call => 'load_age', pool_size => 3 },
  );

The harness never mentions any extension: it exposes the schema, sync storage,
async backend and pool, and lets the caller supply the layer and the assertion.
This is why a transport's harness belongs under C<lib/> rather than C<t/lib/> --
a downstream extension dist cannot see another dist's C<t/lib>.

=head1 CAVEAT

This is a B<live> harness: it opens real connections. It is for driver and
extension test suites, not production code, and it is deliberately outside
core's mock-only offline discipline -- core's own tests exercise this class
offline only (parameterisation, gating and error paths), never a connection.
Gate every consumer with L</skip_all_unless_live>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
