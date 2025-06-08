use Test2::V0 -target => 'DBIx::QuickORM', '!meta', '!pass';
use DBIx::QuickORM;

use lib 't/lib';
use DBIx::QuickORM::Test;
use Hash::Merge qw/merge/;
Hash::Merge::set_behavior('RIGHT_PRECEDENT');

my %BASE_SCHEMA = (
    row_class => 'DBIx::QuickORM::Row',
    tables    => {
        aliases => {
            name           => 'aliases',
            db_name        => 'aliases',
            primary_key    => ['alias_id'],
            is_temp        => F(),

            columns    => {
                alias_id => {affinity => 'numeric', db_name => 'alias_id', name => 'alias_id', nullable => F(), order => 1, identity => T()},
                light_id => {affinity => 'numeric', db_name => 'light_id', name => 'light_id', nullable => F(), order => 2},
                name     => {affinity => 'string',  db_name => 'name',     name => 'name',     nullable => F(), order => 3},
            },
            links => [
                {aliases => [], key => 'light_id', local_columns => ['light_id'], other_columns => ['light_id'], local_table => 'aliases', other_table => 'lights', unique => T(), created => T()},
            ],
            unique => {
                alias_id => ['alias_id'],
                name     => ['name'],
            },
        },
        complex_keys => {
            name           => 'complex_keys',
            db_name        => 'complex_keys',
            primary_key    => ['name_a', 'name_b'],
            is_temp        => F(),

            columns    => {
                name_a => {affinity => 'string', db_name => 'name_a', name => 'name_a', nullable => F(), order => 1},
                name_b => {affinity => 'string', db_name => 'name_b', name => 'name_b', nullable => F(), order => 2},
                name_c => {affinity => 'string', db_name => 'name_c', name => 'name_c', nullable => T(), order => 3},
            },
            links => [
                {aliases => [], key => 'name_a, name_b', local_columns => ['name_a', 'name_b'], other_columns => ['name_a', 'name_b'], local_table => 'complex_keys', other_table => 'complex_ref', unique => T(), created => T()},
            ],
            unique => {
                'name_a, name_b'         => ['name_a', 'name_b'],
                'name_a, name_b, name_c' => ['name_a', 'name_b', 'name_c'],
            },
        },
        complex_ref => {
            name           => 'complex_ref',
            db_name        => 'complex_ref',
            primary_key    => ['name_a', 'name_b'],
            is_temp        => F(),

            columns    => {
                name_a => {affinity => 'string', db_name => 'name_a', name => 'name_a', nullable => F(), order => 1},
                name_b => {affinity => 'string', db_name => 'name_b', name => 'name_b', nullable => F(), order => 2},
                extras => {affinity => 'string', db_name => 'extras', name => 'extras', nullable => T(), order => 3},
            },
            links => [
                {aliases => [], key => 'name_a, name_b', local_columns => ['name_a', 'name_b'], other_columns => ['name_a', 'name_b'], local_table => 'complex_ref', other_table => 'complex_keys', unique => T(), created => T()},
            ],
            unique => {
                'name_a, name_b' => ['name_a', 'name_b',],
            },
        },
        light_by_name => {
            name           => 'light_by_name',
            db_name        => 'light_by_name',
            primary_key    => undef,
            is_temp        => F(),
            links          => [],
            unique         => {},
            indexes        => [],

            columns    => {
                name       => {affinity => 'string',  db_name => 'name',       name => 'name',       nullable => T(), order => 1},
                alias_id   => {affinity => 'numeric', db_name => 'alias_id',   name => 'alias_id',   nullable => T(), order => 2},
                light_id   => {affinity => 'numeric', db_name => 'light_id',   name => 'light_id',   nullable => T(), order => 3},
                light_uuid => {affinity => 'string',  db_name => 'light_uuid', name => 'light_uuid', nullable => T(), order => 4, type => 'DBIx::QuickORM::Type::UUID'},
                stamp      => {affinity => 'string',  db_name => 'stamp',      name => 'stamp',      nullable => T(), order => 5},
                color      => {affinity => 'string',  db_name => 'color',      name => 'color',      nullable => T(), order => 6},
            },
        },
        lights => {
            name           => 'lights',
            db_name        => 'lights',
            primary_key    => ['light_id',],
            is_temp        => F(),

            columns    => {
                light_id   => {affinity => 'numeric', db_name => 'light_id',   name => 'light_id',   nullable => F(), order => 1, identity => T()},
                light_uuid => {affinity => 'string',  db_name => 'light_uuid', name => 'light_uuid', nullable => F(), order => 2, type     => 'DBIx::QuickORM::Type::UUID'},
                stamp      => {affinity => 'string',  db_name => 'stamp',      name => 'stamp',      nullable => T(), order => 3},
                color      => {affinity => 'string',  db_name => 'color',      name => 'color',      nullable => F(), order => 4},
            },
            links => [
                {aliases => [], key => 'light_id', local_columns => ['light_id'], other_columns => ['light_id'], local_table => 'lights', other_table => 'aliases', unique => F(), created => T()},
            ],
            unique => {
                light_id => ['light_id',],
            },
        },
    },
);

