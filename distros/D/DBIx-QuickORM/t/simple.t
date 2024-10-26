use Test2::V0;
use Importer 'Test2::Tools::QuickDB' => (get_db => {-as => 'get_qdb'});
use DBIx::QuickORM;

BEGIN {
    $ENV{PATH} = "/home/exodist/percona/bin:$ENV{PATH}" if -d "/home/exodist/percona/bin";
}

my $psql    = eval { get_qdb({driver => 'PostgreSQL'}) } or diag(clean_err($@));
my $mysql   = eval { get_qdb({driver => 'MySQL'}) }      or diag(clean_err($@));
my $mariadb = eval { get_qdb({driver => 'MariaDB'}) }    or diag(clean_err($@));
my $percona = eval { get_qdb({driver => 'Percona'}) }    or diag(clean_err($@));
my $sqlite  = eval { get_qdb({driver => 'SQLite'}) }     or diag(clean_err($@));

sub clean_err {
    my $err = shift;

    my @lines = split /\n/, $err;

    my $out = "";
    while (@lines) {
        my $line = shift @lines;
        next unless $line;
        last if $out && $line =~ m{^Aborting at.*DBIx/QuickDB\.pm};

        $out = $out ? "$out\n$line" : $line;
    }

    return $out;
}

imported_ok qw{
    db db_attributes db_class db_connect db_dsn db_host db_name db_password
    db_port db_socket db_user

    column column_class columns conflate default index is_temp is_view omit
    primary_key row_class source_class table_class unique

    column columns relation relations relate

    autofill orm

    include schema

    sql_spec
    table
};

sub _schema {
    table person => sub {
        column person_id => sub {
            primary_key;
            serial('BIG');
        };

        column name => sub {
            unique;
            sql_spec(type => 'VARCHAR(128)');
        };

        relations aliases => ['person_id'];
    };

    table aliases => sub {
        column alias_id => sub {
            primary_key;
            serial;
        };

        column person_id => sub {
            sql_type 'biginteger';
            references person => (on_delete => 'cascade', prefetch => 1);
        };

        column alias => sub {
            sql_type \'VARCHAR(128)'; # Just verifying escape works, nothing special about it.
        };

        unique(qw/person_id alias/);

        relation person_way2 => (table => 'person', using => 'person_id', on_delete => 'cascade');
        relation sub { as 'person_way3'; table 'person'; using 'person_id'; on_delete 'cascade' };
        relation as 'person_way4', rtable 'person', on {'person_id' => 'person_id'}, on_delete 'cascade';
        relation as 'person_way5', rtable('person'), using 'person_id',               on_delete 'cascade';
        relation person_way6 => ('person' => ['person_id'], on_delete => 'cascade');
    };

    relate(
        person  => ['aliases_link', ['person_id'], method => 'select'],
        aliases => {as => 'person_link', on => {'person_id' => 'person_id'}, method => 'find', on_delete => 'cascade'},
    );
}

orm postgresql_auto => sub {
    autofill 1;
    db_class 'PostgreSQL';
    db_name 'quickdb';
    db_connect sub { $psql->connect };

    _schema();
} if $psql;

orm mariadb_auto => sub {
    autofill 1;
    db_class 'MariaDB';
    db_name 'quickdb';
    db_connect sub { $mariadb->connect };

    _schema();
} if $mariadb;

orm mysql_auto => sub {
    autofill 1;
    db_class 'MySQL';
    db_name 'quickdb';
    db_connect sub { $mysql->connect };

    _schema();
} if $mysql;

orm percona_auto => sub {
    autofill 1;
    db_class 'Percona';
    db_name 'quickdb';
    db_connect sub { $percona->connect };

    _schema();
} if $percona;

orm sqlite_auto => sub {
    autofill 1;
    db_class 'SQLite';
    db_name 'quickdb';
    db_connect sub { $sqlite->connect };

    _schema();
} if $sqlite;

orm postgresql_noauto => sub {
    autofill 0;
    db_class 'PostgreSQL';
    db_name 'quickdb';
    db_connect sub { $psql->connect };

    _schema();
} if $psql;

orm mariadb_noauto => sub {
    autofill 0;
    db_class 'MariaDB';
    db_name 'quickdb';
    db_connect sub { $mariadb->connect };

    _schema();
} if $mariadb;

