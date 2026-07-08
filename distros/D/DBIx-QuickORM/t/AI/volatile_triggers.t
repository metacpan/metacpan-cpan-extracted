use Test2::V0 '!meta', '!pass';
use DBI;
use File::Temp qw/tempdir/;

# Coverage for volatile detection from triggers. A best-effort parse flags the
# columns an insert/update trigger is seen to set. When the parse resolves those
# columns there is nothing to warn about; when a table has such a trigger but the
# parse cannot name a single column it sets, a per-table warning is emitted so
# the user can mark the column volatile. Asserting the table volatile-free
# (no_volatile, via quick() or => 1) skips both the flagging and the warning.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

# audited.rev is bumped by an AFTER INSERT trigger whose UPDATE ... SET rev = ...
# the parser can read, so rev is flagged volatile with no warning. rev has no
# default, so the trigger is its only source of volatility (a default would
# auto-mark it regardless of no_volatile).
sub setup_resolvable {
    my $dir = tempdir(CLEANUP => 1);
    my $dsn = "dbi:SQLite:dbname=$dir/resolvable.sqlite";
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
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

# evented has an AFTER INSERT trigger that only writes a *different* table, so
# the best-effort parse cannot name any column of evented that the trigger sets.
sub setup_opaque {
    my $dir = tempdir(CLEANUP => 1);
    my $dsn = "dbi:SQLite:dbname=$dir/opaque.sqlite";
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE audit_log (id INTEGER PRIMARY KEY, msg TEXT)');
    $dbh->do('CREATE TABLE evented   (id INTEGER PRIMARY KEY, name TEXT)');
    $dbh->do(<<'    SQL');
        CREATE TRIGGER evented_log AFTER INSERT ON evented
        BEGIN
            INSERT INTO audit_log (msg) VALUES ('inserted');
        END
    SQL
    $dbh->disconnect;
    return $dsn;
}

subtest detect_no_warn_when_resolved => sub {
    my $dsn = setup_resolvable();
    my $con;
    my $warns = warnings { $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn}) };

    my $t = $con->schema->table('audited');
    ok($t->column('rev')->volatile,   "the trigger-set column 'rev' is flagged volatile");
    ok(!$t->column('name')->volatile, "a column the trigger does not touch is not volatile");
    ok(!(grep { /insert\/update trigger/i } @$warns),
        "no trigger warning when the parse resolved the affected columns")
        or diag join("\n", @$warns);
};

subtest warn_when_unresolved => sub {
    my $dsn = setup_opaque();
    my $con;
    my $warns = warnings { $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn}) };

    my $t = $con->schema->table('evented');
    ok(!$t->column('name')->volatile,
        "no column is flagged when the trigger's effects cannot be resolved");
    ok((grep { /insert\/update trigger/i } @$warns),
        "a table whose trigger effects cannot be resolved emits a per-table warning")
        or diag join("\n", @$warns);
};

subtest no_volatile_skips_flagging => sub {
    my $dsn = setup_resolvable();
    my $con;
    my $warns = warnings { $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn}, no_volatile => ["audited"]) };

    my $t = $con->schema->table('audited');
    ok(!$t->column('rev')->volatile, "asserting the table volatile-free skips trigger flagging");
    ok(!(grep { /insert\/update trigger/i } @$warns), "no trigger warning when the table is asserted volatile-free")
        or diag join("\n", @$warns);
};

subtest no_volatile_skips_warning => sub {
    my $dsn = setup_opaque();
    my $warns = warnings { DBIx::QuickORM->quick(credentials => {dsn => $dsn}, no_volatile => ["evented"]) };
    ok(!(grep { /insert\/update trigger/i } @$warns),
        "the unresolved-trigger warning is silenced when the table is asserted volatile-free")
        or diag join("\n", @$warns);
};

subtest suppress_all => sub {
    my $dsn = setup_opaque();
    my $warns = warnings { DBIx::QuickORM->quick(credentials => {dsn => $dsn}, no_volatile => 1) };
    ok(!(grep { /insert\/update trigger/i } @$warns), "no_volatile => 1 silences the warning for every table")
        or diag join("\n", @$warns);
};

done_testing;
