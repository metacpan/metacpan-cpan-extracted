use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Storage::DBI;
use DBIO::MySQL::Storage;
use DBIO::MySQL::Storage::MariaDB;

# ADR 0030 contract test for dbio-mysql: registering the 'ev' mode on
# DBIO::MySQL::Storage must be reachable through the core mode registry,
# shadow only 'ev' (leaving the base-registered 'immediate' / generic
# modes intact), and propagate to the MariaDB subclass via MRO. No live DB
# required -- the registry walks the linear @ISA at the class level.

# -----------------------------------------------------------------------
# 1. DBIO::MySQL::Storage is reachable as a class (load + MRO sanity)
# -----------------------------------------------------------------------
{
  require_ok 'DBIO::MySQL::Storage';
  require_ok 'DBIO::MySQL::Storage::MariaDB';

  my $mro = mro::get_linear_isa('DBIO::MySQL::Storage');
  ok( (grep { $_ eq 'DBIO::MySQL::Storage' } @$mro),
    'DBIO::MySQL::Storage appears in its own linear @ISA' );
  ok( (grep { $_ eq 'DBIO::MySQL::Storage::MariaDB' }
        @{ mro::get_linear_isa('DBIO::MySQL::Storage::MariaDB') }),
    'DBIO::MySQL::Storage::MariaDB appears in its own linear @ISA' );
}

# -----------------------------------------------------------------------
# 2. 'ev' resolves to DBIO::MySQL::EV::Storage on the MySQL driver
# -----------------------------------------------------------------------
{
  is( DBIO::MySQL::Storage->_resolve_async_mode_class('ev'),
    'DBIO::MySQL::EV::Storage',
    'MySQL storage resolves ev -> DBIO::MySQL::EV::Storage' );
}

# -----------------------------------------------------------------------
# 3. MariaDB subclass inherits the 'ev' registration through MRO
# -----------------------------------------------------------------------
{
  is( DBIO::MySQL::Storage::MariaDB->_resolve_async_mode_class('ev'),
    'DBIO::MySQL::EV::Storage',
    'MariaDB subclass inherits ev registration via MRO' );
}

# -----------------------------------------------------------------------
# 4. 'immediate' is still inherited from DBIO::Storage::DBI
#    (regression: our registration did not shadow the core mode)
# -----------------------------------------------------------------------
{
  is( DBIO::MySQL::Storage->_resolve_async_mode_class('immediate'),
    'DBIO::Future::Immediate',
    'immediate mode still resolves via the base DBIO::Storage::DBI' );
  is( DBIO::MySQL::Storage::MariaDB->_resolve_async_mode_class('immediate'),
    'DBIO::Future::Immediate',
    'immediate mode resolves on MariaDB subclass too' );
}

# -----------------------------------------------------------------------
# 5. An unregistered mode returns undef (no silent shadow)
# -----------------------------------------------------------------------
{
  is( DBIO::MySQL::Storage->_resolve_async_mode_class('not_a_real_mode'),
    undef,
    'unknown mode resolves to undef on MySQL storage' );
  is( DBIO::MySQL::Storage::MariaDB->_resolve_async_mode_class('not_a_real_mode'),
    undef,
    'unknown mode resolves to undef on MariaDB subclass' );
}

# -----------------------------------------------------------------------
# 6. When dbio-mysql-ev is absent, connect(..., { async => 'ev' }) croaks
#    with the canonical "install DBIO::MySQL::EV::Storage" message.
#    Skip if dbio-mysql-ev IS installed (then the mode resolves cleanly).
# -----------------------------------------------------------------------
{
  my $ev_installed = eval { require DBIO::MySQL::EV::Storage; 1 } ? 1 : 0;

  SKIP: {
    skip 'dbio-mysql-ev is installed: cannot probe the absent-dist croak',
      2
      if $ev_installed;

    # Synthesize a DBI storage instance, rebless it into the MySQL driver
    # storage class (the same way _determine_driver would after a real
    # connect), then set _async_mode to 'ev'. _resolve_async_mode_class
    # walks ref($self) -- so without the rebless it cannot see the driver
    # registration. We deliberately do NOT call connect -- we only need
    # _async_storage to traverse the resolver and croak on the missing
    # dist.
    my $storage = bless { }, 'DBIO::MySQL::Storage';
    $storage->_async_mode('ev');

    is( $storage->_resolve_async_mode_class('ev'),
      'DBIO::MySQL::EV::Storage',
      'ev resolves to DBIO::MySQL::EV::Storage on a driver-reblessed storage' );

    throws_ok { $storage->_async_storage }
      qr/install DBIO::MySQL::EV::Storage/,
      'absent dbio-mysql-ev -> canonical install-class croak';
  }
}

done_testing;