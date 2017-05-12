#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use DBIx::Introspector;

my $d = DBIx::Introspector->new( drivers => '2013-12.01' );

$d->decorate_driver_connected(MSSQL => concat_sql => sub { '%s + %s' });
my $n = $d->_drivers_by_name;
is(
   $n->{'ODBC_Microsoft_SQL_Server'}->_get_when_connected({
      drivers_by_name => $n,
      dbh => undef,
      key => 'concat_sql'
   }),
   '%s + %s',
   'ODBC_MSSQL "subclasses" MSSQL'
);

is(
   $d->_drivers_by_name->{'ADO_Microsoft_SQL_Server'}->_get_when_connected({
      drivers_by_name => $n,
      dbh => undef,
      key => 'concat_sql'
   }),
   '%s + %s',
   'ADO_MSSQL "subclasses" MSSQL'
);

done_testing;

