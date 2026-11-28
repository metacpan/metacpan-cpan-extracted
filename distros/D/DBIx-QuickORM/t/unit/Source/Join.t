# Test origin: AI
use Test2::V0;

use DBI;
use DBIx::QuickORM;
use DBIx::QuickORM::Source::Join;

my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1});
$dbh->do($_)
    for (
    "CREATE TABLE people (id INTEGER PRIMARY KEY, name TEXT, boss_id INTEGER)",
    "CREATE TABLE pets (owner_id INTEGER, name TEXT)",
    );
my $orm = DBIx::QuickORM->new(dbh => $dbh, row_classes => {pets => undef}, omit => {people => ['boss_id']});
my $map = $orm->db_map;

my $join = DBIx::QuickORM::Source::Join->new(db_map => $map, components => [{as => 'p', table => 'people'}]);
my $two  = $join->extend(left => 'people', as => 'boss', from => 'p', link => {boss_id => 'id'});
my $all  = $two->extend(left => 'pets', link => {id => 'owner_id'});

subtest source => sub {
    ok($join->DOES('DBIx::QuickORM::Role::Source'), "A join is a source");
    is([$join->table, $join->pk, $join->query_sql], [undef, undef], "with no table, primary key, or query");
    is([map { $_->{as} } @{$two->{components}}],    ['p', 'boss'],  "extend returns a new join with one more component");
    is(scalar(@{$join->{components}}),              1,              "leaving the original alone");
    is($all->component_table('boss'),               'people',       "component_table");
    is($all->component_table(undef),                'people',       "undef is the base");

    is(
        [$all->from_sql('DBIx::QuickORM::Dialect')],
        ['"people" AS "p" LEFT JOIN "people" AS "boss" ON "p"."boss_id" = "boss"."id" LEFT JOIN "pets" AS "pets" ON "p"."id" = "pets"."owner_id"', []],
        "from_sql joins each component on its link, under its name",
    );

    my $records = $two->field_records;
    ref_is($records->{'boss.name'}, $map->table('people')->{fields}->{name}, "field_records by component.field");
    ref_is($records->{qorm_1_2},    $records->{'boss.name'},                 "and by label");
};

subtest select_fields => sub {
    is($two->select_fields,                     {qorm_0_1 => 'p.id', qorm_0_2 => 'p.name', qorm_1_1 => 'boss.id', qorm_1_2 => 'boss.name'}, "Each component's default fields and primary key, labeled");
    is($two->select_fields(['boss.boss_id']),   {qorm_1_0 => 'boss.boss_id', qorm_0_1 => 'p.id', qorm_1_1 => 'boss.id'},                    "A subset, with every primary key");
    is($all->select_fields(['pets.name']),      {qorm_2_0 => 'pets.name', qorm_0_1 => 'p.id', qorm_1_1 => 'boss.id'},                       "a component without a primary key adds none");
    is($two->select_fields({n => 'boss.name'}), {n => 'boss.name'},                                                                         "Computed fields as they are");

    like(dies { $two->select_fields(['name']) },      qr/^A join names fields as component\.field; 'name' is not a field of a component/, "A plain name croaks");
    like(dies { $two->select_fields({n => 'name'}) }, qr/'name' is not a field of a component/,                                           "in computed fields too");
    like(dies { $two->select_fields(['x.name']) },    qr/'x\.name' is not a field of a component/,                                        "and so does an unknown component");
};

subtest croaks => sub {
    like(dies { $two->extend(inner => 'people', as => 'boss', link => {id => 'boss_id'}) }, qr/^The join already has a component named 'boss'/, "A taken name croaks");
    like(dies { $two->extend(inner => 'people', as => 'x', from => 'y', link => {}) },      qr/^The join has no component named 'y'/,           "An unknown from croaks");
    like(dies { $two->extend(inner => 'people', as => 'x', from => 'x', link => {}) },      qr/^The join has no component named 'x'/,           "A from naming the component itself croaks");
    like(dies { $two->extend(right => 'people') },                                          qr/^A join is 'inner' or 'left'/,                   "Only inner and left joins");
    like(dies { $two->component_table('nope') },                                            qr/^The join has no component named 'nope'/,        "component_table croaks for an unknown name");
    like(dies { $two->results($orm, [], 1, 'DBIx::QuickORM::Row') },                        qr/^A join handle's row_class can only be undef/,   "results croaks for a row class");
};

subtest results => sub {
    my $raw = [
        {qorm_0_1 => 1, qorm_0_2 => 'al', qorm_1_1 => undef, qorm_1_2 => undef, qorm_2_0 => 'rex', qorm_2_1 => 1},
        {qorm_0_1 => 1, qorm_0_2 => 'al', qorm_1_1 => undef, qorm_1_2 => undef, qorm_2_0 => 'tom', qorm_2_1 => 1},
    ];
    my ($rows, $build) = $all->results($orm, $raw, 1);
    my ($one,  $two)   = map { $build->($_) } @$rows;
    isa_ok($one, ['DBIx::QuickORM::JoinRow'], "Rows build into join rows");
    is([$one->aliases], ['p', 'boss', 'pets'], "with every component");
    isa_ok($one->row('p'), ['DBIx::QuickORM::Row'], "built with its table's row class");
    ok($orm->is_canon(people => $one->row('p')), "and ingested");
    ref_is($two->row('p'), $one->row('p'), "The same canon row gives the same row object within one result");
    is($one->row('boss'),         undef,                          "A left join that matched nothing is undef");
    is($one->row('pets'),         {name => 'rex', owner_id => 1}, "A component without a primary key is built from its fields");
    is($one->data->{'pets.name'}, 'rex',                          "data is keyed component.field");

    my ($raw_rows, $raw_build) = $all->results($orm, $raw, 1, undef);
    is($raw_build->($raw_rows->[0]), $one->data, "row_class undef builds each row's data");

    $orm->clear_cache;
    my ($kept, $kept_build) = $all->results($orm, $raw, 0);
    my $p = $kept_build->($kept->[0])->row('p');
    is($p->field('name'), 'al', "Without ingest the components are still built");
    ok(!$orm->is_canon(people => $p), "but never enter the lookup table");
};

done_testing;
