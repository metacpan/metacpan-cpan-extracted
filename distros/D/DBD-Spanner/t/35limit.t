use strict;
use warnings;
use Test::More tests => 1;
use DBI;
my $dbh = DBI->connect('dbi:Spanner:projects/p/instances/i/databases/d', '', '');
my $sth = $dbh->prepare('SELECT id FROM users LIMIT 10 OFFSET 0');
ok($sth->execute(), 'LIMIT OFFSET query executed');
