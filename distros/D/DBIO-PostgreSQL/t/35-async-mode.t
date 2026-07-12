use strict;
use warnings;
use Test::More;
use Test::Exception;

# ADR 0030: async is an explicit per-connection mode resolved through the mode
# registry. DBIO::PostgreSQL::Storage registers the native 'ev' mode against the
# optional dbio-postgresql-ev backend. This is pure class-registry introspection
# -- no live database and no EV dist required (registration only stores the class
# name; the backend is loaded lazily on first use).

use DBIO::Storage::DBI;
use DBIO::PostgreSQL::Storage;

# -----------------------------------------------------------------------
# 1. 'ev' resolves to the native EV backend on the PostgreSQL driver
# -----------------------------------------------------------------------
is(
  DBIO::PostgreSQL::Storage->_resolve_async_mode_class('ev'),
  'DBIO::PostgreSQL::EV::Storage',
  "PostgreSQL storage resolves the 'ev' mode to the native EV backend",
);

# -----------------------------------------------------------------------
# 2. Registering the 'ev' mode does not eagerly load the optional backend
# -----------------------------------------------------------------------
ok(
  !exists $INC{'DBIO/PostgreSQL/EV/Storage.pm'},
  'registering the ev mode does not eagerly load the optional EV backend',
);

# -----------------------------------------------------------------------
# 3. 'immediate' is still inherited from DBIO::Storage::DBI
#    (regression: our 'ev' registration must not shadow the base mode)
# -----------------------------------------------------------------------
is(
  DBIO::PostgreSQL::Storage->_resolve_async_mode_class('immediate'),
  'DBIO::Future::Immediate',
  'immediate mode still resolves via the base DBIO::Storage::DBI',
);

# -----------------------------------------------------------------------
# 4. An unregistered mode returns undef (no silent shadow)
# -----------------------------------------------------------------------
is(
  DBIO::PostgreSQL::Storage->_resolve_async_mode_class('not_a_real_mode'),
  undef,
  'unknown mode resolves to undef on PostgreSQL storage',
);

# -----------------------------------------------------------------------
# 5. When dbio-postgresql-ev is absent, connect(..., { async => 'ev' })
#    croaks with the canonical "install DBIO::PostgreSQL::EV::Storage"
#    message. Skip if the EV dist IS installed (then the mode resolves
#    cleanly and the absent-dist croak cannot be probed).
# -----------------------------------------------------------------------
{
  my $ev_installed = eval { require DBIO::PostgreSQL::EV::Storage; 1 } ? 1 : 0;

  SKIP: {
    skip 'dbio-postgresql-ev is installed: cannot probe the absent-dist croak',
      2
      if $ev_installed;

    # Synthesize a bare storage instance and rebless it into the PostgreSQL
    # driver storage class (the same way _determine_driver would after a real
    # connect), then set _async_mode to 'ev'. _resolve_async_mode_class walks
    # ref($self) -- so without the rebless it cannot see the driver
    # registration. We deliberately do NOT call connect -- we only need
    # _async_storage to traverse the resolver and croak on the missing dist.
    my $storage = bless { }, 'DBIO::PostgreSQL::Storage';
    $storage->_async_mode('ev');

    is(
      $storage->_resolve_async_mode_class('ev'),
      'DBIO::PostgreSQL::EV::Storage',
      'ev resolves to DBIO::PostgreSQL::EV::Storage on a driver-reblessed storage',
    );

    throws_ok { $storage->_async_storage }
      qr/install DBIO::PostgreSQL::EV::Storage/,
      'absent dbio-postgresql-ev -> canonical install-class croak';
  }
}

done_testing;
