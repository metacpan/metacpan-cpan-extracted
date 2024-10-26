use Test2::V0;
use Importer 'Test2::Tools::QuickDB' => (get_db => {-as => 'get_qdb'});
use DBIx::QuickORM;
use Data::Dumper;

BEGIN {
    $ENV{PATH} = "/home/exodist/percona/bin:$ENV{PATH}" if -d "/home/exodist/percona/bin";
}

my $psql_file    = __FILE__;
my $mysql_file   = __FILE__;
my $mariadb_file = __FILE__;
my $sqlite_file  = __FILE__;

$psql_file    =~ s/\.t$/_postgresql.sql/;
$mysql_file   =~ s/\.t$/_mysql.sql/;
$mariadb_file =~ s/\.t$/_mariadb.sql/;
$sqlite_file  =~ s/\.t$/_sqlite.sql/;

my $psql    = eval { get_qdb({driver => 'PostgreSQL', load_sql => [quickdb => $psql_file]}) }    or diag(clean_err($@));
my $mariadb = eval { get_qdb({driver => 'MariaDB',    load_sql => [quickdb => $mariadb_file]}) } or diag(clean_err($@));
my $mysql   = eval { get_qdb({driver => 'MySQL',      load_sql => [quickdb => $mysql_file]}) }   or diag(clean_err($@));
my $percona = eval { get_qdb({driver => 'Percona',    load_sql => [quickdb => $mysql_file]}) }   or diag(clean_err($@));
my $sqlite  = eval { get_qdb({driver => 'SQLite',     load_sql => [quickdb => $sqlite_file]}) }  or diag(clean_err($@));

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

db postgresql => sub {
    db_class 'PostgreSQL';
    db_name 'quickdb';
    db_connect sub { $psql->connect };
} if $psql;

db mariadb => sub {
    db_class 'MariaDB';
    db_name 'quickdb';
    db_connect sub { $mariadb->connect };
} if $mariadb;

db mysql => sub {
    db_class 'MySQL';
    db_name 'quickdb';
    db_connect sub { $mysql->connect };
} if $mysql;

db percona => sub {
    db_class 'Percona';
    db_name 'quickdb';
    db_connect sub { $percona->connect };
} if $percona;

db sqlite => sub {
    db_class 'SQLite';
    db_name 'quickdb';
    db_connect sub { $sqlite->connect };
} if $sqlite;

my $keys = {
    lights => {
        pk     => ['light_id'],
        unique => [['light_id']],
    },
    aliases => {
        pk     => ['alias_id'],
        fk     => [{columns => ['light_id'], foreign_columns => ['light_id'], foreign_table => 'lights'}],
        unique => bag { item ['alias_id']; item ['name']; end },
    },
    light_by_name => {},
    complex_keys  => {
        pk     => bag { item 'name_a'; item 'name_b'; end },
        unique => bag { item bag { item 'name_a'; item 'name_b'; end }; item bag { item 'name_a'; item 'name_b'; item 'name_c'; end }; end },
    },
    complex_ref => {
        fk     => [{columns => bag { item 'name_a'; item 'name_b'; end }, foreign_columns => bag { item 'name_a'; item 'name_b'; end }, foreign_table => 'complex_keys'}],
        pk     => bag { item 'name_a'; item 'name_b'; end },
        unique => [ bag { item 'name_a'; item 'name_b'; end }],
    },
};

