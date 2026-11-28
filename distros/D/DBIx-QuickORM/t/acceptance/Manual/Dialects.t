# Test origin: AI
# This test runs copies of the code examples in lib/DBIx/QuickORM/Manual/Dialects.pm. Whenever an
# example there changes, change its copy here to match: t/acceptance/Examples.t fails while any
# example has no copy in an example test.
use Test2::V0;
use lib 't/lib';

use DBI;
use DBIx::QuickORM;
use DBIx::QuickORM::Test qw/do_for_all_dbs/;
use DBIx::QuickORM::Test::Examples;

# The examples that show no difference run on PostgreSQL alone.
do_for_pg {
    my ($db) = @_;
    $db->connect->do($SCHEMA);
    my ($dsn, $user, $pass) = ($db->connect_string, $db->username, $db->password);
    my $orm = DBIx::QuickORM->new(connect => sub { $db->connect });

    # ASKING THE DIALECT
    my $dialect = $orm->connection->dialect;
    # 'PostgreSQL', 'MySQL', 'MariaDB', 'SQLite', or 'DuckDB'
    my $name = $dialect->name;
    # 170004 for PostgreSQL 17.4 (its own number), and elsewhere
    # major * 1_000_000 + minor * 1_000 + patch: 8000036 for MySQL 8.0.36
    my $version = $dialect->server_version;

    # branch on a capability, not a name
    my $whole = $dialect->supports_returning_update ? 'the row' : 'its key';

    is($name,    'PostgreSQL',                               "the dialect's name");
    is($version, $orm->connection->dbh->{pg_server_version}, "PostgreSQL's own version number");
    like($version, qr/^\d{5,6}\z/, "as one integer");
    is($whole, 'the row', "PostgreSQL returns updated rows");
    isa_ok($dialect, ['DBIx::QuickORM::Dialect::PostgreSQL', 'DBIx::QuickORM::Dialect']);

    # BACKGROUND QUERIES AND FORKING
    my $memory = DBIx::QuickORM->new(
        connect => sub { DBI->connect('dbi:SQLite:dbname=:memory:', '', '', {RaiseError => 1}) },
    );
    # croaks: no second connection can reach this SQLite database
    my $ok = eval { $memory->handle(\'SELECT 1 AS one')->forked->iter; 1 };

    ok(!$ok, "forked croaks on an in-memory SQLite database");
    like($@, qr/No second connection can reach this SQLite database, so forked\(\) cannot run/, "saying why");
    is($memory->connection->dialect->supports_second_connection($memory->connection->dbh), 0, "the dialect reports it");
    is($orm->connection->dialect->supports_second_connection($orm->connection->dbh),       1, "PostgreSQL allows one");

    # TIME ZONES
    my $ny = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        # a floating DateTime written to a timestamp with time zone is taken to be in it
        time_zone => 'America/New_York',
    );

    is($ny->connection->dbh->selectrow_array('SHOW TIME ZONE'),  'America/New_York', "time_zone sets the session zone");
    is($orm->connection->dbh->selectrow_array('SHOW TIME ZONE'), 'UTC',              "UTC by default");

    # JSON
    my $cy = $orm->insert(
        users => {
            name  => 'Cy',
            prefs => {theme => 'dark'},
        }
    );
    # undef: json has no = operator, so the database raises an error ($@)
    my $compared = eval { $cy->update({name => 'Cy B'}, cas => ['prefs']) };
    $cy->update({name => 'Cy B'}, cas => ['name']);    # compare a plain field instead

    ok(!$compared, "cas on a json column fails on PostgreSQL");
    like($@, qr/operator does not exist: json = unknown/, "as a database error");
    isa_ok($@, ['DBIx::QuickORM::Exception::DB']);
    is($@->kind,           undef,  "of no known kind");
    is($cy->field('name'), 'Cy B', "cas on a plain field works");

    my $maria_json = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        # MariaDB: a JSON column is longtext to the scan
        types => {users => {prefs => 'JSON'}},
    );

    is($maria_json->db_map->field(users => 'prefs')->{orm_type}, 'DBIx::QuickORM::Type::JSON', "naming the type is harmless where autotype already chose it");

    # SQL YOU WRITE
    # "users", or `users` on MySQL and MariaDB
    my $q    = $orm->connection->dialect->quote_identifier('users');
    my @rows = $orm->handle(\"SELECT * FROM $q")->all;

    is($q,                                '"users"', "double quotes on PostgreSQL");
    is([map { $_->field('name') } @rows], ['Cy B'],  "and the SQL runs");
};

