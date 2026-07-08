use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

# A handle bound to a row whose table has no primary key cannot derive a
# WHERE clause. delete()/update() must croak BEFORE any SQL runs, otherwise
# they execute unconstrained statements that hit every row in the table.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir = tempdir(CLEANUP => 1);
my $dsn = "dbi:SQLite:dbname=$dir/no_pk_guard.sqlite";

{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE example (name TEXT NOT NULL)');
    $dbh->disconnect;
}

my $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
my $h   = $con->handle('example');

my $row1 = $h->insert({name => 'a'});
my $row2 = $h->insert({name => 'b'});
my $row3 = $h->insert({name => 'c'});

is($h->count, 3, "3 rows in the pk-less table");

subtest delete_guard => sub {
    like(
        dies { $con->handle($row1)->delete },
        qr/Cannot delete a row bound to a handle when its table has no primary key/,
        "row-bound delete croaks when no WHERE can be derived"
    );

    is($h->count, 3, "no rows were deleted");
};

subtest update_guard => sub {
    like(
        dies { $con->handle($row1)->update({name => 'z'}) },
        qr/Cannot update a row bound to a handle when its table has no primary key/,
        "row-bound update croaks when no WHERE can be derived"
    );

    is($h->count({name => 'z'}), 0, "no rows were updated");
};

subtest read_guard => sub {
    # Reads must guard the same way writes do: without a primary key there is
    # no WHERE to identify the bound row, so a read would scan the whole table
    # (and could silently return the wrong row) instead of the bound one.
    for my $method (qw/all first one iterator/) {
        like(
            dies { $con->handle($row2)->$method },
            qr/no primary key/,
            "row-bound $method() croaks when no WHERE can be derived",
        );
    }

    like(
        dies { $con->handle($row2)->data_only->first },
        qr/no primary key/,
        "row-bound data_only read croaks instead of returning the wrong row",
    );

    # Ordinary where-based reads are unaffected.
    ok(lives { $h->where({name => 'a'})->all }, "where-based reads still work without a primary key");
};

subtest unbound_operations_still_work => sub {
    ok(lives { $h->where({name => 'b'})->update({name => 'bb'}) }, "where-based update still works without a pk")
        or note $@;
    is($h->count({name => 'bb'}), 1, "the targeted row was updated");

    ok(lives { $h->delete({name => 'bb'}) }, "where-based delete still works without a pk")
        or note $@;
    is($h->count, 2, "only the targeted row was deleted");
};

subtest cached_bulk_delete_without_pk => sub {
    ok($con->state_does_cache, "connection is using the cached row manager");

    $h->insert({name => 'd'});
    $h->insert({name => 'e'});
    is($h->count, 4, "reseeded rows for the bulk delete");

    ok(lives { $h->where({name => {-in => ['d', 'e']}})->delete }, "bulk delete on a pk-less cached table does not enter the pk cache path")
        or note $@;
    is($h->count({name => {-in => ['d', 'e']}}), 0, "bulk delete removed the targeted pk-less rows");
    is($h->count, 2, "bulk delete left the other pk-less rows alone");
};

done_testing;
