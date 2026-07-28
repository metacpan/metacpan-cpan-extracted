use strict;
use warnings;
use Test::More tests => 2;
use DBI;
my $dbh = DBI->connect('dbi:Spanner:projects/p/instances/i/databases/d', '', '');
ok($dbh->FETCH('Active'), 'Active');
$dbh->disconnect();
ok(!$dbh->FETCH('Active'), 'Inactive');
