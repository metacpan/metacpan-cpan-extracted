use strict;
use warnings;
use Test::More tests => 2;
use DBI;
my $dbh = DBI->connect('dbi:Spanner:projects/p/instances/i/databases/d', '', '');
my $sth = $dbh->prepare('SELECT ?, ?');
ok($sth->execute('-9223372036854775808', '9223372036854775807'), 'INT64 min max');
ok($sth->fetchrow_arrayref(), 'Fetched row');
