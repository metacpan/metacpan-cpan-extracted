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

subtest unbound_operations_still_work => sub {
    ok(lives { $h->where({name => 'b'})->update({name => 'bb'}) }, "where-based update still works without a pk")
        or note $@;
    is($h->count({name => 'bb'}), 1, "the targeted row was updated");

    ok(lives { $h->delete({name => 'bb'}) }, "where-based delete still works without a pk")
        or note $@;
    is($h->count, 2, "only the targeted row was deleted");
};

done_testing;
