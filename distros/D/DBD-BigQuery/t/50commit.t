use strict;
use warnings;
use Test::More tests => 2;
use DBI;
my $dbh = DBI->connect('dbi:BigQuery:project=p;dataset=d', '', '');
$dbh->begin_work();
ok($dbh->commit(), 'Commit executed');
ok(!$dbh->FETCH('in_transaction'), 'Transaction cleared');
