use strict;
use warnings;
use Test::More tests => 1;
use DBI;
my $dbh = DBI->connect('dbi:BigQuery:project=p;dataset=d', '', '');
my $sth = $dbh->prepare('SELECT * FROM t');
$sth->execute();
is_deeply($sth->FETCH('NAME'), ['id', 'data'], 'Field list retrieved');
