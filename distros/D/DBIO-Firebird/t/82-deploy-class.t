use strict;
use warnings;
use Test::More;

use DBIO::Firebird::Storage;
use DBIO::Firebird::Storage::InterBase;
use DBIO::Firebird::Storage::ODBC;

# OFFLINE (karr k55, core ADR 0064).
#
# WHY: dbio_deploy_class is the driver's alone, one source. It sits on the
# InterBase storage, the stage Storage inherits from, so both native
# transports answer the Deploy class from the same method. The ODBC storage
# does not inherit InterBase and is left as it was (open: karr k40).

my $deploy = 'DBIO::Firebird::Deploy';

is(DBIO::Firebird::Storage::InterBase->dbio_deploy_class, $deploy,
  'Storage::InterBase answers the Deploy class');
is(DBIO::Firebird::Storage->dbio_deploy_class, $deploy,
  'Storage answers the Deploy class');

is(
  DBIO::Firebird::Storage->can('dbio_deploy_class'),
  DBIO::Firebird::Storage::InterBase->can('dbio_deploy_class'),
  'one source: Storage inherits it, defines none of its own',
);

ok(!DBIO::Firebird::Storage::ODBC->isa('DBIO::Firebird::Storage::InterBase'),
  'ODBC storage does not inherit InterBase');
my $odbc = DBIO::Firebird::Storage::ODBC->can('dbio_deploy_class');
isnt($odbc && $odbc == DBIO::Firebird::Storage::InterBase->can('dbio_deploy_class'),
  1, 'ODBC storage does not get the InterBase method');
is(DBIO::Firebird::Storage::ODBC->can('dbio_deploy_class'),
  DBIO::Storage::DBI->can('dbio_deploy_class'),
  'ODBC storage answers whatever the base does, unchanged');

done_testing;
