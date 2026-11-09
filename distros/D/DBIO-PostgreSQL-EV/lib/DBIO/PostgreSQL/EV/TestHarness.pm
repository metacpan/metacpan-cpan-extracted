package DBIO::PostgreSQL::EV::TestHarness;
# ABSTRACT: Reusable live-PostgreSQL harness for EV async on_connect-replay tests

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Test::AsyncHarness';


__PACKAGE__->harness_env_prefix('DBIO_TEST_PG');
__PACKAGE__->harness_async_mode('ev');
__PACKAGE__->harness_required_modules([qw( EV EV::Pg )]);
__PACKAGE__->harness_schema_class('DBIO::PostgreSQL::EV::TestHarness::_Schema');

# The default schema class used when the caller supplies none: an ordinary sync
# PostgreSQL schema. It declares its driver (core ADR 0067) with the
# PostgreSQL component, which pins DBIO::PostgreSQL::Storage, the storage that
# registers the 'ev' async mode; no result sources are needed because the
# harness exercises connection-level SQL, not the ORM. A schema_class the
# caller supplies declares its own driver.
#
# It loads no component of this distribution: DBIO::PostgreSQL::EV is the
# distribution's overview module -- POD, no methods, no connection() hook --
# and a schema reaches the ev mode without it (the distribution's SYNOPSIS
# declares the driver with the -pg shortcut and loads no component at all;
# t/45-synopsis-plain-schema-live.t runs it).
# dbio-mysql-ev's harness loads 'MySQL::EV' as well; the two differ there. That
# DBIO::PostgreSQL::EV, loaded as a component, takes no part in resolution is
# proven offline -- t/00-load.t's ADR 0032 storage-layer contract,
# t/02-access-broker.t's storage_type guard, t/27's registry check.
{
  package DBIO::PostgreSQL::EV::TestHarness::_Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}


sub _tick_loop {
  require EV;
  return EV::run(EV::RUN_ONCE());
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::EV::TestHarness - Reusable live-PostgreSQL harness for EV async on_connect-replay tests

=head1 VERSION

version 0.900004

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
on every freshly-spawned pool connection.

All of that machinery is B<inherited> from
L<DBIO::Test::AsyncHarness>, the parametrised base core ships (ADR 0030 §4).
This class supplies only what core cannot know: the four class declarations
below, the EV-specific L</_tick_loop>, and the default schema class.
C<live_available>, C<skip_all_unless_live>, C<new>, C<schema>,
C<sync_storage>, C<async>, C<pool>, C<timeout>, C<await>, C<query_on>,
C<warm_pool>, C<run_on_each_pooled_connection> and C<disconnect> are all
core's.

It ships under C<lib/> (not C<t/>) on purpose: it is consumed both by this
distribution's own live tests B<and> by downstream extension distributions
(e.g. C<dbio-postgresql-age>), which cannot see another dist's C<t/lib>. An
extension that carries a develop/recommends dependency on
L<DBIO::PostgreSQL::EV> reaches this class from its own C<t/>.

=head1 METHODS

=head2 _tick_loop

Drives one iteration of the L<EV> event loop -- the single thing core's
L<DBIO::Test::AsyncHarness> cannot know, and the only method this class
implements. C<await> calls it until the Future is ready.

L<EV> is loaded here rather than at compile time on purpose: this class must
stay B<loadable without it>, or
L<DBIO::Test::AsyncHarness/skip_all_unless_live> could not skip on the very
machines it exists to skip on. C<live_available> is what probes for EV and
L<EV::Pg>, and C<new> refuses without it, so by the time this runs the module
is present.

=head1 REUSE BY AN EXTENSION (e.g. AGE)

An async storage extension composes onto this transport via core's storage-layer
composition; it does not ship its own transport. To live-test
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
every consumer with L<DBIO::Test::AsyncHarness/skip_all_unless_live>.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