my %OVERRIDES = (
    PostgreSQL => {
        tables => {
            aliases => {
                columns => {
                    alias_id => {type => \'int4'},
                    light_id => {type => \'int4'},
                    name     => {type => \'varchar'},
                },
                indexes => [
                    {columns => ['name'],     name => 'aliases_name_key', type => 'btree', unique => 1},
                    {columns => ['alias_id'], name => 'aliases_pkey',     type => 'btree', unique => 1},
                ],
            },
            complex_keys => {
                columns => {
                    name_a => {type => \'bpchar'},
                    name_b => {type => \'bpchar'},
                    name_c => {type => \'bpchar'},
                },
                indexes => [
                    {columns => ['name_a', 'name_b', 'name_c'], name => 'complex_keys_name_a_name_b_name_c_key', type => 'btree', unique => 1},
                    {columns => ['name_a', 'name_b'], name => 'complex_keys_pkey', type => 'btree', unique => 1},
                ],
            },
            complex_ref => {
                columns => {
                    name_a => {type => \'bpchar'},
                    name_b => {type => \'bpchar'},
                    extras => {type => \'bpchar'},
                },
                indexes => [
                    {columns => ['name_a', 'name_b'], name => 'complex_ref_pkey', type => 'btree', unique => 1},
                ],
            },
            light_by_name => {
                columns => {
                    name       => {nullable => T(), type => \'varchar'},
                    alias_id   => {nullable => T(), type => \'int4'},
                    light_id   => {nullable => T(), type => \'int4'},
                    light_uuid => {nullable => T()},
                    stamp      => {nullable => T(), type => \'timestamptz'},
                    color      => {nullable => T(), type => \'color'},
                },
            },
            lights => {
                columns => {
                    light_id => {type => \'int4'},
                    stamp    => {type => \'timestamptz'},
                    color    => {type => \'color'},
                },
                indexes => [
                    {columns => ['light_id'], name => 'lights_pkey', type => 'btree', unique => 1},
                ],
            },
        },
    },
    MySQL => {
        tables    => {
            aliases => {
                columns => {
                    alias_id => {type => \'int'},
                    light_id => {type => \'int'},
                    name     => {type => \'varchar'},
                },
                indexes => [
                    {columns => ['alias_id'], name => 'PRIMARY',  type => 'BTREE', unique => T()},
                    {columns => ['light_id'], name => 'light_id', type => 'BTREE', unique => F()},
                    {columns => ['name'],     name => 'name',     type => 'BTREE', unique => T()},
                ],
            },
            complex_keys => {
                columns => {
                    name_a => {type => \'char'},
                    name_b => {type => \'char'},
                    name_c => {type => \'char'},
                },
                indexes => [
                    {columns => ['name_a', 'name_b'],           name => 'PRIMARY', type => 'BTREE', unique => T()},
                    {columns => ['name_a', 'name_b', 'name_c'], name => 'name_a',  type => 'BTREE', unique => T()},
                ],
            },
            complex_ref => {
                columns => {
                    name_a => {type => \'char'},
                    name_b => {type => \'char'},
                    extras => {type => \'char'},
                },
                indexes => [
                    {columns => ['name_a', 'name_b'], name => 'PRIMARY', type => 'BTREE', unique => T()},
                ],
            },
            light_by_name => {
                columns => {
                    light_uuid => {nullable => F(), affinity => 'binary'},
                    name       => {nullable => F(), type => \'varchar'},
                    alias_id   => {nullable => F(), type => \'int'},
                    light_id   => {nullable => F(), type => \'int'},
                    stamp      => {nullable => T(), type => \'timestamp'},
                    color      => {nullable => F(), type => \'enum'},
                },
            },
            lights => {
                columns => {
                    light_uuid => {affinity => 'binary'},
                    light_id   => {type => \'int'},
                    stamp      => {type => \'timestamp'},
                    color      => {type => \'enum'},
                },
                indexes => [
                    {columns => ['light_id'], name => 'PRIMARY', type => 'BTREE', unique => T()},
                ],
            },
        },
    },
    'MySQL::MariaDB' => {
        tables    => {
            aliases => {
                columns => {
                    alias_id => {type => \'int'},
                    light_id => {type => \'int'},
                    name     => {type => \'varchar'},
                },
                indexes => [
                    {columns => ['alias_id'], name => 'PRIMARY',  type => 'BTREE', unique => T()},
                    {columns => ['light_id'], name => 'light_id', type => 'BTREE', unique => F()},
                    {columns => ['name'],     name => 'name',     type => 'BTREE', unique => T()},
                ],
            },
            complex_keys => {
                columns => {
                    name_a => {type => \'char'},
                    name_b => {type => \'char'},
                    name_c => {type => \'char'},
                },
                indexes => [
                    {columns => ['name_a', 'name_b'],           name => 'PRIMARY', type => 'BTREE', unique => T()},
                    {columns => ['name_a', 'name_b', 'name_c'], name => 'name_a',  type => 'BTREE', unique => T()},
                ],
            },
            complex_ref => {
                columns => {
                    name_a => {type => \'char'},
                    name_b => {type => \'char'},
                    extras => {type => \'char'},
                },
                indexes => [
                    {columns => ['name_a', 'name_b'], name => 'PRIMARY', type => 'BTREE', unique => T()},
                ],
            },
            light_by_name => {
                columns => {
                    light_uuid => {nullable => F()},
                    name       => {nullable => F(), type => \'varchar'},
                    alias_id   => {nullable => F(), type => \'int'},
                    light_id   => {nullable => F(), type => \'int'},
                    stamp      => {nullable => T(), type => \'timestamp'},
                    color      => {nullable => F(), type => \'enum'},
                },
            },
            lights => {
                columns => {
                    light_id   => {type => \'int'},
                    stamp      => {type => \'timestamp'},
                    color      => {type => \'enum'},
                },
                indexes => [
                    {columns => ['light_id'], name => 'PRIMARY', type => 'BTREE', unique => T()},
                ],
            },
        },
    },
    SQLite => {
        tables    => {
            aliases => {
                columns => {
                    alias_id => {type => \'INTEGER'},
                    light_id => {type => \'INTEGER'},
                    name     => {type => \'VARCHAR'},
                },
                indexes => [
                    {columns => ['alias_id'], name => 'aliases:pk',     unique => 1},
                    {columns => ['name'],     name => 'sqlite_autoindex_aliases_1', unique => 1},
                ],
            },
            complex_keys => {
                columns => {
                    name_a => {type => \'CHAR'},
                    name_b => {type => \'CHAR'},
                    name_c => {type => \'CHAR'},
                },
                indexes => [
                    {columns => ['name_a', 'name_b'], name => 'complex_keys:pk', unique => 1},
                    {columns => ['name_a', 'name_b', 'name_c'], name => 'sqlite_autoindex_complex_keys_1', unique => 1},
                    {columns => ['name_a', 'name_b'], name => 'sqlite_autoindex_complex_keys_2', unique => 1},
                ],
            },
            complex_ref => {
                columns => {
                    name_a => {type => \'CHAR'},
                    name_b => {type => \'CHAR'},
                    extras => {type => \'CHAR'},
                },
                indexes => [
                    {columns => ['name_a', 'name_b'], name => 'complex_ref:pk', unique => 1},
                    {columns => ['name_a', 'name_b'], name => 'sqlite_autoindex_complex_ref_1', unique => 1},
                ],
            },
            light_by_name => {
                columns => {
                    name       => {type => \'VARCHAR'},
                    alias_id   => {type => \'INTEGER'},
                    light_id   => {type => \'INTEGER'},
                    stamp      => {type => \'TIMESTAMP'},
                    color      => {type => \'TEXT'},
                },
            },
            lights => {
                columns => {
                    light_id   => {type => \'INTEGER'},
                    stamp      => {type => \'TIMESTAMP'},
                    color      => {type => \'TEXT'},
                },
                indexes => [
                    {columns => ['light_id'], name => 'lights:pk', unique => 1},
                ],
            },
        },
    },
);

