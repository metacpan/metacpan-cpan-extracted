use strict;
use warnings;

use Test::More;

# What this file claims, in two halves:
#
# 1. Loading DBIO::Base -- the root of practically every class in this family --
#    must not drag DBI or a DBD into the process. It used to:
#    DBIO::Base loads DBIO::Optional::Dependencies, which decided at file scope,
#    with a real "require DBD::MariaDB", which of two module NAMES goes into a
#    metadata table. That one require pulled DBI plus an XS driver into every
#    process touching anything DBIO, and it made the ADR-0004 assurance ("the
#    core does not depend on a driver") unverifiable in-process -- a tripwire
#    like this one was permanently green and could never catch anything
#    (found from the other side in dbio-async).
#
# 2. Dropping that require must not change the answer: the mysql requirement
#    group still names DBD::MariaDB where that driver is installed, and
#    DBD::mysql otherwise.

my @forbidden = qw( DBI.pm DBD/MariaDB.pm DBD/mysql.pm );

require DBIO::Base;

ok !exists $INC{$_}, "$_ not in %INC after loading DBIO::Base"
  for @forbidden;

require DBIO;

ok !exists $INC{$_}, "$_ not in %INC after loading DBIO"
  for @forbidden;

# --- the answer is unchanged ------------------------------------------------

my $mysql = DBIO::Optional::Dependencies->req_list_for('rdbms_mysql');

is scalar(keys %$mysql), 1, 'the mysql requirement group names exactly one driver';

my ($driver) = keys %$mysql;

like $driver, qr/^DBD::(?:MariaDB|mysql)$/,
  '... and it is one of the two mysql drivers';

is $mysql->{$driver}, '0', '... with the usual "any version" requirement';

ok !exists $INC{$_}, "$_ still not in %INC after asking for the requirement list"
  for @forbidden;

# Now -- and only now, because it dirties %INC -- confront the answer with
# reality. Loading is the strongest available oracle for "is it installed".
if ( eval { require DBD::MariaDB; 1 } ) {
  is $driver, 'DBD::MariaDB',
    'DBD::MariaDB is installed, so the mysql group names it';
}
else {
  # A DBD::MariaDB present on disk but unloadable (missing shared library, ABI
  # mismatch) is the one case where the file probe answers differently from the
  # old require: it keeps naming MariaDB and lets req_ok_for report it missing,
  # rather than silently reporting on a driver the user did not install. Assert
  # the fallback only where the file is genuinely absent.
  SKIP: {
    skip 'DBD/MariaDB.pm is on disk but does not load', 1
      if grep { !ref $_ and -f "$_/DBD/MariaDB.pm" } @INC;

    is $driver, 'DBD::mysql',
      'DBD::MariaDB is not installed, so the mysql group falls back to DBD::mysql';
  }
}

done_testing;
