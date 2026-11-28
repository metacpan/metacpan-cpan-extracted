# Test origin: AI
use Test2::V0;

use DBIx::QuickORM::Map;

my %DATA = (
    users => {
        fields => {id => {affinity => 'numeric', db_type => 'integer', type => 'integer'}, 0 => {affinity => 'string', db_type => 'text', type => 'text'}},
        pk     => ['id'],
        unique => [['0']],
        fk     => {orgs => [{0 => 'name'}]},
    },
    logs => {fields => {msg => {affinity => 'string',  db_type => 'text', type => 'text'}}, pk => undef, unique => [], fk => {}},
    0    => {fields => {0   => {affinity => 'numeric', db_type => 'int',  type => 'int'}},  pk => ['0'], unique => [], fk => {}},
);

my $map = DBIx::QuickORM::Map->new(tables => \%DATA);

subtest lookups => sub {
    ref_is($map->tables,         \%DATA,       "The data is held as given");
    ref_is($map->table('users'), $DATA{users}, "table() returns the record");
    is($map->table('nope'), undef, "an unknown table is undef");
    ref_is($map->field(users => 'id'), $DATA{users}->{fields}->{id}, "field() returns the record");
    is($map->field(users => 'Id'), undef, "field lookups are exact");
    is($map->field(nope  => 'id'), undef, "a field of an unknown table is undef");
    ok($map->table(0) && $map->field(0 => 0) && $map->field(users => '0'), "names of 0 work");
    is($map->pk('users'), ['id'], "pk()");
    is($map->pk('logs'),  undef,  "pk() is undef for a table without one");
    is($map->pk(0),       ['0'],  "pk() of a table named 0");
    like(dies { $map->pk('nope') }, qr/^The table 'nope' is not in the database map at /, "pk() of an unknown table croaks");
};

subtest normalize_pk => sub {
    my $pairs = DBIx::QuickORM::Map->new(tables => {pairs => {pk => ['a', 'b']}, users => {pk => ['id']}, logs => {pk => undef}});
    my $obj   = bless {}, 'Some::Value';
    my $row   = mock  {} => (add => [row_data => sub { {id => 7, name => 'x'} }]);

    is($pairs->normalize_pk(users => 1),                      [1],    "A single value");
    is($pairs->normalize_pk(users => [1]),                    [1],    "An arrayref");
    is($pairs->normalize_pk(users => {id => 1, name => 'x'}), [1],    "A hashref, other fields ignored");
    is($pairs->normalize_pk(pairs => {b => 2, a => 1}),       [1, 2], "A compound hashref, in key order");
    is($pairs->normalize_pk(pairs => [1, 2]),                 [1, 2], "A compound arrayref");
    is($pairs->normalize_pk(users => $row),                   [7],    "A row object is taken as its row data");
    ref_is($pairs->normalize_pk(users => $obj)->[0],         $obj, "Any other blessed object is a value, as given");
    ref_is($pairs->normalize_pk(users => {id => $obj})->[0], $obj, "and inside a hashref");

    like(dies { $pairs->normalize_pk(logs  => 1) },        qr/^The table 'logs' has no primary key/,                                               "No primary key croaks");
    like(dies { $pairs->normalize_pk(pairs => 1) },        qr/^The table 'pairs' has a compound primary key \(a, b\); give a hashref/,             "A single value for a compound key croaks");
    like(dies { $pairs->normalize_pk(pairs => $obj) },     qr/^The table 'pairs' has a compound primary key/,                                      "so does an object");
    like(dies { $pairs->normalize_pk(pairs => [1]) },      qr/^The table 'pairs' has 2 primary key field\(s\) \(a, b\), but the arrayref holds 1/, "A short arrayref croaks");
    like(dies { $pairs->normalize_pk(users => [1, 2]) },   qr/^The table 'users' has 1 primary key field\(s\) \(id\), but the arrayref holds 2/,   "A long arrayref croaks");
    like(dies { $pairs->normalize_pk(pairs => {a => 1}) }, qr/^The primary key field 'b' of the table 'pairs' is missing or undefined/,            "A missing key field croaks");
    like(dies { $pairs->normalize_pk(users => undef) },    qr/^The primary key field 'id' of the table 'users' is missing or undefined/,           "An undef value croaks");
    like(dies { $pairs->normalize_pk(users => \1) },       qr/^Primary key must be a value, an arrayref, a hashref, or a row; got SCALAR/,         "An unblessed scalar ref croaks");
    like(
        dies {
            $pairs->normalize_pk(users => sub { 1 })
        },
        qr/^Primary key must be a value, an arrayref, a hashref, or a row; got CODE/,
        "and so does a code ref"
    );
};

subtest clone => sub {
    my $copy = $map->clone;
    isa_ok($copy, ['DBIx::QuickORM::Map'], "A clone is a map");
    is($copy->tables, \%DATA, "with the same data");

    $copy->field(users => 'id')->{orm_type} = 'X';
    push @{$copy->pk('users')}                   => 'x';
    push @{$copy->table('users')->{unique}->[0]} => 'x';
    $copy->table('users')->{fk}->{orgs}->[0]->{y} = 'z';
    delete $copy->tables->{logs};

    is($map->tables,       \%DATA, "Changing every level of the clone leaves the original alone");
    is($DATA{users}->{pk}, ['id'], "including nested arrays");

    like(
        dies { DBIx::QuickORM::Map->new(tables => {t => {fields => {f => bless({}, 'Foo')}}})->clone },
        qr/^The database map holds only strings, hashes, arrays, and code references, found a 'Foo' reference/,
        "Anything blessed croaks"
    );
    my $format = sub { uc $_[0] };
    ref_is(DBIx::QuickORM::Map->new(tables => {t => {fields => {f => {format => $format}}}})->clone->field(t => 'f')->{format}, $format, "A field's format is kept as it is");
    like(dies { DBIx::QuickORM::Map->new(tables => {t => \"x"})->clone }, qr/found a 'SCALAR' reference/, "So does any other reference");
};

like(dies { DBIx::QuickORM::Map->new },               qr/^'tables' must be a hashref/, "tables is required");
like(dies { DBIx::QuickORM::Map->new(tables => []) }, qr/^'tables' must be a hashref/, "and must be a hashref");

done_testing;
