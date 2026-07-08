use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir = tempdir(CLEANUP => 1);
my $dsn = "dbi:SQLite:dbname=$dir/cas.sqlite";

{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE docs (id INTEGER PRIMARY KEY, revision INTEGER, note TEXT)');
    $dbh->do(q{INSERT INTO docs (id, revision, note) VALUES (1, 1, 'loaded'), (2, 1, NULL)});
    $dbh->disconnect;
}

my $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
my $h   = $con->handle('docs');

subtest field_list_guard_requires_fetched_field => sub {
    my $row = $h->fields(['id', 'revision'])->by_id(1);

    like(
        dies { $row->cas('note', {revision => 2}) },
        qr/cas\(\) guard field 'note' was not fetched for this row/,
        "field-list CAS guard croaks when the guard field was never fetched",
    );

    is($h->by_id(1)->field('revision'), 1, "failed CAS did not update the row");
};

subtest fetched_null_guard_still_works => sub {
    my $row = $h->fields(['id', 'revision', 'note'])->by_id(2);

    ok($row->cas('note', {note => 'set'}), "field-list CAS guard still works for a fetched NULL value");
    is($row->field('note'), 'set', "row was updated");
};

done_testing;
