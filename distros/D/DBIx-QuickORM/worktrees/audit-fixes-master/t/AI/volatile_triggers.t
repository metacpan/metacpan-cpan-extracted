use Test2::V0 '!meta', '!pass';
use DBI;
use File::Temp qw/tempdir/;

# Coverage for volatile detection from triggers: a best-effort parse flags the
# columns an insert/update trigger is seen to set, a per-table warning is emitted
# when a table has such a trigger, and asserting the table volatile-free
# (no_volatile, via quick() or => 1) skips both the flagging and the warning.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

sub setup_db {
    my $dir = tempdir(CLEANUP => 1);
    my $dsn = "dbi:SQLite:dbname=$dir/trig.sqlite";
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    # rev has no default, so its only source of volatility is the trigger below
    # (a default would auto-mark it volatile regardless of no_volatile).
    $dbh->do('CREATE TABLE audited (id INTEGER PRIMARY KEY, name TEXT, rev INTEGER)');
    $dbh->do(<<'    SQL');
        CREATE TRIGGER audited_bump AFTER INSERT ON audited
        BEGIN
            UPDATE audited SET rev = rev + 1 WHERE id = NEW.id;
        END
    SQL
    $dbh->disconnect;
    return $dsn;
}

subtest detect_and_warn => sub {
    my $dsn = setup_db();
    my $con;
    my $warns = warnings { $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn}) };

    my $t = $con->schema->table('audited');
    ok($t->column('rev')->volatile,   "the trigger-set column 'rev' is flagged volatile");
    ok(!$t->column('name')->volatile, "a column the trigger does not touch is not volatile");
    ok((grep { /insert\/update trigger/i } @$warns), "a per-table trigger warning is emitted")
        or diag join("\n", @$warns);
};

subtest suppress_with_quick_no_volatile => sub {
    my $dsn = setup_db();
    my $con;
    my $warns = warnings { $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn}, no_volatile => ["audited"]) };

    my $t = $con->schema->table('audited');
    ok(!$t->column('rev')->volatile, "asserting the table volatile-free skips trigger flagging");
    ok(!(grep { /insert\/update trigger/i } @$warns), "no trigger warning when the table is asserted volatile-free")
        or diag join("\n", @$warns);
};

subtest suppress_all => sub {
    my $dsn = setup_db();
    my $warns = warnings { DBIx::QuickORM->quick(credentials => {dsn => $dsn}, no_volatile => 1) };
    ok(!(grep { /insert\/update trigger/i } @$warns), "no_volatile => 1 silences the warning for every table")
        or diag join("\n", @$warns);
};

done_testing;
