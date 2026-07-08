use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

# Under the base (non-caching) RowManager a row-bound update never passed the
# row object through to the state layer, so the caller's row kept its stale
# stored data (and its pending changes) after a save.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir = tempdir(CLEANUP => 1);
my $dsn = "dbi:SQLite:dbname=$dir/update.sqlite";

{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE example (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL)');
    $dbh->disconnect;
}

my $con = DBIx::QuickORM->quick(
    credentials => {dsn => $dsn},
    row_manager => 'DBIx::QuickORM::RowManager',
);

ok(!$con->state_does_cache, "using the base non-caching row manager");

my $h   = $con->handle('example');
my $row = $h->insert({name => 'a'});

subtest save_updates_row_state => sub {
    $row->update({name => 'b'});

    ok(!$row->has_pending, "no pending data is left on the row after save");
    is($row->stored_data->{name}, 'b', "the row's stored data reflects the update");
    is($row->field('name'), 'b', "field() sees the new value");

    my $fresh = $con->handle('example')->one({id => $row->field('id')});
    is($fresh->field('name'), 'b', "the database actually has the new value");
};

subtest handle_update_with_bound_row => sub {
    $con->handle($row)->update({name => 'c'});

    is($row->stored_data->{name}, 'c', "handle-driven update refreshes the bound row's stored data");
    ok(!$row->has_pending, "no pending data on the bound row");
};

done_testing;