my ($pg_schema, $mariadb_schema, $sqlite_schema, $mysql_schema, $percona_schema);
subtest PostgreSQL => sub {
    skip_all "Could not find PostgreSQL" unless $psql;
    my $pdb = db('postgresql');
    isa_ok($pdb, ['DBIx::QuickORM::DB', 'DBIx::QuickORM::DB::PostgreSQL'], "Got a database instance");

    my $c = $pdb->connect;
    my $dbh = $c->dbh;

    is($c->dbh, $dbh, "Got the same dbh, it was cached");

    is($c->db_keys($_), $keys->{$_}, "Got expected data structure for table '$_' keys") for keys %$keys;

    is($c->column_type(lights => 'stamp'), {data_type => match(qr/timestamp/), sql_type => 'timestamptz', is_datetime => T(), name => 'stamp'}, "Can get column type for stamp");
    ref_is($c->column_type(lights => 'stamp'), $c->column_type(lights => 'stamp'), "Cache the column type");
    is($c->column_type(lights => 'light_uuid'), {data_type => 'uuid', sql_type => 'uuid', is_datetime => F(), name => 'light_uuid'}, "Can get column type for uuid");

    $pg_schema = $c->generate_schema;

    like(
        $pg_schema->{tables},
        {
            aliases => {
                indexes => {
                    aliases_name_key => {
                        name     => 'aliases_name_key',
                        type     => 'btree',
                        columns  => ['name'],
                        created  => T(),
                        unique   => T(),
                        sql_spec => {postgresql => {def => 'CREATE UNIQUE INDEX aliases_name_key ON public.aliases USING btree (name)'}},
                    },
                    aliases_pkey => {
                        name     => 'aliases_pkey',
                        type     => 'btree',
                        columns  => ['alias_id'],
                        created  => T(),
                        unique   => T(),
                        sql_spec => {postgresql => {def => 'CREATE UNIQUE INDEX aliases_pkey ON public.aliases USING btree (alias_id)'}},
                    },
                },
            },

            complex_keys => {
                indexes => {
                    complex_keys_name_a_name_b_name_c_key => {
                        name     => 'complex_keys_name_a_name_b_name_c_key',
                        type     => 'btree',
                        columns  => [qw/ name_a name_b name_c /],
                        unique   => T(),
                        created  => T(),
                        sql_spec => {postgresql => {def => 'CREATE UNIQUE INDEX complex_keys_name_a_name_b_name_c_key ON public.complex_keys USING btree (name_a, name_b, name_c)'}},
                    },
                    complex_keys_pkey => {
                        name     => 'complex_keys_pkey',
                        type     => 'btree',
                        columns  => [qw/ name_a name_b /],
                        unique   => T(),
                        created  => T(),
                        sql_spec => {postgresql => {def => 'CREATE UNIQUE INDEX complex_keys_pkey ON public.complex_keys USING btree (name_a, name_b)'}},
                    },
                },
            },

            complex_ref => {
                indexes => {
                    complex_ref_pkey => {
                        name     => 'complex_ref_pkey',
                        type     => 'btree',
                        columns  => [qw/name_a name_b/],
                        unique   => T(),
                        created  => T(),
                        sql_spec => {postgresql => {def => 'CREATE UNIQUE INDEX complex_ref_pkey ON public.complex_ref USING btree (name_a, name_b)'}},
                    },
                },
            },

            lights => {
                indexes => {
                    lights_pkey => {
                        name     => 'lights_pkey',
                        type     => 'btree',
                        columns  => ['light_id'],
                        unique   => T(),
                        created  => T(),
                        sql_spec => {postgresql => {def => 'CREATE UNIQUE INDEX lights_pkey ON public.lights USING btree (light_id)'}},
                    },
                },
            },
        },
        "Generated indexes properly"
    );
};

