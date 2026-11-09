use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI ();
use DBIO;
use DBIO::Schema;
use DBIO::Oracle::Storage;

# OFFLINE (karr k53, core ADR 0067). A schema always has a driver, and the
# DSN does not choose it. Before ADR 0067 a schema without a driver component
# that connected with a dbi:Oracle: DSN was turned into an Oracle schema by
# core's detection: t/38-connect-params-live.t had a "generic" way that
# asserted exactly that, live. The detection is retired; this file holds the
# rule that replaced it, for this driver:
#
#   1. a schema without a declared driver is refused at connect, even with a
#      DSN that names DBD::Oracle -- the DBD this driver is registered for --
#      and nothing is connected;
#   2. "which driver is this DSN" is a function: DBIO->driver_for names
#      Oracle for both DSN forms this driver deals in, the plain name and
#      Easy Connect;
#   3. DBIO->schema_for gives a schema that declares this driver: its
#      storage is DBIO::Oracle::Storage, and it connects lazily.
#
# THE SUBSTITUTION: DBI->connect records that it was asked and dies, so a
# connection attempt anywhere in here is a failure rather than a timeout.

plan skip_all => 'The installed DBIO core predates ADR 0067 (no '
  . 'DBIO->driver_for): it still detects the driver from the DSN'
  unless DBIO->can('driver_for');

my @CONNECTS;
{
  no warnings 'redefine';
  *DBI::connect = sub { push @CONNECTS, $_[1]; die "t/39: DBI->connect was called\n" };
}

{
  # No shortcut, no component, no storage_type.
  package T::K53::Undeclared;
  use base 'DBIO::Schema';
}

# ------------------------------------------- 1. no driver, no schema

throws_ok {
  T::K53::Undeclared->connect('dbi:Oracle:orcl', 'scott', 'tiger');
} qr/Schema class T::K53::Undeclared declares no driver.*ADR 0067/s,
  'a schema without a declared driver is refused at connect, though its DSN '
. 'names the DBD this driver is registered for: the DSN does not choose the '
. 'driver';

is_deeply \@CONNECTS, [], '... and nothing was connected on the way';

# --------------------------------- 2. finding the driver is a function

is +DBIO->driver_for('dbi:Oracle:orcl'), 'Oracle',
  'DBIO->driver_for names Oracle for a dbi:Oracle: DSN with a name the '
. 'Oracle client resolves';

is +DBIO->driver_for('dbi:Oracle://db.example:1521/FREEPDB1'), 'Oracle',
  '... and for the Easy Connect form _connect_params_dsn builds';

is +DBIO::Storage::DBI->driver_storage_class('Oracle'), 'DBIO::Oracle::Storage',
  '... the name of the driver DBD::Oracle is registered for, this storage';

# ------------------------------------- 3. a schema with that driver

{
  my $schema = DBIO->schema_for('dbi:Oracle:orcl', 'scott', 'tiger');

  is ref $schema->storage, 'DBIO::Oracle::Storage',
    'DBIO->schema_for gives a schema whose storage is this driver\'s';

  ok !$schema->storage->connected,
    '... not connected yet: the driver came from the DSN\'s DBD, the server '
  . 'was asked nothing';

  is_deeply \@CONNECTS, [], '... and DBI->connect was not called';
}

done_testing;
