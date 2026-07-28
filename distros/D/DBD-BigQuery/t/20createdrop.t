use strict;
use warnings;
use Test::More tests => 2;
use DBI;
my $dbh = DBI->connect('dbi:BigQuery:project=p;dataset=d', '', '');
ok($dbh->do('CREATE TABLE d.t (id INT64)'), 'CREATE TABLE');
ok($dbh->do('DROP TABLE d.t'), 'DROP TABLE');
