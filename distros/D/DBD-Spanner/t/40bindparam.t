use strict;
use warnings;
use Test::More tests => 2;
use DBI;
my $dbh = DBI->connect('dbi:Spanner:projects/p/instances/i/databases/d', '', '');
my $sth = $dbh->prepare('SELECT id FROM users WHERE name = ?');
ok($sth->execute('Alice'), 'Executed bound param');
ok($sth->fetchrow_arrayref(), 'Fetched row');
