package DBIO::PostgreSQL::EV::TestHarness;
# ABSTRACT: Reusable live-PostgreSQL harness for EV async on_connect-replay tests

use strict;
use warnings;

use Carp 'croak';
use namespace::clean;


# The default schema class used when the caller supplies none: an ordinary sync
# PostgreSQL schema. The 'dbi:Pg:' DSN auto-detects DBIO::PostgreSQL::Storage,
# which registers the 'ev' async mode; no result sources are needed because the
# harness exercises connection-level SQL, not the ORM.
{
  package DBIO::PostgreSQL::EV::TestHarness::_Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}


sub live_available {
  return 0 unless $ENV{DBIO_TEST_PG_DSN};
  return 0 unless eval { require EV; require EV::Pg; 1 };
  return 1;
}


sub skip_all_unless_live {
  my $class = shift;
  return if $class->live_available;
  require Test::More;
  Test::More::plan(skip_all =>
    'Set DBIO_TEST_PG_DSN (and install EV::Pg) to run the live EV harness tests');
}


sub new {
  my ($class, %opts) = @_;

  croak 'DBIO::PostgreSQL::EV::TestHarness->new called but no live PG DSN / EV::Pg '
      . '-- gate with skip_all_unless_live'
    unless $class->live_available;

  my $dsn  = $opts{dsn}  // $ENV{DBIO_TEST_PG_DSN};
  my $user = $opts{user} // $ENV{DBIO_TEST_PG_USER} // '';
  my $pass = $opts{pass} // $ENV{DBIO_TEST_PG_PASS} // '';

  my $schema_class  = $opts{schema_class} // 'DBIO::PostgreSQL::EV::TestHarness::_Schema';
  my $connect_attrs = $opts{connect_attrs} // {};

  my $self = bless {
    dsn          => $dsn,
    user         => $user,
    pass         => $pass,
    schema_class => $schema_class,
  }, $class;

  # Connect an ordinary sync schema, opting the connection into the native 'ev'
  # async mode. The connect actions live on the (owning) sync storage; the
  # embedded EV backend's pool replays them per connection (karr #68).
  $self->{schema} = $schema_class->connect(
    $dsn, $user, $pass,
    { %$connect_attrs, async => 'ev' },
  );

  return $self;
}


sub schema { $_[0]->{schema} }


sub sync_storage { $_[0]->{schema}->storage }


sub async { $_[0]->{schema}->storage->async }


sub pool { $_[0]->async->pool }


sub await {
  my ($self, $f) = @_;
  require EV;
  local $SIG{ALRM} = sub { croak 'TIMEOUT awaiting Future in EV test harness' };
  alarm($self->{timeout} || 30);
  EV::run(EV::RUN_ONCE()) until $f->is_ready;
  alarm 0;
  return $f->get;
}