subtest MariaDB => sub {
    skip_all "Could not find MariaDB" unless $mariadb;
    my $pdb = db('mariadb');
    isa_ok($pdb, ['DBIx::QuickORM::DB', 'DBIx::QuickORM::DB::MariaDB'], "Got a database instance");

    my $c = $pdb->connect;
    my $dbh = $c->dbh;
    is($c->dbh, $dbh, "Got the same dbh, it was cached");

    is($c->db_keys($_), $keys->{$_}, "Got expected data structure for table '$_' keys") for keys %$keys;

    is($c->column_type(lights => 'stamp'), {data_type => match(qr/timestamp/), sql_type => 'timestamp(6)', is_datetime => T(), name => 'stamp'}, "Can get column type for stamp");
    ref_is($c->column_type(lights => 'stamp'), $c->column_type(lights => 'stamp'), "Cache the column type");
    is($c->column_type(lights => 'light_uuid'), {data_type => 'uuid', sql_type => 'uuid', is_datetime => F(), name => 'light_uuid'}, "Can get column type for uuid");

    $mariadb_schema = $c->generate_schema;

    like(
        $mariadb_schema->{tables},
        {
            aliases => {
                indexes => {
                    name => {
                        name      => 'name',
                        type      => 'BTREE',
                        columns   => ['name'],
                        created   => T(),
                        unique    => T(),
                    },
                    light_id => {
                        name      => 'light_id',
                        type      => 'BTREE',
                        columns   => ['light_id'],
                        created   => T(),
                        unique    => F(),
                    },
                    PRIMARY => {
                        name      => 'PRIMARY',
                        type      => 'BTREE',
                        columns   => ['alias_id'],
                        created   => T(),
                        unique    => T(),
                    },
                },
            },

            complex_keys => {
                indexes => {
                    name_a => {
                        name      => 'name_a',
                        type      => 'BTREE',
                        columns   => [qw/ name_a name_b name_c /],
                        unique    => T(),
                        created   => T(),
                    },
                    PRIMARY => {
                        name      => 'PRIMARY',
                        type      => 'BTREE',
                        columns   => [qw/ name_a name_b /],
                        unique    => T(),
                        created   => T(),
                    },
                },
            },

            complex_ref => {
                indexes => {
                    PRIMARY => {
                        name      => 'PRIMARY',
                        type      => 'BTREE',
                        columns   => [qw/name_a name_b/],
                        unique    => T(),
                        created   => T(),
                    },
                },
            },

            lights => {
                indexes => {
                    PRIMARY => {
                        name      => 'PRIMARY',
                        type      => 'BTREE',
                        columns   => ['light_id'],
                        unique    => T(),
                        created   => T(),
                    },
                },
            },
        },
        "Generated indexes properly"
    );
};

subtest MySQL => sub {
    skip_all "Could not find MySQL" unless $mysql;
    my $pdb = db('mysql');
    isa_ok($pdb, ['DBIx::QuickORM::DB', 'DBIx::QuickORM::DB::MySQL'], "Got a database instance");

    my $c = $pdb->connect;
    my $dbh = $c->dbh;
    is($c->dbh, $dbh, "Got the same dbh, it was cached");

    is($c->db_keys($_), $keys->{$_}, "Got expected data structure for table '$_' keys") for keys %$keys;

    is($c->column_type(lights => 'stamp'), {data_type => match(qr/timestamp/), sql_type => 'timestamp(6)', is_datetime => T(), name => 'stamp'}, "Can get column type for stamp");
    ref_is($c->column_type(lights => 'stamp'), $c->column_type(lights => 'stamp'), "Cache the column type");
    is($c->column_type(lights => 'light_uuid'), {data_type => 'binary', sql_type => 'binary(16)', is_datetime => F(), name => 'light_uuid'}, "Can get column type for binary(16)");

    $mysql_schema = $c->generate_schema;

    like(
        $mysql_schema->{tables},
        {
            aliases => {
                indexes => {
                    name => {
                        name      => 'name',
                        type      => 'BTREE',
                        columns   => ['name'],
                        created   => T(),
                        unique    => T(),
                    },
                    light_id => {
                        name      => 'light_id',
                        type      => 'BTREE',
                        columns   => ['light_id'],
                        created   => T(),
                        unique    => F(),
                    },
                    PRIMARY => {
                        name      => 'PRIMARY',
                        type      => 'BTREE',
                        columns   => ['alias_id'],
                        created   => T(),
                        unique    => T(),
                    },
                },
            },

            complex_keys => {
                indexes => {
                    name_a => {
                        name      => 'name_a',
                        type      => 'BTREE',
                        columns   => [qw/ name_a name_b name_c /],
                        unique    => T(),
                        created   => T(),
                    },
                    PRIMARY => {
                        name      => 'PRIMARY',
                        type      => 'BTREE',
                        columns   => [qw/ name_a name_b /],
                        unique    => T(),
                        created   => T(),
                    },
                },
            },

            complex_ref => {
                indexes => {
                    PRIMARY => {
                        name      => 'PRIMARY',
                        type      => 'BTREE',
                        columns   => [qw/name_a name_b/],
                        unique    => T(),
                        created   => T(),
                    },
                },
            },

            lights => {
                indexes => {
                    PRIMARY => {
                        name      => 'PRIMARY',
                        type      => 'BTREE',
                        columns   => ['light_id'],
                        unique    => T(),
                        created   => T(),
                    },
                },
            },
        },
        "Generated indexes properly"
    );
};