# The examples that show a difference run on every database.
my %AUTO_PK = (
    PostgreSQL => 'SERIAL PRIMARY KEY',
    MySQL      => 'INTEGER AUTO_INCREMENT PRIMARY KEY',
    MariaDB    => 'INTEGER AUTO_INCREMENT PRIMARY KEY',
    SQLite     => 'INTEGER PRIMARY KEY AUTOINCREMENT',
    DuckDB     => "INTEGER PRIMARY KEY DEFAULT nextval('users_seq')",
);

my %KEY_ONLY   = (MySQL      => 1, MariaDB => 1);
my %NO_INSERT  = (MySQL      => 1);
my %BIND_LIMIT = (PostgreSQL => 65535,     MySQL => 65535,     MariaDB => 65535,     SQLite => 999,       DuckDB => 7000);
my %STATE      = (PostgreSQL => '23505',   MySQL => '23000',   MariaDB => '23000',   SQLite => 'S1000',   DuckDB => 'S1000');
my %NATIVE     = (PostgreSQL => 7,         MySQL => 1062,      MariaDB => 1062,      SQLite => 2067,      DuckDB => 1);
my %QUOTED     = (PostgreSQL => '"users"', MySQL => '`users`', MariaDB => '`users`', SQLite => '"users"', DuckDB => '"users"');

