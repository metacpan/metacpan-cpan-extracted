use strict;
use warnings;
use Test::More tests => 2;
use DBI;
use DBI::Const::GetInfoType;
my $dbh = DBI->connect('dbi:BigQuery:project=p;dataset=d', '', '');
is($dbh->get_info($GetInfoType{'SQL_DBMS_NAME'}), 'BigQuery', 'DBMS name');
is($dbh->get_info($GetInfoType{'SQL_ASYNC_MODE'}), 2, 'SQL_ASYNC_MODE is 2');
