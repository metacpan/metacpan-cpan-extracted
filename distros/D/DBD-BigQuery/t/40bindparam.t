use strict;
use warnings;
use Test::More tests => 2;
use DBI;
my $dbh = DBI->connect('dbi:BigQuery:project=p;dataset=d', '', '');
my $sth = $dbh->prepare('SELECT id FROM t WHERE data = ?');
ok($sth->execute('val'), 'Executed bound param');
ok($sth->fetchrow_arrayref(), 'Fetched row');