do_for_all_dbs {
    my ($db, $set) = @_;
    my $family = $set->{family};
    my $mysql  = $family =~ m/^(?:MySQL|MariaDB)$/;

    # DuckDB sees only its own connection's writes, so the setup connection is closed before the ORM opens.
    my $setup = $db->connect;
    $setup->do("CREATE SEQUENCE users_seq") if $family eq 'DuckDB';
    $setup->do("CREATE TABLE users (id $AUTO_PK{$family}, name VARCHAR(40) NOT NULL, email VARCHAR(80) UNIQUE, prefs JSON)");
    $setup->disconnect;

    my $orm     = DBIx::QuickORM->new(connect => sub { $db->connect });
    my $dialect = $orm->connection->dialect;
    is($dialect->name, $family, "the dialect is named for the server");
    like($dialect->server_version, qr/^\d+\z/, "with a version number");
    is(!!$dialect->supports_async,                                  $family eq 'SQLite' || $family eq 'DuckDB' ? '' : 1, "$family: async where the at-a-glance list says");
    is($dialect->supports_second_connection($orm->connection->dbh), $family eq 'DuckDB'                        ? 0  : 1, "$family: a second connection to a database file, except DuckDB");

    # RETURNING
    my $ann = $orm->insert(
        users => {
            name  => 'Ann',
            email => 'ann@example.com',
        }
    );
    $ann->update({name => 'Ann B'});
    # every field, but on MySQL, and on MariaDB after an update, only id
    my @have = sort keys %{$ann->row_data};
    # 'Ann B' everywhere: a field the row lacks is fetched when read
    my $name = $ann->field('name');

    is(\@have,                                                         $KEY_ONLY{$family} ? ['id'] : ['email', 'id', 'name', 'prefs'],  "$family: what the row holds after an update");
    is($name,                                                          'Ann B',                                                         "the field is there when read");
    is(!!$dialect->supports_returning_update,                          !$KEY_ONLY{$family},                                             "supports_returning_update says so");
    is(!!$dialect->supports_returning_insert,                          !$NO_INSERT{$family},                                            "only MySQL cannot return inserted rows");
    is([sort keys %{$orm->insert(users => {name => 'Al'})->row_data}], $NO_INSERT{$family} ? ['id'] : ['email', 'id', 'name', 'prefs'], "$family: what a row holds after an insert");

    # SAVEPOINTS
    my $nested = eval {
        $orm->txn(sub {
            # a savepoint. DuckDB has none, so this croaks
            $orm->txn(sub { $orm->insert(users => {name => 'Bob'}) });
        });
        1;
    };

    if ($dialect->supports_savepoints) {
        isnt($family, 'DuckDB', "every database but DuckDB has savepoints");
        ok($nested,                                             "a nested transaction works");
        ok($orm->handle('users')->where({name => 'Bob'})->only, "and commits with the outer one");
    }
    else {
        is($family, 'DuckDB', "only DuckDB has none");
        ok(!$nested, "a nested transaction croaks");
        like($@, qr/The DuckDB dialect has no savepoints, so transactions cannot be nested/, "saying so");
        ok(!$orm->handle('users')->where({name => 'Bob'})->only, "and nothing was inserted");
        $orm->txn(sub { $orm->insert(users => {name => 'Bob'}) });
        ok($orm->handle('users')->where({name => 'Bob'})->only, "a transaction that does not nest works");
    }

    if ($family eq 'SQLite' || $family eq 'DuckDB') {
        like(
            dies {
                $orm->txn(sub { }, isolation => 'serializable')
            },
            qr/cannot set a transaction isolation level/,
            "$family: isolation croaks"
        );
    }
    else {
        ok(
            lives {
                $orm->txn(sub { $orm->handle('users')->count }, isolation => 'serializable')
            },
            "$family: isolation is accepted"
        );
    }

    # TIME ZONES: an offset, on the MySQL family
    if ($mysql) {
        my ($dsn, $user, $pass) = ($db->connect_string, $db->username, $db->password);

        my $maria = DBIx::QuickORM->new(
            credentials => {
                dsn  => $dsn,
                user => $user,
                pass => $pass,
            },
            # MySQL and MariaDB without time zone tables (DuckDB takes names only)
            time_zone => '+05:30',
        );

        is($maria->connection->dbh->selectrow_array('SELECT @@session.time_zone'), '+05:30', "an offset sets the session zone");
        is($orm->connection->dbh->selectrow_array('SELECT @@session.time_zone'),   '+00:00', "UTC is sent as +00:00");

        my $tables = $orm->connection->dbh->selectrow_array('SELECT COUNT(*) FROM mysql.time_zone_name');
        my $named  = eval { DBIx::QuickORM->new(credentials => {dsn => $dsn, user => $user, pass => $pass}, time_zone => 'America/New_York')->connection; 1 };
        if ($tables) {
            ok($named, "a named zone works with the time zone tables loaded");
        }
        else {
            ok(!$named, "a named zone fails without the time zone tables");
            like($@, qr/Unknown or incorrect time zone/, "with the server's error");
        }

        # JSON on the MySQL family
        my $maria_json = DBIx::QuickORM->new(
            credentials => {
                dsn  => $dsn,
                user => $user,
                pass => $pass,
            },
            # MariaDB: a JSON column is longtext to the scan
            types => {users => {prefs => 'JSON'}},
        );

        is($maria_json->db_map->field(users => 'prefs')->{orm_type}, 'DBIx::QuickORM::Type::JSON', "types gives the column the JSON type");
        if ($family eq 'MariaDB') {
            is($orm->db_map->field(users => 'prefs')->{db_type},  'longtext', "MariaDB reports a JSON column as longtext");
            is($orm->db_map->field(users => 'prefs')->{orm_type}, undef,      "so autotype does not claim it by type");
        }
        else {
            is($orm->db_map->field(users => 'prefs')->{db_type},  'json',                       "MySQL reports json");
            is($orm->db_map->field(users => 'prefs')->{orm_type}, 'DBIx::QuickORM::Type::JSON', "which autotype claims");
        }

        my $cy = $maria_json->insert(users => {name => 'Cy', prefs => {theme => 'dark'}});
        $cy->refresh;    # the insert returned only the key
        my $cas = $cy->update({name => 'Cy B'}, cas => ['prefs']);
        if ($family eq 'MySQL') {
            is($cas, undef, "MySQL: a JSON value never equals the text bind, so cas misses");
            $cy->refresh;
            is($cy->field('name'), 'Cy', "and nothing changed");
        }
        else {
            ok($cas, "MariaDB: longtext compares as text, so cas works");
        }
    }

    # ERRORS
    my $ok = eval {
        $orm->insert(
            users => {
                name  => 'Dup',
                email => 'ann@example.com',    # taken: Ann's, from RETURNING above
            }
        );
        1;
    };
    my $err  = $@;
    my $kind = $err->kind;    # 'unique_violation' on every database

    # '23505' on PostgreSQL, '23000' on MySQL and MariaDB, 'S1000' on SQLite and DuckDB
    my $state = $err->state;
    # 7 on PostgreSQL, 1062 on MySQL and MariaDB, 2067 on SQLite, 1 on DuckDB
    my $native = $err->native;

    ok(!$ok, "the duplicate fails");
    is($kind,           'unique_violation', "$family: the same kind everywhere");
    is($state,          $STATE{$family},    "$family: the database's SQLSTATE");
    is($native,         $NATIVE{$family},   "$family: the driver's native code");
    is($err->retriable, 0,                  "a constraint error is not retriable");

    # SQL YOU WRITE, BULK INSERTS
    is($dialect->quote_identifier('users'),                                                                                               $QUOTED{$family},     "$family: identifier quoting");
    is($dialect->bind_limit,                                                                                                              $BIND_LIMIT{$family}, "$family: the bind limit");
    is([map { $_->field('name') } $orm->handle(\('SELECT * FROM ' . $dialect->quote_identifier('users') . ' WHERE name = \'Al\''))->all], ['Al'],               "the quoted name runs");
};

done_testing;