sub query_on {
  my ($self, $conn, $sql, $bind) = @_;
  return $self->async->_query_async_pinned($conn, $sql, $bind // []);
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
  # skip the spawn -- and thus the replay). Each acquire's spawn drives the
  # blocking connect-action replay to completion before the Future resolves.
  my @conns;
  for (1 .. $n) {
    push @conns, $self->await($pool->acquire);
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
  $pool->release($_) for @conns;

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

DBIO::PostgreSQL::EV::TestHarness - Reusable live-PostgreSQL harness for EV async on_connect-replay tests

=head1 VERSION

version 0.900001

=head1 SYNOPSIS

  use Test::More;
  use DBIO::PostgreSQL::EV::TestHarness;

  # Skip the whole file cleanly unless a live PG DSN + EV::Pg are available.
  DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

  my $h = DBIO::PostgreSQL::EV::TestHarness->new(
      # each fresh pool connection replays these against the owning sync storage
      connect_attrs => {
          on_connect_do => [ q{SET myapp.replay_tag = 'live'} ],
          pool_size     => 4,
      },
  );

  # Force 3 DISTINCT pool connections to spawn (each replays the connect
  # actions at spawn) and run an async op on each -- the replay-verification seam.
  my @tags = $h->run_on_each_pooled_connection(3, sub {
      my ($conn, $harness) = @_;
      return $harness->query_on($conn, q{SELECT current_setting('myapp.replay_tag')});
  });
  is $_->[0][0], 'live', 'connect action replayed on this pooled connection'
      for @tags;

  $h->disconnect;
  done_testing;

=head1 DESCRIPTION

An B<installable> test harness for the native C<ev> async transport
(L<DBIO::PostgreSQL::EV::Storage>). It removes the boilerplate every live EV
test repeats -- parse C<DBIO_TEST_PG_DSN>, connect an C<< { async => 'ev' } >>
schema, reach the embedded async backend + its pool, drive the EV loop -- and,
crucially, provides the one thing an C<on_connect>-replay test needs and cannot
get from a directly-constructed storage: an EV async backend B<wired to an
owning sync storage> whose C<on_connect_do> / C<on_connect_call> actually replay
on every freshly-spawned pool connection (karr #68).

It ships under C<lib/> (not C<t/>) on purpose: it is consumed both by this
distribution's own live tests B<and> by downstream extension distributions
(e.g. C<dbio-postgresql-age>), which cannot see another dist's C<t/lib>. An
extension that carries a develop/recommends dependency on
L<DBIO::PostgreSQL::EV> reaches this class from its own C<t/>.

=head1 METHODS

=head2 live_available

  DBIO::PostgreSQL::EV::TestHarness->live_available or ...;

Class method. True when C<DBIO_TEST_PG_DSN> is set B<and> L<EV::Pg> (and L<EV>)
can be loaded -- i.e. the live harness can run.

=head2 skip_all_unless_live

  DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

Class method. When the live harness is unavailable (see L</live_available>),
calls C<< Test::More->plan(skip_all => ...) >>, which skips and exits the test
file cleanly. A no-op when live testing is available.

=head2 new

  my $h = DBIO::PostgreSQL::EV::TestHarness->new(%opts);

Connect an C<< { async => 'ev' } >> schema and build its embedded async backend.
Options:

=over 4

=item * C<dsn> / C<user> / C<pass> -- connect info; default to
C<DBIO_TEST_PG_DSN> / C<DBIO_TEST_PG_USER> / C<DBIO_TEST_PG_PASS>.

=item * C<schema_class> -- the schema class to connect (default a generic sync
PostgreSQL schema). Supply your own to register storage layers / components
(this is how an extension injects its behaviour).

=item * C<connect_attrs> -- extra connect attributes merged into the
C<< { async => 'ev', ... } >> attrs hash, e.g. C<on_connect_do>,
C<on_connect_call>, C<pool_size>. These are exactly the actions replayed on each
pooled connection.

=back

Croaks unless L</live_available> (call L</skip_all_unless_live> first).

=head2 schema

The connected schema instance.

=head2 sync_storage

The sync L<DBIO::PostgreSQL::Storage> the schema connected to (the owner of the
async backend). Forces driver determination on first call.

=head2 async

The embedded async backend (a L<DBIO::PostgreSQL::EV::Storage>, possibly with
composed extension async layers). Built lazily on first access via the sync
storage's C<async> resolver, which also wires the owner back-reference.

=head2 pool

The L<DBIO::PostgreSQL::EV::Pool> of the async backend.

=head2 await

  my @result = $h->await($future);

Drive the EV loop until C<$future> is ready, then return its result (dies on a
failed Future). Guarded by a wall-clock C<alarm> so a hang fails loudly instead
of spinning forever.

=head2 query_on

  my @rows = $h->await( $h->query_on($conn, $sql, \@bind) );

Run C<$sql> on the specific pooled connection C<$conn> (pinned, not released),
returning a L<Future> of the raw result rows -- the natural way to assert that a
connect action replayed on B<that> connection. C<$sql> may use C<?> placeholders
(shaped to C<$N> by the transport). Returns a Future; wrap with L</await>.

=head2 run_on_each_pooled_connection

  my @results = $h->run_on_each_pooled_connection($n, sub {
      my ($conn, $harness) = @_;
      return $harness->query_on($conn, $sql);   # a Future
  });

The replay-verification seam. Forces C<$n> B<distinct> pool connections to spawn
by acquiring (and holding) them -- each spawn replays the owner's C<on_connect>
actions via L<DBIO::PostgreSQL::EV::Storage/_run_pool_connect_statement>. Then
runs C<$code-E<gt>($conn, $self)> on each held connection, awaits the returned
Future, releases every connection, and returns one entry per connection (in
spawn order). Each entry is an B<arrayref> of whatever that connection's Future
resolved to -- e.g. for a L</query_on> op it is the arrayref of raw result rows,
so C<< $results[$i][0] >> is connection C<$i>'s first row. Capturing per
connection as an arrayref keeps multi-row results from flattening across
connections.

C<$code> must return a L<Future>. Croaks if the pool's C<max_size> is smaller
than C<$n> (raise C<pool_size> in C<connect_attrs>), or if the pool ever hands
back a non-distinct connection (which would mean a spawn did not happen and the
replay was not exercised on a fresh connection).

=head2 disconnect

Tear down the async backend (shutting the pool, which runs the
C<on_disconnect> actions on each live connection) and the schema storage.

=head1 REUSE BY AN EXTENSION (e.g. AGE)

An async storage extension composes onto this transport via core's storage-layer
composition (core karr #70); it does not ship its own transport. To live-test
that its C<on_connect_call> (e.g. C<connect_call_load_age>) replays on pooled EV
connections, an extension reuses this harness by supplying its own schema class
(carrying the extension's storage layer + component) and its own per-connection
assertion:

  my $h = DBIO::PostgreSQL::EV::TestHarness->new(
      schema_class  => 'MyApp::Age::Schema',        # registers the Age layer
      connect_attrs => { on_connect_call => 'load_age', pool_size => 3 },
  );

  $h->run_on_each_pooled_connection(3, sub {
      my ($conn, $harness) = @_;
      # LOAD 'age' + search_path must have replayed on THIS pooled connection
      return $harness->query_on($conn, q{SELECT current_setting('search_path')});
  });

The harness stays generic: it never mentions AGE, exposes the schema / sync
storage / async backend / pool, and lets the caller add the layer (via
C<schema_class>) and assert whatever it needs on each pooled connection.

=head1 CAVEAT

This is a B<live> harness: it opens real connections against
C<DBIO_TEST_PG_DSN>. It is for driver/extension test suites, not production
code. It is excluded from the mock-only offline discipline by design -- gate
every consumer with L</skip_all_unless_live>.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
