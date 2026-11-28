# Test origin: AI
use utf8;
use Test2::V0;
use lib 't/lib';

use File::Temp qw/tempdir/;
use DBIx::QuickORM;
use DBIx::QuickORM::Test;

my %AUTO_PK = (
    PostgreSQL => 'SERIAL PRIMARY KEY',
    MySQL      => 'INTEGER AUTO_INCREMENT PRIMARY KEY',
    MariaDB    => 'INTEGER AUTO_INCREMENT PRIMARY KEY',
    SQLite     => 'INTEGER PRIMARY KEY AUTOINCREMENT',                 # creates sqlite_sequence, a system table
    DuckDB     => "INTEGER PRIMARY KEY DEFAULT nextval('orgs_seq')",
);

# The same tables everywhere. Only the auto-increment key and the identifier quote differ.
sub build_schema {
    my ($dbh, $family) = @_;

    my $mysql = $family =~ m/^(?:MySQL|MariaDB)$/;
    my $q     = $mysql ? '`' : '"';

    $dbh->do("CREATE SEQUENCE orgs_seq") if $family eq 'DuckDB';
    $dbh->do($_)
        for (
        "CREATE TABLE orgs (id $AUTO_PK{$family}, code VARCHAR(20) NOT NULL, name VARCHAR(50), UNIQUE (code))",
        <<"        EOT",
            CREATE TABLE members (
                org_id  INTEGER NOT NULL,
                user_id INTEGER NOT NULL,
                role    VARCHAR(10),
                PRIMARY KEY (user_id, org_id),
                UNIQUE (org_id, user_id),
                FOREIGN KEY (org_id) REFERENCES orgs (id)
            )
        EOT
        <<"        EOT",
            CREATE TABLE people (
                id          INTEGER NOT NULL PRIMARY KEY,
                manager_id  INTEGER,
                org_code    VARCHAR(20),
                first       VARCHAR(20),
                last        VARCHAR(20),
                email       VARCHAR(100),
                amount      NUMERIC(10,2),
                born        DATE,
                active      BOOLEAN,
                ${q}MixedCase${q} INTEGER,
                UNIQUE (last, first),
                FOREIGN KEY (manager_id) REFERENCES people (id),
                FOREIGN KEY (org_code) REFERENCES orgs (code)
            )
        EOT
        "CREATE TABLE logs (msg VARCHAR(50), seen INTEGER)",
        "CREATE TABLE ${q}0${q} (${q}0${q} INTEGER NOT NULL PRIMARY KEY, parent INTEGER, FOREIGN KEY (parent) REFERENCES ${q}0${q} (${q}0${q}))",
        "CREATE TABLE ${q}café${q} (${q}☺${q} VARCHAR(10))",
        "CREATE VIEW people_view AS SELECT id, email FROM people",
        "CREATE TEMPORARY TABLE temp_only (t INTEGER)",
        );

    # A unique index over whole columns.
    $dbh->do("CREATE UNIQUE INDEX people_email ON people (email)");

    # Unique indexes that do not make their columns unique: partial, expression, and column prefix.
    $dbh->do("CREATE UNIQUE INDEX people_partial ON people (org_code) WHERE active") if $family =~ m/^(?:PostgreSQL|SQLite)$/;
    $dbh->do("CREATE UNIQUE INDEX people_lower ON people (lower(email))")            if $family =~ m/^(?:PostgreSQL|SQLite|DuckDB)$/;
    $dbh->do("CREATE UNIQUE INDEX people_prefix ON people (first(5))")               if $mysql;

    # A table outside the namespace, named like one inside it.
    if ($family eq 'SQLite') {
        my $dir = tempdir(CLEANUP => 1);
        $dbh->do("ATTACH DATABASE '$dir/other.db' AS qorm_other");
    }
    else {
        $dbh->do($mysql ? "CREATE DATABASE qorm_other" : "CREATE SCHEMA qorm_other");
    }
    $dbh->do("CREATE TABLE qorm_other.people (elsewhere INTEGER PRIMARY KEY)");
    $dbh->do("CREATE TABLE qorm_other.only_elsewhere (elsewhere INTEGER)");
}

my %KEYS = (
    orgs    => {pk => ['id'],                unique => [['code']], fk => {}},
    members => {pk => ['user_id', 'org_id'], unique => [],         fk => {orgs => [{org_id => 'id'}]}},
    people  => {
        pk     => ['id'],
        unique => [['email'], ['first', 'last']],
        fk     => {people => [{manager_id => 'id'}], orgs => [{org_code => 'code'}]},
    },
    logs   => {pk => undef, unique => [], fk => {}},
    0      => {pk => ['0'], unique => [], fk => {0 => [{parent => '0'}]}},
    'café' => {pk => undef, unique => [], fk => {}},
);

