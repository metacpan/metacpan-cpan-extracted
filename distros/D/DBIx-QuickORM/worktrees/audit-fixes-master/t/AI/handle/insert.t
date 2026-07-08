use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

# insert() used to mutate the caller's data hashref in place (injecting
# column defaults and deleting generated columns), and pk-value truthiness
# checks broke legitimate primary key values of 0.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir = tempdir(CLEANUP => 1);
my $dsn = "dbi:SQLite:dbname=$dir/insert.sqlite";

{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do("CREATE TABLE example (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, xxx TEXT NOT NULL DEFAULT 'dflt')");
    $dbh->disconnect;
}

my $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
my $h   = $con->handle('example');

subtest caller_data_not_mutated => sub {
    my $data = {name => 'a'};
    my $row  = $h->insert($data);

    ok($row, "inserted the row");
    is($data, {name => 'a'}, "the caller's data hashref was not mutated");
};

subtest pk_value_zero => sub {
    # An explicit pk of 0 must be honored (truthiness checks used to treat
    # it as 'missing/auto-generated').
    my $row = $h->insert({id => 0, name => 'zero'});
    is($row->field('id'), 0, "inserted a row with primary key 0");

    my $fetched = $con->handle('example')->one({id => 0});
    is($fetched->field('name'), 'zero', "fetched the pk-0 row back");

};

subtest non_returning_insert_preserves_supplied_pk => sub {
    {
        my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
        $dbh->do('CREATE TABLE natural (id TEXT PRIMARY KEY, name TEXT NOT NULL)');
        $dbh->disconnect;
    }

    my $con2 = DBIx::QuickORM->quick(credentials => {dsn => $dsn});

    {
        package DBIx::QuickORM::Dialect::SQLite::NoReturningInsert;
        use parent -norequire, 'DBIx::QuickORM::Dialect::SQLite';
        sub supports_returning_insert { 0 }
    }

    bless $con2->dialect, 'DBIx::QuickORM::Dialect::SQLite::NoReturningInsert';

    my $h2  = $con2->handle('natural');
    my $row = $h2->insert({id => 'abc', name => 'natural'});

    is($row->field('id'), 'abc', "non-returning insert preserves a caller-supplied text primary key");

    my $again = $h2->by_id('abc');
    ref_is($again, $row, "identity cache is keyed under the supplied primary key");
    is($h2->count, 1, "only the inserted row exists");
};

subtest pk_update_to_zero_rekeys_cache => sub {
    {
        my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
        $dbh->do('CREATE TABLE other (id INTEGER PRIMARY KEY, name TEXT NOT NULL)');
        $dbh->disconnect;
    }

    my $con2 = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
    my $h2   = $con2->handle('other');

    # Updating a pk to 0 must rekey the cache instead of leaving the row
    # cached under the old key.
    my $row = $h2->insert({id => 50, name => 'fifty'});
    $h2->where({id => 50})->update({id => 0});

    ok(!$con2->state_cache_lookup($h2->source, [50]), "old pk is no longer cached after a pk change to 0");
    ref_is($con2->state_cache_lookup($h2->source, [0]), $row, "row moved to pk 0 in the cache");
    is($row->field('id'), 0, "row identity reflects the new pk 0");
};

done_testing;
