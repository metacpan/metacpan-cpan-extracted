use Test2::V0 '!meta', '!pass';
use DBIx::QuickORM::Schema;
use DBIx::QuickORM::Schema::Table;
use DBIx::QuickORM::Schema::Table::Column;
use DBIx::QuickORM::Link;
use DBIx::QuickORM::Join;
use DBIx::QuickORM::SQLBuilder::SQLAbstract;

# Joins translate aliased column names across component tables: ORM names in
# (qualified alias.field or bare field), database names out in the generated
# SQL, and database names back to ORM names for fetched rows.

my $C = 'DBIx::QuickORM::Schema::Table::Column';

my $foo = DBIx::QuickORM::Schema::Table->new(
    name    => 'foo',
    columns => {
        foo_pid  => $C->new(name => 'foo_pid',  db_name => 'foo_id', order => 1, affinity => 'numeric'),
        foo_name => $C->new(name => 'foo_name', db_name => 'name',   order => 2, affinity => 'string'),
    },
    primary_key => ['foo_pid'],
);

my $bar = DBIx::QuickORM::Schema::Table->new(
    name    => 'bar',
    columns => {
        bar_pid => $C->new(name => 'bar_pid', db_name => 'bar_id', order => 1, affinity => 'numeric'),
        bar_foo => $C->new(name => 'bar_foo', db_name => 'foo_id', order => 2, affinity => 'numeric'),
    },
    primary_key => ['bar_pid'],
);

my $schema = DBIx::QuickORM::Schema->new(name => 's', tables => {foo => $foo, bar => $bar});

my $link = DBIx::QuickORM::Link->new(
    local_table   => 'foo',
    other_table   => 'bar',
    local_columns => ['foo_id'],
    other_columns => ['foo_id'],
    unique        => 0,
);

my $join = DBIx::QuickORM::Join->new(schema => $schema, primary_source => $foo)->left_join($link);

subtest fields_to_fetch => sub {
    my $fields = join(', ' => map { $$_ } @{$join->fields_to_fetch});
    like($fields, qr/\ba\.foo_id AS "a\.foo_id"/, "foo PK fetched by database name under its alias");
    like($fields, qr/\ba\.name AS "a\.name"/,     "foo name fetched by database name under its alias");
    like($fields, qr/\bb\.bar_id\b/,              "bar PK fetched by database name under its alias");
    unlike($fields, qr/foo_pid|foo_name|bar_pid|bar_foo/, "no ORM names appear in the fetch list");
};

subtest field_db_name => sub {
    is($join->field_db_name('a.foo_pid'),  'a.foo_id', "qualified ORM name -> qualified database name (foo)");
    is($join->field_db_name('a.foo_name'), 'a.name',   "qualified ORM name -> qualified database name (foo, aliased)");
    is($join->field_db_name('b.bar_pid'),  'b.bar_id', "qualified ORM name -> qualified database name (bar)");
    is($join->field_db_name('b.bar_foo'),  'b.foo_id', "qualified disambiguation picks the named component");
    is($join->field_db_name('a.foo_id'),   'a.foo_id', "idempotent on a qualified database name");
};

subtest field_orm_name => sub {
    is($join->field_orm_name('a.foo_id'), 'a.foo_pid',  "qualified database name -> qualified ORM name (foo)");
    is($join->field_orm_name('a.name'),   'a.foo_name', "qualified database name -> qualified ORM name (foo, aliased)");
    is($join->field_orm_name('b.bar_id'), 'b.bar_pid',  "qualified database name -> qualified ORM name (bar)");
};

subtest source_has_aliases => sub {
    ok($join->source_has_aliases, "join over aliased component tables reports aliases");
};

subtest has_field => sub {
    ok($join->has_field('a.foo_pid'), "has_field accepts a qualified ORM name");
    ok($join->has_field('b.bar_foo'), "has_field accepts a qualified ORM name on the joined table");
    ok(!$join->has_field('-or'),      "has_field is false for a logic operator (where-walker guard)");
    ok(!$join->has_field('a.nope'),   "has_field is false for an unknown field");
};

subtest builder_select => sub {
    my $b = DBIx::QuickORM::SQLBuilder::SQLAbstract->new;
    my $sql = $b->qorm_select(
        source   => $join,
        fields   => ['a.foo_pid', 'a.foo_name', 'b.bar_pid'],
        where    => {-or => [{'a.foo_name' => 'x'}, {'b.bar_foo' => 5}]},
        order_by => {-desc => 'a.foo_name'},
    );

    my $stmt = $sql->{statement};
    like($stmt, qr/a\.name/,    "field list / where reference foo's database name");
    like($stmt, qr/b\.foo_id/,  "where on the joined table uses its database name");
    like($stmt, qr/a\.name DESC/i, "order_by uses the database name");
    unlike($stmt, qr/foo_pid|foo_name|bar_pid|bar_foo/, "no ORM names leak into the join SQL");
};

done_testing;