$OVERRIDES{'MySQL::Percona'}   = $OVERRIDES{'MySQL'};
$OVERRIDES{'MySQL::Community'} = $OVERRIDES{'MySQL'};

do_for_all_dbs {
    my $db = shift;

    db mydb => sub {
        dialect curdialect();
        db_name 'quickdb';
        connect sub { $db->connect };
    };

    orm myorm => sub {
        db 'mydb';
        autofill sub {
            autotype 'UUID';
        };
    };

    my $con = orm('myorm')->connect;
    use DBIx::QuickORM::Util qw/debug/;
    note "Using dialect '" . $con->dialect->dialect_name . "'";

    my $schema = $con->schema;
    is(
        $schema,
        merge(\%BASE_SCHEMA, $OVERRIDES{curdialect()}),
        "Generated a schema"
    );

    isa_ok($schema, ['DBIx::QuickORM::Schema'], "Schema is the correct type");
    for my $table ($schema->tables) {
        isa_ok($table, ['DBIx::QuickORM::Schema::Table'], "Table $table->{name} is correct type");
        isa_ok($table, ['DBIx::QuickORM::Schema::View'], "View $table->{name} is a view") if $table->name eq 'light_by_name';

        for my $col ($table->columns) {
            isa_ok($col, ['DBIx::QuickORM::Schema::Table::Column'], "Column $table->{name}.$col->{name} is correct type");
        }

        for my $link (@{$table->links}) {
            isa_ok($link, ['DBIx::QuickORM::Link'], "Link $table->{name}->$link->{other_table} is correct type");
        }
    }

    isa_ok($schema->maybe_table('aliases'), ['DBIx::QuickORM::Schema::Table'], "Can get table by name");
    isa_ok($schema->maybe_table('aliases')->column('alias_id'), ['DBIx::QuickORM::Schema::Table::Column'], "Can get column by name");
    isa_ok($schema->maybe_table('aliases')->resolve_link(table => 'lights'), ['DBIx::QuickORM::Link'], "Can get link by table");
    isa_ok($schema->maybe_table('aliases')->resolve_link(table => 'lights', cols => ['light_id']), ['DBIx::QuickORM::Link'], "Can get link by table + cols");
};

done_testing;