subtest Percona => sub {
    skip_all "Could not find Percona" unless $percona;
    my $pdb = db('percona');
    isa_ok($pdb, ['DBIx::QuickORM::DB', 'DBIx::QuickORM::DB::Percona'], "Got a database instance");

    my $c = $pdb->connect;
    my $dbh = $c->dbh;
    is($c->dbh, $dbh, "Got the same dbh, it was cached");

    is($c->db_keys($_), $keys->{$_}, "Got expected data structure for table '$_' keys") for keys %$keys;

    is($c->column_type(lights => 'stamp'), {data_type => match(qr/timestamp/), sql_type => 'timestamp(6)', is_datetime => T(), name => 'stamp'}, "Can get column type for stamp");
    ref_is($c->column_type(lights => 'stamp'), $c->column_type(lights => 'stamp'), "Cache the column type");
    is($c->column_type(lights => 'light_uuid'), {data_type => 'binary', sql_type => 'binary(16)', is_datetime => F(), name => 'light_uuid'}, "Can get column type for binary(16)");

    $percona_schema = $c->generate_schema;

    like(
        $percona_schema->{tables},
        {
            aliases => {
                indexes => {
                    name => {
                        name      => 'name',
                        type      => 'BTREE',
                        columns   => ['name'],
                        created   => T(),
                        unique    => T(),
                    },
                    light_id => {
                        name      => 'light_id',
                        type      => 'BTREE',
                        columns   => ['light_id'],
                        created   => T(),
                        unique    => F(),
                    },
                    PRIMARY => {
                        name      => 'PRIMARY',
                        type      => 'BTREE',
                        columns   => ['alias_id'],
                        created   => T(),
                        unique    => T(),
                    },
                },
            },

            complex_keys => {
                indexes => {
                    name_a => {
                        name      => 'name_a',
                        type      => 'BTREE',
                        columns   => [qw/ name_a name_b name_c /],
                        unique    => T(),
                        created   => T(),
                    },
                    PRIMARY => {
                        name      => 'PRIMARY',
                        type      => 'BTREE',
                        columns   => [qw/ name_a name_b /],
                        unique    => T(),
                        created   => T(),
                    },
                },
            },

            complex_ref => {
                indexes => {
                    PRIMARY => {
                        name      => 'PRIMARY',
                        type      => 'BTREE',
                        columns   => [qw/name_a name_b/],
                        unique    => T(),
                        created   => T(),
                    },
                },
            },

            lights => {
                indexes => {
                    PRIMARY => {
                        name      => 'PRIMARY',
                        type      => 'BTREE',
                        columns   => ['light_id'],
                        unique    => T(),
                        created   => T(),
                    },
                },
            },
        },
        "Generated indexes properly"
    );
};

