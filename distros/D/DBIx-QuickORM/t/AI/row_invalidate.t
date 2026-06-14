use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

# Exercises row invalidation: RowManager->invalidate given only a row, and
# the refresh / lazy field fetch paths that invalidate a row whose database
# record no longer exists.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir  = tempdir(CLEANUP => 1);
my $file = "$dir/invalidate.sqlite";
my $dsn  = "dbi:SQLite:dbname=$file";

{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE things (thing_id INTEGER PRIMARY KEY, name TEXT NOT NULL, notes TEXT)');
    $dbh->disconnect;
}

sub db_delete {
    my ($pk) = @_;
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('DELETE FROM things WHERE thing_id = ?', undef, $pk);
    $dbh->disconnect;
}

my $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
my $h   = $con->handle('things');

subtest invalidate_with_only_a_row => sub {
    my $row = $h->insert({name => 'goner'});
    my $pk  = $row->field('thing_id');

    ok($row->is_valid, "row starts valid");

    ok(
        lives { $con->state_invalidate(source => $con->source('things'), row => $row, reason => 'test invalidation') },
        "invalidate works when given only a row",
    );

    ok(!$row->is_valid, "row is invalid");
    like(dies { $row->field('name') }, qr/test invalidation/, "invalidation reason is reported");

    ok(!$con->state_cache_lookup('things', {thing_id => $pk}), "row was removed from the cache");
};

subtest refresh_of_deleted_row_invalidates => sub {
    my $row = $h->insert({name => 'refresh_me'});
    my $pk  = $row->field('thing_id');

    db_delete($pk);

    like(
        dies { $row->refresh },
        qr/Cannot refresh: this row no longer exists in the database/,
        "refresh croaks when the database row is gone",
    );

    ok(!$row->is_valid, "row was invalidated");
    like(dies { $row->field('name') }, qr/no longer exists in the database/, "the invalidation reason explains why");
};

subtest lazy_field_fetch_of_deleted_row_invalidates => sub {
    my $full = $h->insert({name => 'lazy', notes => 'some notes'});
    my $pk   = $full->field('thing_id');
    $full = undef;

    # Drop the cached copy so the partial fetch builds a fresh row missing
    # the 'notes' field.
    my $row = $con->handle('things', fields => ['thing_id', 'name'], where => {thing_id => $pk})->one;
    ok(!exists $row->stored_data->{notes}, "notes field was not fetched");

    db_delete($pk);

    like(
        dies { $row->field('notes') },
        qr/Cannot fetch field 'notes': this row no longer exists in the database/,
        "lazy field fetch croaks when the database row is gone",
    );

    ok(!$row->is_valid, "row was invalidated");
};

done_testing;
