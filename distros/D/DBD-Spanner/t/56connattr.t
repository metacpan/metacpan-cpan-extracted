use strict;
use warnings;
use Test::More tests => 1;
use DBI;
my $dbh = DBI->connect('dbi:Spanner:projects/p/instances/i/databases/d', '', '');
is($dbh->FETCH('Name'), 'projects/p/instances/i/databases/d', 'Connection Name attribute');
