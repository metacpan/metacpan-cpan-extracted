# Test origin: AI
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM;
use DBIx::QuickORM::Test;
use DBIx::QuickORM::Value qw/sql inflated/;

my %AUTO_PK = (
    PostgreSQL => 'SERIAL PRIMARY KEY',
    MySQL      => 'INTEGER AUTO_INCREMENT PRIMARY KEY',
    MariaDB    => 'INTEGER AUTO_INCREMENT PRIMARY KEY',
    SQLite     => 'INTEGER PRIMARY KEY AUTOINCREMENT',
    DuckDB     => "INTEGER PRIMARY KEY DEFAULT nextval('widgets_seq')",
);

my @WIDE = map { "c$_" } 1 .. 19;

sub build_schema {
    my ($dbh, $family) = @_;
    $dbh->do("CREATE SEQUENCE widgets_seq") if $family eq 'DuckDB';
    $dbh->do("CREATE TABLE widgets (id $AUTO_PK{$family}, name VARCHAR(50) NOT NULL UNIQUE, qty INTEGER DEFAULT 7, extra_json TEXT)");
    $dbh->do("CREATE TABLE pairs (a INTEGER NOT NULL, b VARCHAR(10) NOT NULL, val VARCHAR(20), PRIMARY KEY (a, b))");
    $dbh->do("CREATE TABLE nopk (msg VARCHAR(20))");
    $dbh->do("CREATE TABLE wide (id INTEGER NOT NULL PRIMARY KEY, " . join(', ' => map { "$_ INTEGER" } @WIDE) . ")");
}

