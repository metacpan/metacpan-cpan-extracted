use strict;
use warnings;
use Test::More tests => 2;
use DBI;
my $dbh = DBI->connect('dbi:BigQuery:project=p;dataset=d', '', '');
my $sth = $dbh->prepare('SELECT 1', { Async => 1 });
$sth->execute();
ok($sth->async_read_ready(), 'async_read_ready permitted');
ok($sth->fetch_async_row(), 'fetch_async_row permitted');
