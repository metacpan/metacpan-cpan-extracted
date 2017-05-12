use strict;
use warnings;
use Test::More;
BEGIN {
    eval { require Test::postgresql };
    if ($@) {
        plan skip_all => "Test::postgresql is not installed";
    }
}
use DBI;
use DBIx::TransactionManager;

my $pgsql = Test::postgresql->new
    or plan skip_all => $Test::postgresql::errstr;

my $dbh = DBI->connect($pgsql->dsn);
$dbh->{"Warn"} = 0;
$dbh->do(q{
    CREATE TABLE job (
        id   SERIAL PRIMARY KEY,
        func TEXT NOT NULL
    )
});

my $tm = DBIx::TransactionManager->new($dbh);

{
    my $txn = $tm->txn_scope;
    $dbh->do("insert into job (func) values ('baz')");
    {
        my $txn2 = $tm->txn_scope;
        $dbh->do("insert into job (func) values ('bab')");
        $txn2->commit;
    }
    $txn->commit;

    my $row = $dbh->selectrow_hashref('select * from job');
    ok $row;
}

done_testing;
