use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require DBIO::Sybase::Storage; 1 }
    or plan skip_all => 'DBIO::Sybase (dbio-sybase) required';
}

use DBIO::MSSQL::Storage::ODBC;
use DBIO::MSSQL::Storage::Sybase;

# karr k81. DBIO::Sybase::Storage precedes DBIO::MSSQL::Storage in the
# linearisation of the DBD::Sybase classes and names DBIO::Sybase::Deploy
# (ASE). A schema deployed through DBD::Sybase got a TEXT column for a
# declared `text` (the SQL Server DDL makes NVARCHAR(MAX) of it) and ASE's
# diff. The deploy class is this driver's on every access path.

for my $class (qw(
  DBIO::MSSQL::Storage
  DBIO::MSSQL::Storage::ODBC
  DBIO::MSSQL::Storage::Sybase
)) {
  is $class->dbio_deploy_class, 'DBIO::MSSQL::Deploy', "$class: deploy class";
}

done_testing;
