use strict;
use warnings;
use Test::More tests => 2;
use DBI;
use DBI::Const::GetInfoType;
my $dbh = DBI->connect('dbi:Spanner:projects/p/instances/i/databases/d', '', '');
is($dbh->get_info($GetInfoType{'SQL_DBMS_NAME'}), 'Spanner', 'DBMS name');
is($dbh->get_info($GetInfoType{'SQL_ASYNC_MODE'}), 2, 'SQL_ASYNC_MODE is 2');
