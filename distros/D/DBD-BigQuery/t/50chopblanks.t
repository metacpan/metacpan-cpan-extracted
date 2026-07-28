use strict;
use warnings;
use Test::More tests => 1;
use DBI;
my $dbh = DBI->connect('dbi:BigQuery:project=p;dataset=d', '', '');
$dbh->STORE('ChopBlanks', 1);
is($dbh->FETCH('ChopBlanks'), 1, 'ChopBlanks attribute set');