orm mysql_noauto => sub {
    autofill 0;
    db_class 'MySQL';
    db_name 'quickdb';
    db_connect sub { $mysql->connect };

    _schema();
} if $mysql;

orm percona_noauto => sub {
    autofill 0;
    db_class 'Percona';
    db_name 'quickdb';
    db_connect sub { $percona->connect };

    _schema();
} if $percona;

orm sqlite_noauto => sub {
    autofill 0;
    db_class 'SQLite';
    db_name 'quickdb';
    db_connect sub { $sqlite->connect };

    _schema();
} if $sqlite;

my %DB_COUNT;
for my $set (map {( [$_, "${_}_auto"], [$_, "${_}_noauto"] )} qw/postgresql mariadb mysql percona sqlite/) {
    my ($db, $name) = @$set;

    subtest $name => sub {
        my $orm = orm($name) or skip_all "Could not find $name";

        my $id = 1;

        isa_ok($orm, ['DBIx::QuickORM::ORM'], "Got correct ORM type");

        my $pdb = $orm->db;
        isa_ok($pdb, ['DBIx::QuickORM::DB'], "Got a database instance");

        if ($DB_COUNT{$db}++) {
            $pdb->connect->dbh->do("DROP TABLE aliases");
            $pdb->connect->dbh->do("DROP TABLE person");
        }

        note uc("== SQL for $db ==\n" . $orm->generate_schema_sql . "\n== END SQL for $db ==\n");

        ok(lives { $orm->generate_and_load_schema() }, "Generate and load schema");

        is([sort $orm->connection->tables], [qw/aliases person/], "Loaded both tables");

        my $source = $orm->source('person');
        isa_ok($source, ['DBIx::QuickORM::Source'], "Got a source");

        my $bob_id = $id++;
        ok(my $bob = $source->insert(name => 'bob'), "Inserted bob");

        isa_ok($bob, ['DBIx::QuickORM::Row'], "Got a row back");
        is($bob->stored->{person_id}, $bob_id, "First row inserted, got id");
        is($bob->stored->{name}, 'bob', "Name was set correctly");
        ref_is($bob->real_source, $source, "Can get original source");
        isa_ok($bob->source, [qw/DBIx::QuickORM::Util::Mask DBIx::QuickORM::Source/], "Source has been masked");

        # This failed insert will increment the sequence for all db's except sqlite
        $id++ unless $db eq 'sqlite';

        like(
            dies {
                local $SIG{__WARN__} = sub { 1 };
                $source->insert(name => 'bob');
            },
            in_set(
                qr/Duplicate entry 'bob' for key 'name'/,
                qr/UNIQUE constraint failed: person\.name/,
                qr/Duplicate entry 'bob' for key 'person\.name'/,
                qr/duplicate key value violates unique constraint "person_name_key"/,
            ),
            "Cannot insert the same row again due to unique contraint"
        );

        ref_is($source->find($bob_id), $bob, "Got cached copy using pk search");
        ref_is($source->find(name => 'bob'), $bob, "Got cached copy using name search");

        my $con = $source->connection;
        my $oldref = "$bob";
        $bob = undef;
        ok(!$con->{cache}->{$source}->{$bob_id}, "Object can be pruned from cache when there are no refs to it");

        $bob = $source->find($bob_id);
        ok("$bob" ne $oldref, "Did not get the same ref");
        is($bob->stored, {name => 'bob', person_id => $bob_id}, "Got bob");
        ref_is($source->find($bob_id), $bob, "Got cached copy using pk search");

        my $data_ref = $bob->stored;
        $bob->refresh();
        is($bob->stored, $data_ref, "Identical data after fetch");
        ref_is_not($bob->stored, $data_ref, "But the data hashref has been swapped out");

        $bob->{stored}->{name} = 'foo';
        is($bob->column('name'), 'foo', "Got incorrect stored name");
        $bob->{dirty}->{name} = 'bar';
        is($bob->column('name'), 'bar', "Got dirty name");
        $bob->reload;
        is($bob->column('name'), 'bob', "Got correct name from db, and cleared dirty");

        is($source->fetch($bob_id), {name => 'bob', person_id => $bob_id}, "fetched bobs data");
        is($source->find($id), undef, "Could not find anything for id $id");

        my $ted = $source->vivify(name => 'ted');
        isa_ok($ted, ['DBIx::QuickORM::Row'], "Created row");
        ok(!$ted->stored, "But did not insert");

        my $ted_id = $id++;
        $ted->save;

        is($ted->stored, {name => 'ted', person_id => $ted_id}, "Inserted");
        ref_is($source->find($ted_id), $ted, "Got cached copy");

        $ted->update(name => 'theador');

        like(
            $ted,
            {
                stored  => {name => 'theador', person_id => $ted_id},
                dirty    => DNE(),
                inflated => DNE(),
            },
            "Got expected data and state",
        );

        ok($ted->is_stored, "Ted is in the db");
        $ted->delete;
        ok(!$ted->is_stored, "Not in the db");

        is($source->find($ted_id), undef, "No Ted");

        my $als = $orm->source('aliases');
        my $robert = $als->insert(person_id => $bob->column('person_id'), alias => 'robert');
        my $rob = $als->insert(person_id => $bob->column('person_id'), alias => 'rob');

        is($robert->relation('person'), $bob, "Got bob via relationship");
        is($rob->relation('person'), $bob, "Got bob via relationship");

        my $robert_id = $robert->column('alias_id');
        $robert = undef;
        ok(!$con->{cache}->{$als}->{$robert_id}, "Robert is not in cache");

        $robert = $als->find(alias => 'robert');
        is(
            $robert->fetched_relations,
            {person => $bob},
            "prefetched person"
        );

        is($als->count_select({where => {person_id => $bob_id}}),             2, "Got proper count");
        is($als->count_select({where => {person_id => $bob_id}, limit => 1}), 1, "Got limit");
        is($als->count_select({where => {person_id => 9001}}),                0, "No rows");

        $robert = $als->find(where => {alias => 'robert'}, prefetch => 'person_way2');
        is(
            $robert->fetched_relations,
            {person => $bob, person_way2 => $bob},
            "prefetched person and person_way2"
        );

        my $rows = $bob->relations('aliases', order_by => 'alias_id');
        is($rows->count, 2, "Got count");

        is([$rows->all], [exact_ref($robert), exact_ref($rob)], "Got both aliases, cached");
        is($rows->count, 2, "Got count");

        $rows = $bob->relations('aliases', order_by => 'alias_id', limit => 1);
        is($rows->count, 1, "Got count");
        is([$rows->all], [exact_ref($robert)], "Got aliases, limited");
        is($rows->count, 1, "Got count");

        is(
            [$bob->relations('aliases_link', order_by => 'alias_id')->all],
            [exact_ref($robert), exact_ref($rob)],
            "Got relation built with 'relate' (aliases_link)"
        );

        is(
            $rob->relation('person_link'),
            exact_ref($bob),
            "Got relation built with 'relate' (person_link)"
        );

        $source->cache->clear();
        $source->set_row_class('DBIx::QuickORM::Row::AutoAccessors');

        $bob = $source->find($bob_id);
        isa_ok($bob, ['DBIx::QuickORM::Row::AutoAccessors'], "Correct row class");
        is($bob->person_id, $bob_id, "Can get column as accessor (autoloaded person_id method)");

        ok($rows = $bob->aliases(order_by => 'alias_id'), "autoloaded aliases method");
        is($rows->all, 2, "Got both aliases");

        $source->cache->clear();
        $als->set_row_class('DBIx::QuickORM::Row::AutoAccessors');

        $robert = $als->find(alias => 'robert');
        isa_ok($robert, ['DBIx::QuickORM::Row::AutoAccessors'], "Got correct row type");
        is($robert->person->person_id, $bob_id, "autoloaded person method");

        $bob = $source->find($bob_id);

        like(
            dies { $bob->fluggle },
            qr/Can't locate object method "fluggle" via package "DBIx::QuickORM::Row::AutoAccessors"/,
            "Correct exception for invalid method on blessed object"
        );

        like(
            dies { DBIx::QuickORM::Row::AutoAccessors->foo },
            qr/Can't locate object method "foo" via package "DBIx::QuickORM::Row::AutoAccessors"/,
            "Correct exception for invalid method on class"
        );
    };
}

done_testing;
