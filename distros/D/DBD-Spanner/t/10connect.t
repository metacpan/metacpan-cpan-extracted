use strict;
use warnings;
use Test::More tests => 3;
use DBI;
my $dbh = DBI->connect('dbi:Spanner:projects/p/instances/i/databases/d', '', '');
ok($dbh, 'Connected');
is($dbh->FETCH('AutoCommit'), 1, 'AutoCommit default 1');
is($dbh->FETCH('Active'), 1, 'Active handle');
