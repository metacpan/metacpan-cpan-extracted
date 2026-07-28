use strict;
use warnings;
use Test::More tests => 2;
use DBI;
my $dbh = DBI->connect('dbi:Spanner:projects/p/instances/i/databases/d', '', '', { RaiseError => 0 });
ok($dbh->begin_work(), 'begin_work succeeded without RaiseError');
ok($dbh->commit(), 'commit succeeded');
