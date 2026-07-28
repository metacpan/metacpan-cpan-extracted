use strict;
use warnings;
use Test::More tests => 4;
use DBI;
my $dbh = DBI->connect('dbi:Spanner:projects/p/instances/i/databases/d', '', '');
ok($dbh->do('SELECT 1'), 'SELECT supported');
ok($dbh->do('INSERT INTO t (id) VALUES (1)'), 'INSERT supported');
ok($dbh->do('UPDATE t SET id = 2 WHERE id = 1'), 'UPDATE supported');
ok($dbh->do('DELETE FROM t WHERE id = 2'), 'DELETE supported');
