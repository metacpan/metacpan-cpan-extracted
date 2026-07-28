use strict;
use warnings;
use Test::More tests => 1;
use DBI;
my $dbh = DBI->connect('dbi:BigQuery:project=p;dataset=d', '', '');
my $sth = $dbh->prepare('SELECT B"10101"');
ok($sth->execute(), 'Bit BYTES type executed');
