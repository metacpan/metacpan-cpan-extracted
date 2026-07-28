use strict;
use warnings;
use Test::More tests => 2;
use DBI;
my $dbh1 = DBI->connect('dbi:BigQuery:project=p;dataset=d', '', '');
$dbh1->disconnect();
my $dbh2 = DBI->connect('dbi:BigQuery:project=p;dataset=d', '', '');
ok($dbh2->FETCH('Active'), 'Reconnected active handle');
is($dbh2->FETCH('bq_dataset'), 'd', 'Dataset preserved');
