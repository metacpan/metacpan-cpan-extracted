use strict;
use warnings;
use Test::More tests => 1;
use DBI;
my $dbh = DBI->connect('dbi:Spanner:projects/p/instances/i/databases/d', '', '');
my $sth = $dbh->prepare('SELECT 1');
$sth->execute();
ok($sth->fetchrow_arrayref(), 'Safe fetch without segfault');
