package NoSessionReset;

use strict;
use warnings;

use DBIO::PostgreSQL::EV::Storage;

# The session reset of a pool connection (_reset_pool_connection, karr k99, core
# k398) is a statement on the wire: DISCARD ALL, then the connect actions. A
# mock test whose fake EV::Pg does not answer it, and whose subject is something
# else -- the order of a release, a lease, a retirement, the fork guard -- loads
# this to put the connection back at once, as the pool did before the reset
# existed. It stubs the one seam and nothing else; the reset itself is held by
# t/114-session-reset-mock.t (the pool's order and a failing reset) and
# t/115-session-reset-live.t (against a server).
{
  no warnings 'redefine';
  *DBIO::PostgreSQL::EV::Storage::_reset_pool_connection =
    sub { $_[0]->future_class->done };
}

1;
