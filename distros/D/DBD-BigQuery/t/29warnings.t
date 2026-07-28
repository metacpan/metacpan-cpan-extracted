use strict;
use warnings;
use Test::More tests => 1;
use DBI;
my $dbh = DBI->connect('dbi:BigQuery:project=p;dataset=d', '', '');
is($dbh->FETCH('Warn'), 1, 'Warn attribute default 1');
