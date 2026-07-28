use strict;
use warnings;
use Test::More tests => 1;
use DBI;
my $dbh = DBI->connect('dbi:BigQuery:project=p;dataset=d', '', '');
$dbh->STORE('InvalidCustomAttr', 123);
is($dbh->FETCH('InvalidCustomAttr'), 123, 'Custom attribute stored');
