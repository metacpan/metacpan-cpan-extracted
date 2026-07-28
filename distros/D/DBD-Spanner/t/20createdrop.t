use strict;
use warnings;
use Test::More tests => 2;
use DBI;
my $dbh = DBI->connect('dbi:Spanner:projects/p/instances/i/databases/d', '', '');
ok($dbh->do('CREATE TABLE users (id INT64) PRIMARY KEY(id)'), 'CREATE TABLE');
ok($dbh->do('DROP TABLE users'), 'DROP TABLE');
