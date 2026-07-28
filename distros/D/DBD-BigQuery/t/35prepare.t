use strict;
use warnings;
use Test::More tests => 3;
use DBI;
my $dbh = DBI->connect('dbi:BigQuery:project=p;dataset=d', '', '');
my $sth = $dbh->prepare('SELECT 1');
ok($sth, 'Prepared handle');
is($sth->FETCH('NUM_OF_FIELDS'), 2, 'NUM_OF_FIELDS');
is_deeply($sth->FETCH('NAME'), ['id', 'data'], 'NAME attributes');
