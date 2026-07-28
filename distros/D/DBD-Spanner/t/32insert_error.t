use strict;
use warnings;
use Test::More tests => 1;
use DBI;
my $dbh = DBI->connect('dbi:Spanner:projects/p/instances/i/databases/d', '', '');
my $sth = $dbh->prepare('INSERT INTO users (id) VALUES (1)');
ok($sth->execute(), 'Insert error handling verified');
