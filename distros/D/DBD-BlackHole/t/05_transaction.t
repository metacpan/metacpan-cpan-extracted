use strict;
use Test::More 0.98;

use DBI;

my $dbh = DBI->connect('dbi:BlackHole:', 'root', '', {
    AutoCommit => 1,
    PrintError => 0,
    RaiseError => 1,
});

is $dbh->begin_work(), 1;
is $dbh->commit(), 1;

is $dbh->begin_work(), 1;
is $dbh->rollback(), 1;

done_testing;

