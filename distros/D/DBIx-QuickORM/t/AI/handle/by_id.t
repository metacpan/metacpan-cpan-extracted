use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir = tempdir(CLEANUP => 1);
my $dsn = "dbi:SQLite:dbname=$dir/by_id.sqlite";

{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL, color TEXT)');
    $dbh->do('CREATE TABLE pairs (a INTEGER NOT NULL, b INTEGER NOT NULL, label TEXT, PRIMARY KEY (a, b))');
    $dbh->disconnect;
}

my $con   = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
my $users = $con->handle('users');
my $pairs = $con->handle('pairs');

subtest cache_hit_with_extra_constraints => sub {
    my $row = $users->insert({id => 1, name => 'alice', color => 'red'});

    ref_is($users->by_id(1), $row, "bare by_id hits the cache");
    is($users->by_id({id => 1, name => 'alice'})->field('color'), 'red', "matching extra hash constraint can still fetch");
    is($users->by_id({id => 1, name => 'bob'}), undef, "non-matching extra hash constraint does not return the cached row");
};

subtest data_only_cache_hit => sub {
    my $row = $users->by_id(1);

    my $data = $users->data_only->by_id(1);
    ref_ok($data, 'HASH', "data_only by_id cache hit returns a hashref");
    is($data, $row->raw_fields, "data_only by_id cache hit returns raw row data");
};

subtest malformed_primary_key_inputs => sub {
    like(
        dies { $users->by_id({name => 'alice'}) },
        qr/Missing primary key field 'id'/,
        "hash form requires the primary key field",
    );

    like(
        dies { $pairs->by_id(1) },
        qr/Scalar by_id\(\) can only be used with a single-column primary key/,
        "scalar form croaks for compound primary keys",
    );

    like(
        dies { $pairs->by_id([1]) },
        qr/Incorrect primary key field count in by_id\(\): expected 2, got 1/,
        "array form requires every primary key component",
    );
};

subtest undefined_primary_key_values => sub {
    # An undef primary key value must be surfaced, not silently degraded to a
    # "WHERE id IS NULL" lookup that can never match a NOT NULL primary key.
    like(dies { $users->by_id({id => undef}) }, qr/Undefined primary key value in by_id/, "hash form rejects an undef pk value");
    like(dies { $users->by_id([undef]) },       qr/Undefined primary key value in by_id/, "array form rejects an undef pk value");
    like(dies { $users->by_id(undef) },         qr/Undefined primary key value in by_id/, "scalar form rejects an undef pk value");
};

done_testing;
