use strict;
use warnings;
use Test::More tests => 2;
use DBI;
my $dbh = DBI->connect('dbi:Spanner:projects/p/instances/i/databases/d', '', '');
my $sth = $dbh->prepare('SELECT 1');
$sth->execute();
ok(!defined $DBD::Spanner::err || $DBD::Spanner::err == 0, 'No err');
ok(!defined $DBD::Spanner::errstr || $DBD::Spanner::errstr eq '', 'No errstr');
