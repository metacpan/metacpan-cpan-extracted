use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

# An upsert whose data consists solely of primary key fields has no non-key
# fields for the conflict UPDATE SET, which used to generate a syntax error
# ('DO UPDATE SET RETURNING ...'). A no-op assignment is injected instead,
# and both the insert and the conflict case must return the row.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir = tempdir(CLEANUP => 1);
my $dsn = "dbi:SQLite:dbname=$dir/upsert.sqlite";

{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE tags (name TEXT NOT NULL PRIMARY KEY)');
    $dbh->disconnect;
}

my $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
my $h   = $con->handle('tags');

subtest insert_case => sub {
    my $row = $h->upsert({name => 'perl'});
    ok($row, "pk-only upsert returned a row when inserting");
    is($row->field('name'), 'perl', "row carries the inserted key");
    is($h->count, 1, "one row in the table");
};

subtest conflict_case => sub {
    my $row = $h->upsert({name => 'perl'});
    ok($row, "pk-only upsert returned a row on conflict");
    is($row->field('name'), 'perl', "row carries the conflicting key");
    is($h->count, 1, "still one row in the table");
};

subtest mixed_still_updates => sub {
    {
        my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
        $dbh->do('CREATE TABLE example (id INTEGER PRIMARY KEY, name TEXT)');
        $dbh->disconnect;
    }

    my $con2 = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
    my $h2   = $con2->handle('example');

    my $row = $h2->upsert({id => 1, name => 'a'});
    is($row->field('name'), 'a', "upsert with non-key fields inserts them");

    my $row2 = $h2->upsert({id => 1, name => 'b'});
    is($row2->field('name'), 'b', "upsert with non-key fields still updates on conflict");
    is($h2->count, 1, "no duplicate row");
};

subtest literal_value_containing_returning => sub {
    {
        my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
        $dbh->do('CREATE TABLE phrases (id INTEGER PRIMARY KEY, note TEXT)');
        $dbh->disconnect;
    }

    my $con2 = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
    my $h2   = $con2->handle('phrases');

    my $row;
    ok(
        lives { $row = $h2->upsert({id => 1, note => \"'contains returning token'"}) },
        "upsert keeps the RETURNING clause separate from a literal value containing the word",
    ) or note $@;

    is($row->field('id'), 1, "upsert returned the row primary key");
    is($h2->by_id(1)->field('note'), 'contains returning token', "literal value was written intact");
};

subtest literal_returning_without_returning_clause => sub {
    # On a dialect with no RETURNING-on-insert support the built statement has
    # no RETURNING clause, so a literal write value containing the word
    # "returning" must not be mistaken for one and split. Exercise qorm_upsert
    # directly since the SQLite Handle path always requests RETURNING.
    {
        my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
        $dbh->do('CREATE TABLE lit (id INTEGER PRIMARY KEY, note TEXT)');
        $dbh->disconnect;
    }

    my $con2 = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
    my $h2   = $con2->handle('lit');
    my $sb   = $h2->sql_builder;

    my $sql = $sb->qorm_upsert(
        source  => $h2->source,
        dialect => $con2->dialect,
        insert  => {id => 1, note => \"'x returning y'"},
    );
    like(
        $sql->{statement},
        qr/VALUES \(\?, 'x returning y'\) ON CONFLICT/,
        "conflict clause follows the intact literal value instead of being spliced into it",
    );
    unlike($sql->{statement}, qr/returning\s+"/i, "no RETURNING clause emitted when none was requested");

    my $sql2 = $sb->qorm_upsert(
        source    => $h2->source,
        dialect   => $con2->dialect,
        insert    => {id => 1, note => \"'x returning y'"},
        returning => ['id'],
    );
    like(
        $sql2->{statement},
        qr/ON CONFLICT.*RETURNING "id"\s*\z/s,
        "a real RETURNING clause is still separated correctly and placed last",
    );
};

done_testing;
