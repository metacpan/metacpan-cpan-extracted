use strict;
use warnings;
use Test::More tests => 2;
use DBI;
my $dbh = DBI->connect('dbi:Spanner:projects/p/instances/i/databases/d', '', '');
my $sth1 = $dbh->prepare('SELECT 1');
my $sth2 = $dbh->prepare('SELECT 2');
ok($sth1->execute(), 'sth1 executed');
ok($sth2->execute(), 'sth2 executed');
