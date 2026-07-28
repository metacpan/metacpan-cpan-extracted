use strict;
use warnings;
use Test::More tests => 2;
use DBI;
my $dbh = DBI->connect('dbi:Spanner:projects/p/instances/i/databases/d', '', '');
ok($dbh, 'Connected');
is($dbh->FETCH('spanner_db_path'), 'projects/p/instances/i/databases/d', 'Mapped database path');
