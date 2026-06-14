use Test2::V0 '!meta', '!pass';
use DBIx::QuickORM::Schema::Table;
use DBIx::QuickORM::Schema::Table::Column;

# Simulate the autofill merge: an introspected table (columns keyed by database
# name, name == db_name) merged with a user table that aliases those columns
# (columns keyed by ORM name with a db_name pointing at the database column).
# The database is canonical, so introspected metadata fills gaps while the
# user's ORM names and overrides win, and the result is uniformly ORM-keyed.

my $C = 'DBIx::QuickORM::Schema::Table::Column';

my $introspected = DBIx::QuickORM::Schema::Table->new(
    name    => 'example',
    db_name => 'example',
    columns => {
        id   => $C->new(name => 'id',   db_name => 'id',   order => 1, identity => 1, nullable => 0, affinity => 'numeric'),
        uuid => $C->new(name => 'uuid', db_name => 'uuid', order => 2,                nullable => 0, affinity => 'binary'),
    },
    primary_key => ['id'],
    unique      => {'uuid' => ['uuid']},
    indexes     => [{name => 'example_uuid_idx', columns => ['uuid'], unique => 1}],
);

my $user = DBIx::QuickORM::Schema::Table->new(
    name    => 'example',
    columns => {
        my_id   => $C->new(name => 'my_id',   db_name => 'id',   order => 1, affinity => 'numeric'),
        my_uuid => $C->new(name => 'my_uuid', db_name => 'uuid', order => 2, affinity => 'binary'),
    },
    primary_key => ['my_id'],
);

my $merged = $introspected->merge($user);

is([sort $merged->column_names], ['my_id', 'my_uuid'], "merged columns are keyed by ORM name");
is($merged->primary_key, ['my_id'], "primary key translated to ORM name");

my $my_id = $merged->column('my_id');
is($my_id->db_name, 'id', "aliased column keeps its database name");
ok($my_id->identity, "identity metadata filled in from introspection");
is($my_id->nullable, 0, "nullable metadata filled in from introspection");

is($merged->field_db_name('my_id'),  'id',    "field_db_name maps ORM name to database name");
is($merged->field_db_name('id'),     'id',    "field_db_name is idempotent on database name");
is($merged->field_orm_name('id'),    'my_id', "field_orm_name maps database name to ORM name");
is($merged->field_orm_name('my_id'), 'my_id', "field_orm_name is idempotent on ORM name");

ok($merged->has_field('id'),    "has_field accepts the database name");
ok($merged->has_field('my_id'), "has_field accepts the ORM name");

subtest name_collisions => sub {
    like(
        dies {
            DBIx::QuickORM::Schema::Table->new(
                name    => 't',
                columns => {
                    a => $C->new(name => 'a', db_name => 'x', order => 1, affinity => 'string'),
                    b => $C->new(name => 'b', db_name => 'x', order => 2, affinity => 'string'),
                },
            );
        },
        qr/both map to database column 'x'/,
        "two columns mapping to the same database name croaks",
    );

    like(
        dies {
            DBIx::QuickORM::Schema::Table->new(
                name    => 't',
                columns => {
                    foo => $C->new(name => 'foo', db_name => 'bar', order => 1, affinity => 'string'),
                    bar => $C->new(name => 'bar', db_name => 'baz', order => 2, affinity => 'string'),
                },
            );
        },
        qr/database name 'bar', which is also the ORM name of another column/,
        "a db_name colliding with another column's ORM name croaks",
    );
};

subtest source_has_aliases => sub {
    ok($merged->source_has_aliases, "merged (aliased) table reports aliases");
    ok($user->source_has_aliases,   "user table with aliased columns reports aliases");

    my $plain = DBIx::QuickORM::Schema::Table->new(
        name        => 'plain',
        columns     => {id => $C->new(name => 'id', db_name => 'id', order => 1, affinity => 'numeric')},
        primary_key => ['id'],
    );
    ok(!$plain->source_has_aliases, "table with no aliased columns reports none");
};

subtest unique_and_index_translation => sub {
    my $unique = $merged->unique;
    is([sort keys %$unique], ['my_uuid'], "unique constraint re-keyed to ORM column_key");
    is($unique->{my_uuid}, ['my_uuid'], "unique constraint columns translated to ORM names");

    my $indexes = $merged->indexes;
    is(scalar(@$indexes), 1, "one index preserved");
    is($indexes->[0]->{columns}, ['my_uuid'], "index columns translated to ORM names");
    is($indexes->[0]->{name}, 'example_uuid_idx', "index name preserved");
};

done_testing;
