use Test2::V0 '!meta', '!pass';
use DBI;
use File::Temp qw/tempdir/;

# handle-write I2: upsert() funnels through the shared _insert body, so calling
# it on an already-stored bound row reported the *insert* wording. The message
# now names the actual operation.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir = tempdir(CLEANUP => 1);
my $dsn = "dbi:SQLite:dbname=$dir/x.sqlite";
{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT)');
    $dbh->disconnect;
}

my $con    = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
my $stored = $con->handle('t')->insert({name => 'x'});
ok($stored->in_storage, "row is stored");

like(
    dies { $con->handle('t')->row($stored)->upsert },
    qr/Cannot upsert a row that is already stored/,
    "upsert() on a stored bound row names 'upsert', not 'insert'",
);

like(
    dies { $con->handle('t')->row($stored)->insert },
    qr/Cannot insert a row that is already stored/,
    "insert() on a stored bound row still names 'insert'",
);

done_testing;
