package FutureIoParityHarness;

# The DBIO::Test::AsyncHarness of this distribution's future_io transport
# (DBIO::PostgreSQL::Storage::Async) on the loop IO::Async, for
# DBIO::Test::AsyncParity (t/133).
#
# It lives under t/lib, not lib/: the transport itself is optional here
# (DBIO::Async is "recommends"), and nothing outside this distribution's tests
# needs a harness for it -- the EV transport's harness is installed because
# dbio-postgresql-age reuses it.

use strict;
use warnings;

use base 'DBIO::Test::AsyncHarness';

__PACKAGE__->harness_env_prefix('DBIO_TEST_PG');
__PACKAGE__->harness_async_mode('future_io');
__PACKAGE__->harness_required_modules([qw(
  DBIO::PostgreSQL::Storage::Async IO::Async::Loop Future::IO::Impl::IOAsync
)]);
__PACKAGE__->harness_schema_class('FutureIoParityHarness::Schema');

# The schema the harness connects when the caller names none: core's shared
# DBIO::Test::Schema, with its sources, on this driver. DBIO::Test::Schema
# keeps no driver in its class, and a test helper of a driver declares its
# driver (core ADR 0067).
{
  package FutureIoParityHarness::Schema;
  use base 'DBIO::Test::Schema';
  __PACKAGE__->storage_type('+DBIO::PostgreSQL::Storage');
}

# Future::IO::Impl::IOAsync takes the loop IO::Async::Loop->new returns, the
# process's one. One turn of it, a second at most so that the wall-clock guard
# of await still gets its turn.
sub _tick_loop {
  require IO::Async::Loop;
  IO::Async::Loop->new->loop_once(1);
  return;
}

1;
