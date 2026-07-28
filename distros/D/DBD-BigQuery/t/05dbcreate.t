use strict;
use warnings;
use Test::More tests => 2;
use DBI;
my $dbh = DBI->connect('dbi:BigQuery:project=p;dataset=d', '', '');
ok($dbh, 'Connected');
is($dbh->FETCH('bq_dataset'), 'd', 'Mapped dataset name');
