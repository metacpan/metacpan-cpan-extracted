use strict;
use warnings;
use utf8;
use Test::More tests => 1;
use DBI;
my $dbh = DBI->connect('dbi:Spanner:projects/p/instances/i/databases/d', '', '');
my $sth = $dbh->prepare('SELECT "🚀"');
ok($sth->execute(), 'UTF8MB4 emoji query executed');
