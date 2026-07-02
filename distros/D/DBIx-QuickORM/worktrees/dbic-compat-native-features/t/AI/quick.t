use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

# The "quick" interface: DBIx::QuickORM->quick(...) returns a live,
# fully-introspected connection with auto-typing applied, with no DSL.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir  = tempdir(CLEANUP => 1);
my $file = "$dir/quick.sqlite";
my $dsn  = "dbi:SQLite:dbname=$file";

# Seed a database the quick interface will introspect.
{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE users (user_id INTEGER PRIMARY KEY, name TEXT NOT NULL, meta_json TEXT)');
    $dbh->do('INSERT INTO users (name, meta_json) VALUES (?, ?)', undef, 'bob', '{"age":42}');
    $dbh->disconnect;
}

subtest credentials_with_dsn => sub {
    my $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn}, auto_types => ['JSON']);

    isa_ok($con, ['DBIx::QuickORM::Connection'], "quick() returns a live Connection");
    isa_ok($con->orm, ['DBIx::QuickORM::ORM'], "the ORM is reachable via \$con->orm");
    isa_ok($con->dialect, ['DBIx::QuickORM::Dialect::SQLite'], "dialect detected from the dsn scheme");

    my @rows = $con->handle('users')->all;
    is(scalar(@rows), 1, "introspected the table and fetched the seeded row");

    my $row = $rows[0];
    is($row->field('name'), 'bob', "plain column value");
    is($row->field('meta_json'), {age => 42}, "JSON auto-type inflated the column to a ref");

    my $new = $con->handle('users')->insert({name => 'alice', meta_json => {x => 1}});
    is($new->field('meta_json'), {x => 1}, "JSON round-tripped on insert");
    is($con->handle('users')->count, 2, "row was written to the database");
};

subtest connect_callback_probe => sub {
    my $con = DBIx::QuickORM->quick(
        connect    => sub { DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0}) },
        auto_types => ['JSON'],
    );

    isa_ok($con->dialect, ['DBIx::QuickORM::Dialect::SQLite'], "dialect detected by probing the connect handle");
    my ($row) = $con->handle('users')->all;
    ok($row, "fetched a row through a connect-callback quick connection");
    is($row->field('name'), 'bob', "column value via connect-callback path");
};

subtest explicit_dialect => sub {
    my $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn}, dialect => 'SQLite');
    isa_ok($con->dialect, ['DBIx::QuickORM::Dialect::SQLite'], "explicit dialect honored");
};

subtest row_manager => sub {
    my $def = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
    isa_ok($def->manager, ['DBIx::QuickORM::RowManager::Cached'], "default row manager is Cached");

    my $plain = DBIx::QuickORM->quick(credentials => {dsn => $dsn}, row_manager => 'DBIx::QuickORM::RowManager');
    isa_ok($plain->manager, ['DBIx::QuickORM::RowManager'], "row_manager override honored");
    ok(!$plain->manager->does_cache, "the plain RowManager does not cache");

    like(
        dies { DBIx::QuickORM->quick(credentials => {dsn => $dsn}, row_manager => 'No::Such::Manager::XYZ') },
        qr/Could not load row_manager/,
        "bad row_manager class is reported",
    );
};

subtest autorow => sub {
    # Off by default: rows are the generic class.
    my $off = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
    my ($u) = $off->handle('users')->all;
    is(ref($u), 'DBIx::QuickORM::Row', "autorow off by default -> generic Row");

    # autorow => 1 generates a unique namespace.
    my $gen = DBIx::QuickORM->quick(credentials => {dsn => $dsn}, autorow => 1);
    my ($g) = $gen->handle('users')->all;
    like(ref($g), qr/^DBIx::QuickORM::Row::Auto\d+::Users$/, "autorow => 1 generates a row class");
    isa_ok($g, ['DBIx::QuickORM::Row'], "generated row class isa Row");
    is($g->name, 'bob', "generated row class has a named field accessor");

    # autorow => prefix uses that namespace.
    my $pfx = DBIx::QuickORM->quick(credentials => {dsn => $dsn}, autorow => 'My::QS::Row');
    my ($p) = $pfx->handle('users')->all;
    is(ref($p), 'My::QS::Row::Users', "autorow => prefix uses the given namespace");
    is($p->name, 'bob', "prefixed row class has a named field accessor");

    # Two generated namespaces do not collide.
    my $gen2 = DBIx::QuickORM->quick(credentials => {dsn => $dsn}, autorow => 1);
    my ($g2) = $gen2->handle('users')->all;
    isnt(ref($g2), ref($g), "each autorow => 1 connection gets its own namespace");
};

subtest validation => sub {
    like(
        dies { DBIx::QuickORM->quick() },
        qr/exactly one of 'credentials' or 'connect'/,
        "must provide credentials or connect",
    );
    like(
        dies { DBIx::QuickORM->quick(credentials => {dsn => $dsn}, connect => sub { }) },
        qr/exactly one of 'credentials' or 'connect'/,
        "cannot provide both",
    );
    like(
        dies { DBIx::QuickORM->quick(credentials => {user => 'x'}) },
        qr/dsn.*dbd|detect the dialect/,
        "credentials need a dsn/dbd or an explicit dialect",
    );
    like(
        dies { DBIx::QuickORM->quick(credentials => {dsn => $dsn}, bogus => 1) },
        qr/Unknown parameter/,
        "rejects unknown parameters",
    );
};

done_testing;
