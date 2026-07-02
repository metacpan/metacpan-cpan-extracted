use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

# Exercises RowManager-level behaviors: cache_lookup, vivify returning an
# already-loaded row (and warning when that drops differing data),
# insert_or_save with nothing to write, and the connection's
# find_or_insert / update_or_insert helpers.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir  = tempdir(CLEANUP => 1);
my $file = "$dir/manager.sqlite";
my $dsn  = "dbi:SQLite:dbname=$file";

{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE gadgets (gadget_id INTEGER PRIMARY KEY, name TEXT NOT NULL UNIQUE, color TEXT)');
    $dbh->disconnect;
}

sub db_count {
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    my ($count) = $dbh->selectrow_array('SELECT COUNT(*) FROM gadgets');
    $dbh->disconnect;
    return $count;
}

my $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
my $h   = $con->handle('gadgets');

subtest insert_or_save_with_no_data_croaks => sub {
    my $row = $h->vivify({name => 'temp'});
    $row->discard;

    ok(!$row->is_stored,   "row is not stored");
    ok(!$row->has_pending, "row has no pending data");

    like(
        dies { $row->insert_or_save },
        qr/This row has no data to write/,
        "insert_or_save croaks when there is nothing to write",
    );
};

subtest cache_lookup => sub {
    my $row = $h->insert({name => 'findme', color => 'teal'});
    my $pk  = $row->field('gadget_id');

    my $manager = $con->manager;
    my $source  = $con->source('gadgets');

    my $hit = $manager->cache_lookup(source => $source, fetched => {gadget_id => $pk, name => 'findme'});
    ref_is($hit, $row, "cache_lookup found the cached row by fetched data");

    $hit = $manager->cache_lookup(source => $source, old_primary_key => [$pk]);
    ref_is($hit, $row, "cache_lookup found the cached row by primary key alone");

    my $miss = $manager->cache_lookup(source => $source, old_primary_key => [999_999]);
    ok(!$miss, "cache_lookup returns undef on a miss");
};

subtest vivify_of_loaded_row_returns_existing => sub {
    my $row = $h->insert({name => 'loaded', color => 'red'});
    my $pk  = $row->field('gadget_id');

    # A bare hit (only the primary key, or matching values) returns the loaded
    # row with no warning: nothing was dropped.
    my $hit;
    my $count = warns {
        $hit = $h->vivify({gadget_id => $pk, name => 'loaded', color => 'red'});
    };
    ref_is($hit, $row, "vivify returned the already-loaded row");
    is($count, 0, "no warning when nothing is dropped (matching values)");

    # Differing non-pk data would be silently lost, so vivify warns and still
    # returns the existing row untouched.
    my $got = warnings {
        $hit = $h->vivify({gadget_id => $pk, name => 'shadow', color => 'blue'});
    };
    like(
        $got,
        [qr/returned an already-loaded row.*'color', 'name'.*was not applied/s],
        "vivify warns when the supplied data differs and would be dropped",
    );
    ref_is($hit, $row, "vivify still returned the already-loaded row");
    is($row->field('color'), 'red', "the loaded row's data was not touched");

    ok(lives { $h->vivify({name => 'unloaded', color => 'green'}) }, "vivify without a conflicting primary key still works");
};

subtest find_or_insert => sub {
    my $count = db_count();

    my $made = $con->find_or_insert('gadgets', {name => 'felix', color => 'black'});
    ok($made, "got a row back");
    ok($made->is_stored, "row was inserted");
    is(db_count(), $count + 1, "one new database row");
    is($made->field('color'), 'black', "row has the supplied data");

    my $found = $con->find_or_insert('gadgets', {name => 'felix', color => 'black'});
    ref_is($found, $made, "second call found the existing row instead of inserting");
    is(db_count(), $count + 1, "no extra database row");
};

subtest update_or_insert => sub {
    my $count = db_count();

    # The upsert resolves conflicts on the primary key, so supply one.
    my $made = $con->update_or_insert('gadgets', {gadget_id => 1000, name => 'oscar', color => 'white'});
    ok($made, "got a row back");
    ok($made->is_stored, "row was inserted");
    is(db_count(), $count + 1, "one new database row");

    my $updated = $con->update_or_insert('gadgets', {gadget_id => 1000, name => 'oscar', color => 'grey'});
    ok($updated->is_stored, "still stored");
    is(db_count(), $count + 1, "no extra database row");
    is($updated->field('color'), 'grey', "conflicting row was updated");

    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    my ($color) = $dbh->selectrow_array('SELECT color FROM gadgets WHERE gadget_id = 1000');
    $dbh->disconnect;
    is($color, 'grey', "database reflects the update");
};

done_testing;
