use strict;
use warnings;
use Test::More tests => 1;
use DBI;
my $dbh = DBI->connect('dbi:BigQuery:project=p;dataset=d', '', '');
my $sth = $dbh->prepare('SELECT 1');
$sth->execute();
ok($sth->fetchrow_arrayref(), 'Safe fetch without segfault');
