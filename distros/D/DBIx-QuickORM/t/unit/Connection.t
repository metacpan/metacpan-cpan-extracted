# Test origin: AI
use Test2::V0;

use DBD::SQLite::Constants qw/DBD_SQLITE_STRING_MODE_UNICODE_STRICT/;

use Config qw/%Config/;
use DBI;
use POSIX();
use DBIx::QuickORM::Connection;
use DBIx::QuickORM::Map;

package Fake::Row {
    sub row_data { $_[0]->{data} }
}

sub dbh { DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1, @_}) }

subtest handle_checks => sub {
    my $dbh  = dbh(PrintError => 1);
    my $conn = DBIx::QuickORM::Connection->new(dbh => $dbh, time_zone => 'UTC');

    ref_is($conn->dbh, $dbh, "Holds the handle");
    isa_ok($conn->dialect, ['DBIx::QuickORM::Dialect::SQLite'], "Dialect from the driver");
    ok($conn->dialect->server_version > 3_000_000, "holding the server version");
    is($conn->namespace, 'main', "Namespace from the dialect");
    is($conn->pid,       $$,     "Records the pid");
    ok(!$dbh->{PrintError},         "PrintError turned off");
    ok($dbh->{AutoInactiveDestroy}, "AutoInactiveDestroy turned on");
    is($dbh->{sqlite_string_mode}, DBD_SQLITE_STRING_MODE_UNICODE_STRICT, "The dialect set up the session");

    like(dies { DBIx::QuickORM::Connection->new(dbh => dbh(RaiseError => 0), time_zone => 'UTC') }, qr/^The database handle must have RaiseError on/,                         "RaiseError off croaks");
    like(dies { DBIx::QuickORM::Connection->new(dbh => dbh(AutoCommit => 0), time_zone => 'UTC') }, qr/^The database handle must have AutoCommit on and no transaction open/, "AutoCommit off croaks");
    like(dies { DBIx::QuickORM::Connection->new(dbh => {}, time_zone => 'UTC') }, qr/^The connection did not produce a DBI database handle/, "A non-handle croaks");
    $conn = DBIx::QuickORM::Connection->new(dbh => dbh());
    is([$conn->time_zone, $conn->retain_cache, $conn->enforce_canon], ['UTC', 0, 1], "Settings default to UTC, not retaining, enforcing canon");
};

subtest scan => sub {
    my $dbh = dbh();
    $dbh->do("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)");
    my $conn = DBIx::QuickORM::Connection->new(dbh => $dbh);
    isa_ok($conn->db_map, ['DBIx::QuickORM::Map'], "Without a map the database is scanned into one");
    is($conn->db_map->pk('users'), ['id'], "with the tables");

    my $map = DBIx::QuickORM::Map->new(tables => {});
    ref_is(DBIx::QuickORM::Connection->new(dbh => $dbh, db_map => $map)->db_map, $map, "A given map is used as is");
};

subtest lookup => sub {
    my $map    = DBIx::QuickORM::Map->new(tables => {users => {fields => {id => {}}, pk => ['id']}});
    my $conn   = DBIx::QuickORM::Connection->new(dbh => dbh(), db_map => $map);
    my $lookup = $conn->lookup;
    isa_ok($lookup, ['DBIx::QuickORM::LookupTable'], "Built on first use");
    ref_is($conn->lookup, $lookup, "and kept");
    ok(!$lookup->retain, "retain follows retain_cache (off)");

    my $row = $lookup->ingest(users => {id => 1});
    ok($conn->is_canon(users  => $row),                               "Primary keys come from the map");
    ok(!$conn->is_canon(users => {id => 1}),                          "A copy is not canon");
    ok($conn->is_canon(users  => bless({data => $row}, 'Fake::Row')), "A row object is checked through its row_data");
    like(dies { $conn->is_canon(users => 1) },         qr/^Expected row data \(a hashref\) or a row object, got 1/, "A plain value croaks");
    like(dies { $conn->is_canon(nope  => {id => 1}) }, qr/^The table 'nope' is not in the database map/,            "An unknown table croaks");

    $conn = DBIx::QuickORM::Connection->new(dbh => dbh(), time_zone => 'UTC', db_map => $map, retain_cache => 1);
    ok($conn->lookup->retain, "retain follows retain_cache (on)");
};

subtest no_namespace => sub {
    my $mock = mock 'DBIx::QuickORM::Dialect::SQLite' => (override => [namespace => sub { undef }]);
    like(dies { DBIx::QuickORM::Connection->new(dbh => dbh(), time_zone => 'UTC') }, qr/^The connection has no current schema or database; select one in the DSN/, "No namespace croaks");
};

subtest release_in_child => sub {
    skip_all "fork is emulated with threads on Windows" if $Config{d_pseudofork};
    my $released = 0;
    my $mock     = mock 'DBIx::QuickORM::Dialect::SQLite' => (override => [release_inherited => sub { $released++ }]);

    my $conn = DBIx::QuickORM::Connection->new(dbh => dbh(), time_zone => 'UTC');
    my $pid  = fork // die "Could not fork: $!";
    unless ($pid) {
        undef $conn;
        POSIX::_exit($released == 1 ? 0 : 1);
    }
    waitpid($pid, 0);
    is($?, 0, "Freed in a child, the Connection releases its inherited handle");

    undef $conn;
    is($released, 0, "Freed in the process that opened it, it does not");
};

done_testing;
