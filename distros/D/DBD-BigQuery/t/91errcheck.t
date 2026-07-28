use strict;
use warnings;
use Test::More tests => 2;
use DBI;
my $dbh = DBI->connect('dbi:BigQuery:project=p;dataset=d', '', '');
my $sth = $dbh->prepare('SELECT 1');
$sth->execute();
ok(!defined $DBD::BigQuery::err || $DBD::BigQuery::err == 0, 'No err');
ok(!defined $DBD::BigQuery::errstr || $DBD::BigQuery::errstr eq '', 'No errstr');