subtest SQLite => sub {
    skip_all "Could not find SQLite" unless $sqlite;
    my $pdb = db('sqlite');
    isa_ok($pdb, ['DBIx::QuickORM::DB', 'DBIx::QuickORM::DB::SQLite'], "Got a database instance");

    my $c = $pdb->connect;
    my $dbh = $c->dbh;
    is($c->dbh, $dbh, "Got the same dbh, it was cached");

    is($c->db_keys($_), $keys->{$_}, "Got expected data structure for table '$_' keys") for keys %$keys;

    is($c->column_type(lights => 'stamp'), {data_type => match(qr/timestamp/i), sql_type => 'TIMESTAMP(6)', is_datetime => T(), name => 'stamp'}, "Can get column type for stamp");
    ref_is($c->column_type(lights => 'stamp'), $c->column_type(lights => 'stamp'), "Cache the column type");
    is($c->column_type(lights => 'light_uuid'), {data_type => 'UUID', sql_type => 'UUID', is_datetime => F(), name => 'light_uuid'}, "Can get column type for uuid");

    $sqlite_schema = $c->generate_schema;

    like(
        $sqlite_schema->{tables},
        {
            aliases => {
                indexes => {
                    sqlite_autoindex_aliases_1 => {
                        name    => 'sqlite_autoindex_aliases_1',
                        columns => ['name'],
                        created => T(),
                        unique  => T(),
                    },
                    ':pk' => {
                        name    => ':pk',
                        columns => ['alias_id'],
                        created => T(),
                        unique  => T(),
                    },
                },
            },

            complex_keys => {
                indexes => {
                    sqlite_autoindex_complex_keys_1 => {
                        name    => 'sqlite_autoindex_complex_keys_1',
                        columns => [qw/ name_a name_b name_c /],
                        unique  => T(),
                        created => T(),
                    },
                    sqlite_autoindex_complex_keys_2 => {
                        name    => 'sqlite_autoindex_complex_keys_2',
                        columns => [qw/ name_a name_b /],
                        unique  => T(),
                        created => T(),
                    },
                    ':pk' => {
                        name    => ':pk',
                        columns => [qw/ name_a name_b /],
                        unique  => T(),
                        created => T(),
                    },
                },
            },

            complex_ref => {
                indexes => {
                    sqlite_autoindex_complex_ref_1 => {
                        name    => 'sqlite_autoindex_complex_ref_1',
                        columns => [qw/name_a name_b/],
                        unique  => T(),
                        created => T(),
                    },
                    ':pk' => {
                        'name'    => ':pk',
                        'columns' => [qw/name_a name_b/],
                        'created' => T(),
                        'unique'  => T(),
                    },
                },
            },

            lights => {
                indexes => {
                    ':pk' => {
                        name    => ':pk',
                        columns => ['light_id'],
                        unique  => T(),
                        created => T(),
                    },
                },
            },
        },
        "Generated indexes properly"
    );
};

my $aliases = {
    name        => 'aliases',
    primary_key => ['alias_id'],
    is_temp     => F(),
    is_view     => F(),
    created     => T(),
    sql_spec    => T(),
    indexes     => T(),

    unique => {
        alias_id => ['alias_id'],
        name     => ['name'],
    },

    relations => {
        lights => {
            gets_one  => 1,
            gets_many => 0,
            prefetch  => 0,
            method    => 'find',
            table     => 'lights',
            on        => {light_id => 'light_id'},
        },
    },

    columns => {
        alias_id => {
            name        => 'alias_id',
            primary_key => T(),
            unique      => T(),
            created     => T(),
            order       => T(),
            sql_spec    => T(),
        },
        light_id => {
            name     => 'light_id',
            created  => T(),
            order    => T(),
            sql_spec => T(),
        },
        name => {
            name     => 'name',
            unique   => T(),
            created  => T(),
            order    => T(),
            sql_spec => T(),
        },
    },
};

my $complex_keys = {
    name        => 'complex_keys',
    primary_key => ['name_a', 'name_b'],
    is_temp     => F(),
    is_view     => F(),
    created     => T(),
    sql_spec    => T(),
    indexes     => T(),

    unique => {
        'name_a, name_b'         => ['name_a', 'name_b'],
        'name_a, name_b, name_c' => ['name_a', 'name_b', 'name_c'],
    },

    relations => {
        complex_ref => {
            gets_one  => 0,
            gets_many => 1,
            prefetch  => 0,
            method    => 'select',
            table     => 'complex_ref',
            on        => {name_a => 'name_a', name_b => 'name_b'},
        },
    },

    columns => {
        name_a => {
            created     => T(),
            name        => 'name_a',
            primary_key => FDNE(),
            order       => T(),
            sql_spec    => T(),
        },
        name_b => {
            name        => 'name_b',
            primary_key => FDNE(),
            created     => T(),
            order       => T(),
            sql_spec    => T(),
        },
        name_c => {
            name     => 'name_c',
            created  => T(),
            order    => T(),
            sql_spec => T(),
        },
    },
};

