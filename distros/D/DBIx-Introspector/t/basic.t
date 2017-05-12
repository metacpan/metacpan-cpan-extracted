#!/usr/bin/env perl

use Test::Roo;
use DBI;
use DBIx::Introspector;

has [qw(
   dsn user password rdbms_engine
   connected_introspector_driver unconnected_introspector_driver
)] => ( is => 'ro' );

test basic => sub {
   my $self = shift;

   my $d = DBIx::Introspector->new( drivers => '2013-12.01' );

   is(
      $d->get(undef, $self->dsn, '_introspector_driver'),
      $self->unconnected_introspector_driver,
      'unconnected introspector driver'
   );
   my $dbh = DBI->connect($self->dsn, $self->user, $self->password);
   is(
      $d->get($dbh, $self->dsn, '_introspector_driver'),
      $self->connected_introspector_driver,
      'connected introspector driver'
   );
};

run_me(SQLite => {
   connected_introspector_driver => 'SQLite',
   unconnected_introspector_driver => 'SQLite',
   dsn => 'dbi:SQLite::memory:',
});

run_me('ODBC SQL Server', {
   dsn      => $ENV{DBIITEST_ODBC_MSSQL_DSN},
   user     => $ENV{DBIITEST_ODBC_MSSQL_USER},
   password => $ENV{DBIITEST_ODBC_MSSQL_PASSWORD},

   connected_introspector_driver => 'ODBC_Microsoft_SQL_Server',
   unconnected_introspector_driver => 'ODBC',
}) if $ENV{DBIITEST_ODBC_MSSQL_DSN};

run_me(Pg => {
   dsn      => $ENV{DBIITEST_PG_DSN},
   user     => $ENV{DBIITEST_PG_USER},
   password => $ENV{DBIITEST_PG_PASSWORD},

   connected_introspector_driver => 'Pg',
   unconnected_introspector_driver => 'Pg',
}) if $ENV{DBIITEST_PG_DSN};

run_me(mysql => {
   dsn      => $ENV{DBIITEST_MYSQL_DSN},
   user     => $ENV{DBIITEST_MYSQL_USER},
   password => $ENV{DBIITEST_MYSQL_PASSWORD},

   connected_introspector_driver => 'mysql',
   unconnected_introspector_driver => 'mysql',
}) if $ENV{DBIITEST_MYSQL_DSN};

done_testing;

