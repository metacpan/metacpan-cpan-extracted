use strict;
use warnings;
use Test::More tests => 3;
use DBI;
my $dbh = DBI->connect('dbi:BigQuery:project=p;dataset=d', '', '');
ok($dbh, 'Connected');
is($dbh->FETCH('AutoCommit'), 1, 'AutoCommit default 1');
is($dbh->FETCH('Active'), 1, 'Active handle');
