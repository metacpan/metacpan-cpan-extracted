use strict;
use warnings;
use Test::More tests => 2;
use DBI;
my $dbh1 = DBI->connect('dbi:Spanner:projects/p/instances/i/databases/d', '', '');
$dbh1->disconnect();
my $dbh2 = DBI->connect('dbi:Spanner:projects/p/instances/i/databases/d', '', '');
ok($dbh2->FETCH('Active'), 'Reconnected active handle');
is($dbh2->FETCH('spanner_db_path'), 'projects/p/instances/i/databases/d', 'Path preserved');
