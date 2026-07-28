use strict;
use warnings;
use Test::More tests => 2;
use DBI;
my $dbh = DBI->connect('dbi:BigQuery:project=p;dataset=d', '', '');
ok($dbh->FETCH('Active'), 'Active');
$dbh->disconnect();
ok(!$dbh->FETCH('Active'), 'Inactive');