my %FIELDS = (
    orgs    => [qw/id code name/],
    members => [qw/org_id user_id role/],
    people  => [qw/id manager_id org_code first last email amount born active MixedCase/],
    logs    => [qw/msg seen/],
    0       => ['0', 'parent'],
    'café'  => ['☺'],
);

do_for_all_dbs {
    my ($db, $set) = @_;
    my $family = $set->{family};

    # One handle for the DDL and the ORM, so the scan can see the temporary table and the attached database.
    my $dbh = $db->connect;
    build_schema($dbh, $family);

    my $map    = DBIx::QuickORM->new(dbh => $dbh)->db_map;
    my $tables = $map->tables;

    isa_ok($map, ['DBIx::QuickORM::Map'], "The ORM has a map");
    is([sort keys %$tables], [sort keys %KEYS], "Only the namespace's tables: no views, temporary tables, system tables, or other namespaces");

    my %keys = map { my $t = $tables->{$_}; ($_ => {pk => $t->{pk}, unique => $t->{unique}, fk => $t->{fk}}) } keys %$tables;
    is(\%keys, \%KEYS, "Primary, unique, and foreign keys are the same on every backend");

    is({map { $_ => [sort keys %{$tables->{$_}->{fields}}] } keys %$tables}, {map { $_ => [sort @{$FIELDS{$_}}] } keys %FIELDS}, "Every field, with names as declared");

    my $people = $tables->{people}->{fields};
    is($people->{amount},             {table => 'people', name => 'amount', affinity => 'numeric', size => 10, type => match(qr/^(?:numeric|decimal)$/), db_type => match(qr/^(?:numeric|decimal)\(10,\s?2\)$/i)},                  "numeric(10,2)");
    is($people->{born},               {table => 'people', name => 'born', affinity => 'string', type => 'date', db_type => match(qr/^date$/i), orm_type => 'DBIx::QuickORM::Type::DateTime'},                                       "date, typed DateTime by default");
    is($people->{id},                 {table => 'people', name => 'id', affinity => 'numeric', type => match(qr/^int(?:eger)?$/), db_type => match(qr/^int(?:eger)?(?:\(\d+\))?$/i), ($family eq 'SQLite' ? (db_fills => 1) : ())}, "integer");
    is($people->{active}->{affinity}, $family =~ m/^(?:MySQL|MariaDB)$/ ? 'numeric' : 'boolean',                                                                                                                                    "boolean (MySQL makes it tinyint)");

    my %varchar = (table => 'people', name => 'email', affinity => 'string', type => $family eq 'PostgreSQL' ? 'character varying' : 'varchar', db_type => match(qr/^(?:varchar|character varying)/i));
    $varchar{size} = 100 unless $family eq 'DuckDB';    # DuckDB does not keep the length
    is($people->{email}, \%varchar, "varchar(100)");

    ok($map->field(people => 'MixedCase'), "Names keep their case");
    is($map->field(people => 'mixedcase'), undef, "and lookups are exact");
    ok($map->field(0      => '0'), "A table and field named 0 work");
    ok($map->field('café' => '☺'), "Names outside ASCII are characters");

    subtest backend_specific => sub {
        my $scan = sub { DBIx::QuickORM->new(dbh => $dbh)->db_map };

        if ($family eq 'PostgreSQL') {
            $dbh->do("CREATE DOMAIN bytes AS bytea");
            $dbh->do("CREATE TABLE pg_extra (id bytes PRIMARY KEY, a INTEGER, b INTEGER)");
            $dbh->do("CREATE UNIQUE INDEX pg_extra_ab ON pg_extra (a) INCLUDE (b)") if $dbh->{pg_server_version} >= 110000;
            my $map = $scan->();
            is($map->field(pg_extra => 'id'),     {table => 'pg_extra', name => 'id', db_type => 'bytes', type => 'bytes', affinity => 'binary'}, "A domain's base type decides the affinity");
            is($map->table('pg_extra')->{unique}, $dbh->{pg_server_version} >= 110000 ? [['a']] : [],                                             "INCLUDE columns are not part of a unique key");
        }
        elsif ($family eq 'SQLite') {
            $dbh->do("CREATE TABLE lite_extra (id INTEGER PRIMARY KEY, untyped, twice INTEGER GENERATED ALWAYS AS (id * 2), org INTEGER REFERENCES orgs)");
            my $map = $scan->();
            is($map->field(lite_extra => 'untyped'), {table => 'lite_extra', name => 'untyped', db_type => '', type => '', affinity => 'binary'}, "A field without a type has SQLite's blob affinity");
            ok($map->field(lite_extra => 'twice'), "Generated columns are fields");
            is($map->table('lite_extra')->{fk}, {orgs => [{org => 'id'}]}, "A foreign key without fields names the other table's primary key");
        }
        elsif ($family eq 'MySQL') {
            $dbh->do("CREATE TABLE my_extra (id INTEGER PRIMARY KEY, email VARCHAR(50), UNIQUE KEY my_lower ((lower(email))))");
            is($scan->()->table('my_extra')->{unique}, [], "An expression unique index is left out");
        }
        elsif ($family eq 'DuckDB') {
            $dbh->do("CREATE TABLE duck_extra (id INTEGER PRIMARY KEY, code VARCHAR(10), a INTEGER, \"we ird\" INTEGER, UNIQUE (a))");
            $dbh->do("CREATE UNIQUE INDEX duck_$_->[0] ON duck_extra ($_->[1])") for [code => 'code'], [weird => '"we ird", a'], [a => 'a'], [id => 'id'];
            $dbh->do("CREATE TABLE duck_ref (id INTEGER PRIMARY KEY, code VARCHAR(10))");
            my $orm = DBIx::QuickORM->new(dbh => $dbh, row_class => undef, fks => {duck_ref => {duck_extra => [{code => 'code'}]}});
            is($orm->db_map->table('duck_extra')->{unique},                              [['a'], ['a', 'we ird'], ['code']], "Unique indexes are unique keys, quoted names too, without repeating a constraint or the primary key");
            is($orm->follow_fk(duck_ref => {id => 1, code => 'x'}, 'duck_extra')->state, 'single',                           "so a link to one is single");
        }
        else {
            skip_all "nothing specific to $family";
        }
    };

    subtest fill_facts => sub {
        my $pg  = $family eq 'PostgreSQL' ? $dbh->{pg_server_version} : 0;
        my %ddl = (
            PostgreSQL => [
                "CREATE DOMAIN filled AS INTEGER DEFAULT 7",
                "CREATE TABLE fills (id INTEGER PRIMARY KEY DEFAULT 1, nul INTEGER DEFAULT NULL, dom filled)",
                ($pg >= 100000 ? "CREATE TABLE fills_identity (always INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY, by_default INTEGER GENERATED BY DEFAULT AS IDENTITY)" : ()),
                ($pg >= 120000 ? "CREATE TABLE fills_generated (id INTEGER PRIMARY KEY, twice INTEGER GENERATED ALWAYS AS (id * 2) STORED)"                                   : ()),
            ],
            MySQL   => ["CREATE TABLE fills (id VARCHAR(5) PRIMARY KEY DEFAULT 'x', nul INTEGER DEFAULT NULL, twice INTEGER GENERATED ALWAYS AS (nul * 2) STORED)"],
            MariaDB => ["CREATE TABLE fills (id VARCHAR(5) PRIMARY KEY DEFAULT 'x', nul INTEGER DEFAULT NULL, twice INTEGER GENERATED ALWAYS AS (nul * 2) STORED)"],
            SQLite  => [
                "CREATE TABLE fills (id TEXT PRIMARY KEY DEFAULT 'x', nul INTEGER DEFAULT NULL, twice INTEGER GENERATED ALWAYS AS (nul * 2))",
                "CREATE TABLE fills_int (id INT PRIMARY KEY)",
                "CREATE TABLE fills_desc (id INTEGER PRIMARY KEY DESC)",
                "CREATE TABLE fills_norowid (id INTEGER PRIMARY KEY) WITHOUT ROWID",
            ],
            DuckDB => ["CREATE TABLE fills (id VARCHAR PRIMARY KEY DEFAULT 'x', nul INTEGER DEFAULT NULL)"],
        );
        $dbh->do($_) for @{$ddl{$family}};

        my $map   = DBIx::QuickORM->new(dbh => $dbh)->db_map;
        my $facts = sub {
            my %got;
            for my $table (sort keys %{$map->tables}) {
                next unless $table =~ m/^(?:orgs|people|fills.*)$/;
                my $fields = $map->table($table)->{fields};
                for my $name (keys %$fields) {
                    my @facts = grep { $fields->{$name}->{$_} } qw/db_fills db_refuses_value/;
                    $got{"$table.$name"} = join ',' => @facts if @facts;
                }
            }
            return \%got;
        };

        my %want = (
            'orgs.id'  => 'db_fills',    # serial, auto-increment, rowid alias, or a sequence default
            'fills.id' => 'db_fills',
        );
        if ($family eq 'PostgreSQL') {
            $want{'fills.dom'}                                         = 'db_fills';
            @want{qw/fills_identity.always fills_identity.by_default/} = ('db_fills,db_refuses_value', 'db_fills') if $pg >= 100000;
            $want{'fills_generated.twice'}                             = 'db_fills,db_refuses_value'               if $dbh->{pg_server_version} >= 120000;
        }
        $want{'fills.twice'} = 'db_fills,db_refuses_value' if $family =~ m/^(?:MySQL|MariaDB|SQLite)$/;
        $want{'people.id'}   = 'db_fills'                  if $family eq 'SQLite';                        # INTEGER PRIMARY KEY is the rowid alias

        is($facts->(), \%want, "Filled and refusing columns are marked; a NULL default, INT, DESC, and WITHOUT ROWID keys are not");
    };
};

done_testing;
