use strict;
use warnings;
use utf8;
use Test::More tests => 1;
use DBI;
my $dbh = DBI->connect('dbi:Spanner:projects/p/instances/i/databases/d', '', '');
my $sth = $dbh->prepare('SELECT ?', { Async => 1 });
is($sth->execute('テスト'), '0E0', 'Async UTF-8 param returned 0E0');
