use strict;
use warnings;
use Test::More tests => 1;
use DBI;
my $dbh = DBI->connect('dbi:Spanner:projects/p/instances/i/databases/d', '', '');
my $sth = $dbh->prepare('SELECT CAST(? AS BYTES)');
ok($sth->execute('A' x 10000), 'Large BYTES blob executed');