do_for_all_dbs {
    my ($db, $set) = @_;
    my $family = $set->{family};

    my $dbh = $db->connect;
    build_schema($dbh, $family);

    my $orm     = DBIx::QuickORM->new(dbh => $dbh, row_class => undef);
    my $dialect = $orm->connection->dialect;
    my $ret     = $dialect->supports_returning_insert;
    my $count   = sub { $dbh->selectrow_array("SELECT COUNT(*) FROM $_[0]") };

    subtest count => sub {
        is($orm->insert_many(widgets => [{name => 'a', qty => 7}, {name => 'b', qty => undef}], count => 1), 2, "count returns how many rows went in");
        unlike($dbh->{Statement}, qr/RETURNING/i, "without asking for them back");
        is($dbh->selectall_arrayref("SELECT name, qty FROM widgets ORDER BY name"), [['a', 7], ['b', undef]], "in one statement");
        my ($id) = $dbh->selectrow_array("SELECT id FROM widgets WHERE name = 'a'");
        is($orm->refresh_row(widgets => {id => $id}, db => 0), undef, "Nothing is held as current");

        $orm->insert_many(widgets => [{name => 'v1', extra_json => {k => 1}}, {name => 'v2', extra_json => sql('?', '[2]')}]);
        is($dbh->selectall_arrayref("SELECT extra_json FROM widgets WHERE name LIKE 'v%' ORDER BY name"), [['{"k":1}'], ['[2]']], "Values are deflated; sql() is inlined with its binds");
        $orm->insert_many(widgets => [{name => 'r1', extra_json => '{"raw":1}'}, {name => 'r2', extra_json => inflated([3])}], raw => 1);
        is($dbh->selectall_arrayref("SELECT extra_json FROM widgets WHERE name LIKE 'r%' ORDER BY name"), [['{"raw":1}'], ['[3]']], "raw sends values as given, but inflated() is still deflated");
    };

    subtest no_rows => sub {
        my $sent = 0;
        my $seen = sub { $sent++; return };
        local $dbh->{Callbacks} = {prepare => $seen, do => $seen, begin_work => $seen};
        is($orm->insert_many(widgets => []),             [],   "No rows inserts none and returns an empty arrayref");
        is([$orm->insert_many(widgets => [])],           [[]], "in list context too");
        is($orm->insert_many(widgets => [], count => 1), 0,    "or 0 with count");
        $orm->insert_many(widgets => []);
        is($sent, 0, "without sending anything");
    };

    subtest croaks => sub {
        like(dies { $orm->insert_many(widgets => [{name => 'x'}, {qty => 1}]) },              qr/^insert_many\(\) into 'widgets' needs the same fields in every row, but row 1 differs/, "Rows with different fields croak");
        like(dies { $orm->insert_many(widgets => [{name => 'x'}, {name => 'y', qty => 1}]) }, qr/^insert_many\(\) into 'widgets' needs the same fields in every row/,                    "even when one has more");
        like(dies { $orm->insert_many(widgets => {}) },                                       qr/^insert_many\(\) needs an arrayref of rows/,                                            "Rows not in an arrayref croak");
        like(dies { $orm->insert_many(widgets => [{}]) },                                     qr/^insert_many\(\) into 'widgets' needs at least one field in each row/,                  "An empty row croaks");
        like(dies { $orm->insert_many(widgets => [{nope => 1}]) },                            qr/^The table 'widgets' has no field 'nope'/,                                              "An unknown field croaks");
        like(dies { $orm->insert_many(widgets => [{name => 'x'}], bogus => 1) },              qr/^Unknown argument\(s\) to insert_many\(\): bogus/,                                      "An unknown argument croaks");
        like(dies { $orm->insert_many(widgets => [{name => 'x'}], returning => 1) },          qr/^Unknown argument\(s\) to insert_many\(\): returning/,                                  "returning is gone");
        like(dies { $orm->insert_many(widgets => [{name => 'x'}], count => 1, data => 1) },   qr/^Unknown argument\(s\) to insert_many\(\): data/,                                       "count takes no data");
        is($count->('widgets'), 6, "Nothing was sent");
    };

    subtest rows => sub {
        if ($ret) {
            my $rows = $orm->insert_many(widgets => [{name => 'ret2', qty => 7}, {name => 'ret1', qty => 1}]);
            is($rows, [{id => T(), name => 'ret2', qty => 7, extra_json => undef}, {id => T(), name => 'ret1', qty => 1, extra_json => undef}], "Outside void context it returns an arrayref of whole rows through RETURNING, in order");
            ok($orm->is_canon(widgets => $_), "held as current") for @$rows;

            is($orm->insert_many(nopk  => [{msg => 'a'}, {msg => 'b'}]),       [{msg => 'a'}, {msg => 'b'}],       "A table without a primary key returns its rows");
            is($orm->insert_many(pairs => [{a   => 9, b => 'x', val => 'v'}]), [{a   => 9, b => 'x', val => 'v'}], "A compound key");
        }
        else {
            like(dies { my $r = $orm->insert_many(widgets => [{name => 'ret1'}]) },                                 qr/^insert_many\(\) into 'widgets' cannot return rows unless every row carries its whole primary key.*count => 1/, "Without RETURNING, generated keys cannot come back");
            like(dies { my $r = $orm->insert_many(nopk    => [{msg  => 'a'}]) },                                    qr/^insert_many\(\) into 'nopk' cannot return rows: the table has no primary key.*count => 1/,                     "and a table without a primary key croaks");
            like(dies { my $r = $orm->insert_many(pairs   => [{a    => 1, b => 'x'}, {a => 2, b => sql("'y'")}]) }, qr/cannot return rows unless every row carries its whole primary key/,                                             "a key from sql() is not carried");
            is([$count->('nopk'), $count->('pairs')], [0, 0], "before anything is sent");

            my $rows = $orm->insert_many(widgets => [{id => 1001, name => 'ret2'}, {id => 1000, name => 'ret1'}]);
            is($rows, [{id => 1001}, {id => 1000}], "With every primary key given, rows hold only the key, in the given order");
            ok($orm->is_canon(widgets => $_), "held as current") for @$rows;
            is($orm->insert_many(pairs => [{a => 9, b => 'x', val => 'v'}]), [{a => 9, b => 'x'}], "A compound key");
        }

        is([$orm->insert_many(pairs => [{a => 20, b => 's'}, {a => 21, b => 's'}])], [[T(), T()]], "In list context too, one arrayref");

        is($orm->insert_many(nopk => [{msg => 'cnt'}, {msg => 'cnt'}], count => 1), 2, "count works on every database, keyless tables included");
        unlike($dbh->{Statement}, qr/RETURNING/i, "and asks for nothing back");

        $orm->insert_many(nopk => [{msg => 'void'}]);
        unlike($dbh->{Statement}, qr/RETURNING/i, "Void context asks for nothing back");
        is($dbh->selectrow_array("SELECT COUNT(*) FROM nopk WHERE msg = 'void'"), 1, "and nothing croaks");
    };

    subtest batches => sub {
        my $per  = int($dialect->bind_limit / 20);
        my @rows = map {
            my $i = $_;
            +{id => $i, map { $WIDE[$_] => $i + $_ } 0 .. $#WIDE}
        } 1 .. 2 * $per + 1;

        my $inserts = 0;
        my $held    = $orm->insert(pairs => {a => 40, b => 'held'});
        local $dbh->{Callbacks} = {prepare => sub { $inserts++ if $_[1] =~ m/^INSERT/; return }};
        is($orm->insert_many(wide => \@rows, count => 1), scalar(@rows), "Every row goes in, the count summed over the statements");
        is($inserts,                                      3,             "in as many statements as the bind limit needs");
        ok($orm->is_canon(pairs => $held), "Its transaction leaves unrelated rows held as current");
        is($count->('wide'),                                                          scalar(@rows), "all of them");
        is($dbh->selectrow_array("SELECT c19 FROM wide WHERE id = " . scalar(@rows)), @rows + 18,    "with their values");

        $dbh->do("DELETE FROM wide");
        $rows[-1]->{id} = 1;
        my $err = dies { $orm->insert_many(wide => \@rows) };
        is($err->kind,       'unique_violation', "A failing statement throws") or diag "$err";
        is($count->('wide'), 0,                  "and the earlier statements are rolled back with it");
        $rows[-1]->{id} = scalar(@rows);

        if ($ret) {
            my $got = $orm->insert_many(wide => \@rows);
            is([map { $_->{id} } @$got], [map { $_->{id} } @rows], "The rows returned gather every statement's");
            $dbh->do("DELETE FROM wide");
        }

        $orm->txn(sub {
            $orm->insert_many(wide => \@rows);
            is($count->('wide'), scalar(@rows), "Inside a transaction (on DuckDB, without a savepoint)");
            $_[0]->rollback;
        });
        is($count->('wide'), 0, "the rows go with it");
    };

    subtest savepoint => sub {
        skip_all "the backend has no savepoints" unless $dialect->supports_savepoints;

        my $txn = $orm->txn;
        my $err = dies { $orm->insert_many(pairs => [{a => 50, b => 'dup'}, {a => 50, b => 'dup'}]) };
        is($err->kind, 'unique_violation', "One failing statement inside a transaction throws");
        ok(lives { $orm->insert(pairs => {a => 51, b => 'after'}) }, "but its savepoint leaves the transaction usable") or diag $@;
        $txn->commit;
        is($dbh->selectall_arrayref("SELECT a FROM pairs WHERE a IN (50, 51)"), [[51]], "so the later write commits");
    };

    subtest handle => sub {
        my $h = $orm->handle('pairs');
        is($h->insert_many([{a => 5, b => 'h'}, {a => 6, b => 'h'}], count => 1), 2,                                                              "A table handle delegates insert_many");
        is($h->insert_many([{a => 7, b => 'h'}]),                                 [$ret ? {a => 7, b => 'h', val => undef} : {a => 7, b => 'h'}], "returning the rows");
        like(dies { $h->where({a => 1})->insert_many([{a => 8, b => 'h'}]) }, qr/^insert_many\(\) works on the whole table, but the handle has a where/, "and croaks with a where");
        like(dies { $orm->handle(\'SELECT 1')->insert_many([{a => 8}]) },     qr/^insert_many\(\) needs a handle on a table, not a query/,               "or on a query");
    };
};

done_testing;