my $complex_ref = {
    name        => 'complex_ref',
    primary_key => ['name_a', 'name_b'],
    is_temp     => F(),
    is_view     => F(),
    created     => T(),
    sql_spec    => T(),
    indexes     => T(),

    unique => {
        'name_a, name_b' => ['name_a', 'name_b'],
    },

    relations => {
        complex_keys => {
            gets_one  => 1,
            gets_many => 0,
            prefetch  => 0,
            method    => 'find',
            table     => 'complex_keys',
            on        => {name_a => 'name_a', name_b => 'name_b'},
        },
    },

    columns => {
        extras => {
            name     => 'extras',
            created  => T(),
            order    => T(),
            sql_spec => T(),
        },
        name_a => {
            name        => 'name_a',
            primary_key => FDNE(),
            created     => T(),
            order       => T(),
            sql_spec    => T(),
        },
        name_b => {
            name        => 'name_b',
            primary_key => FDNE(),
            created     => T(),
            order       => T(),
            sql_spec    => T(),
        },
    },
};

my $light_by_name = {
    name     => 'light_by_name',
    is_temp  => F(),
    is_view  => T(),
    created  => T(),
    sql_spec => T(),

    relations => {},
    indexes   => {},

    columns => {
        alias_id => {
            name     => 'alias_id',
            created  => T(),
            order    => T(),
            sql_spec => T(),
        },
        color => {
            name     => 'color',
            created  => T(),
            order    => T(),
            sql_spec => T(),
        },
        light_id => {
            name     => 'light_id',
            created  => T(),
            order    => T(),
            sql_spec => T(),
        },
        light_uuid => {
            name     => 'light_uuid',
            conflate => 'DBIx::QuickORM::Conflator::UUID',
            created  => T(),
            order    => T(),
            sql_spec => T(),
        },
        name => {
            name     => 'name',
            created  => T(),
            order    => T(),
            sql_spec => T(),
        },
        stamp => {
            name     => 'stamp',
            conflate => 'DBIx::QuickORM::Conflator::DateTime',
            created  => T(),
            order    => T(),
            sql_spec => T(),
        },
    },
};

my $lights = {
    name        => 'lights',
    primary_key => ['light_id'],
    is_temp     => F(),
    is_view     => F(),
    created     => T(),
    sql_spec    => T(),
    indexes     => T(),

    unique => {light_id => ['light_id']},

    relations => {
        aliases => {
            gets_one  => 0,
            gets_many => 1,
            prefetch  => 0,
            method    => 'select',
            table     => 'aliases',
            on        => {light_id => 'light_id'},
        },
    },

    columns => {
        color => {
            name     => 'color',
            created  => T(),
            order    => T(),
            sql_spec => T(),
        },
        light_id => {
            name        => 'light_id',
            primary_key => T(),
            unique      => T(),
            created     => T(),
            order       => T(),
            sql_spec    => T(),
        },
        light_uuid => {
            name     => 'light_uuid',
            conflate => 'DBIx::QuickORM::Conflator::UUID',
            created  => T(),
            order    => T(),
            sql_spec => T(),
        },
        stamp => {
            name     => 'stamp',
            conflate => 'DBIx::QuickORM::Conflator::DateTime',
            created  => T(),
            order    => T(),
            sql_spec => T(),
        },
    },
};

my $tables = {
    aliases       => $aliases,
    complex_keys  => $complex_keys,
    complex_ref   => $complex_ref,
    light_by_name => $light_by_name,
    lights        => $lights,
};

is($pg_schema,      {locator => T(), tables => $tables, created => T()}, "Got PG Schema")      if $psql;
is($mariadb_schema, {locator => T(), tables => $tables, created => T()}, "Got MariaDB Schema") if $mariadb;
is($mysql_schema,   {locator => T(), tables => $tables, created => T()}, "Got MySQL Schema")   if $mysql;
is($percona_schema, {locator => T(), tables => $tables, created => T()}, "Got Percona Schema") if $percona;
is($sqlite_schema,  {locator => T(), tables => $tables, created => T()}, "Got SQLite Schema")  if $sqlite;

#system($sqlite->shell_command('quickdb')) unless $ENV{HARNESS_ACTIVE};

done_testing;
