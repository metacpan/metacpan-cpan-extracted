use strict;
use warnings;
use Test::More tests => 2;
use DBI;
my $dbh = DBI->connect('dbi:Spanner:projects/p/instances/i/databases/d', '', '');
my $sth = $dbh->prepare('SELECT 1');
is($sth->FETCH('NUM_OF_FIELDS'), 2, 'NUM_OF_FIELDS');
is_deeply($sth->FETCH('NAME'), ['id', 'val'], 'NAME');
