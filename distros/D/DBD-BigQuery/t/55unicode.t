use strict;
use warnings;
use utf8;
use Test::More tests => 2;
use DBI;
my $dbh = DBI->connect('dbi:BigQuery:project=p;dataset=d', '', '');
my $sth = $dbh->prepare('SELECT "日本語"');
ok($sth->execute(), 'Unicode query executed');
ok($sth->fetchrow_arrayref(), 'Fetched row');
