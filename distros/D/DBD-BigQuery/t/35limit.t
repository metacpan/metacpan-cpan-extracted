use strict;
use warnings;
use Test::More tests => 1;
use DBI;
my $dbh = DBI->connect('dbi:BigQuery:project=p;dataset=d', '', '');
my $sth = $dbh->prepare('SELECT id FROM t LIMIT 10 OFFSET 0');
ok($sth->execute(), 'LIMIT OFFSET query executed');
