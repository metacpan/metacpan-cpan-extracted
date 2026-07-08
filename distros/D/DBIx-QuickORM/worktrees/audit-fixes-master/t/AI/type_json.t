use Test2::V0 '!meta', '!pass';

# Coverage for DBIx::QuickORM::Type::JSON: inflate string->ref, deflate
# ref->json, undef handling, canonical comparison, blessed-ref deflation,
# affinity, and a real round-trip through a SQLite "json" column.

BEGIN {
    skip_all "Cpanel::JSON::XS is required for these tests"
        unless eval { require Cpanel::JSON::XS; 1 };
}

use DBIx::QuickORM::Type::JSON;

my $C = 'DBIx::QuickORM::Type::JSON';

subtest affinity => sub {
    is($C->qorm_affinity, 'string', "JSON affinity is string");
};

subtest inflate => sub {
    my $ref = $C->qorm_inflate(class => $C, value => '{"a":1,"b":[2,3]}');
    is($ref, {a => 1, b => [2, 3]}, "decoded JSON object string into a Perl structure");

    is(
        $C->qorm_inflate(class => $C, value => '[1,2,3]'),
        [1, 2, 3],
        "decoded JSON array string",
    );

    is($C->qorm_inflate(class => $C, value => '"hello"'), 'hello', "decoded JSON string scalar");
    is($C->qorm_inflate(class => $C, value => '42'),      42,      "decoded JSON numeric scalar");

    is($C->qorm_inflate(class => $C, value => undef), undef, "undef inflates to undef");

    # An already-inflated ref passes straight through (the row layer can
    # re-run inflate on a value that is already a ref).
    my $already = {x => 1};
    is($C->qorm_inflate(class => $C, value => $already), $already, "ref value passes through unchanged");
};

subtest deflate => sub {
    is(
        $C->qorm_deflate(class => $C, value => {x => 1}, affinity => 'string'),
        '{"x":1}',
        "encoded a hashref to a JSON string",
    );

    is(
        $C->qorm_deflate(class => $C, value => [1, 2], affinity => 'string'),
        '[1,2]',
        "encoded an arrayref to a JSON string",
    );

    is($C->qorm_deflate(class => $C, value => undef, affinity => 'string'), undef, "undef deflates to undef");

    is(
        $C->qorm_deflate(class => $C, value => 'hello', affinity => 'string'),
        '"hello"',
        "encoded a string scalar to a JSON string",
    );

    is(
        $C->qorm_inflate(class => $C, value => $C->qorm_deflate(class => $C, value => 42, affinity => 'string')),
        42,
        "numeric scalar round-trips through deflate and inflate",
    );

    ok(
        lives { $C->qorm_deflate(class => $C, value => {x => 1}) },
        "deflate does not require an affinity (it never uses one)",
    );
};

subtest blessed_ref_deflation => sub {
    my $hash_obj  = bless {z => 9},   'Some::Blessed::Hash';
    my $array_obj = bless [4, 5, 6],  'Some::Blessed::Array';

    is(
        $C->qorm_deflate(class => $C, value => $hash_obj, affinity => 'string'),
        '{"z":9}',
        "blessed hashref deflates to a plain JSON object",
    );

    is(
        $C->qorm_deflate(class => $C, value => $array_obj, affinity => 'string'),
        '[4,5,6]',
        "blessed arrayref deflates to a plain JSON array",
    );

    {
        package Some::JSON::Object;
        sub TO_JSON { return {from_to_json => $_[0]->{value}} }
    }

    my $to_json = bless {value => 42}, 'Some::JSON::Object';
    is(
        $C->qorm_deflate(class => $C, value => $to_json, affinity => 'string'),
        '{"from_to_json":42}',
        "blessed objects with TO_JSON delegate to the JSON encoder",
    );
};

subtest canonical_compare => sub {
    # qorm_compare follows the equality contract: true when the values are the
    # same, false when they differ.
    ok(
        $C->qorm_compare('{"a":1,"b":2}', '{"b":2,"a":1}'),
        "structurally equal but differently-ordered objects compare equal",
    );

    ok(
        !$C->qorm_compare('{"a":1}', '{"a":2}'),
        "different values compare unequal",
    );

    # Compare a raw JSON string against an already-inflated ref.
    ok(
        $C->qorm_compare('{"a":1,"b":2}', {b => 2, a => 1}),
        "compare normalizes a raw string against an inflated ref",
    );

    my $nested_a = {list => [{k => 1}, {k => 2}], n => 3};
    my $nested_b = {n => 3, list => [{k => 1}, {k => 2}]};
    ok($C->qorm_compare($nested_a, $nested_b), "nested structures compare canonically");
};

subtest round_trip_through_sqlite => sub {
    skip_all "DBD::SQLite is required for the integration test"
        unless eval { require DBD::SQLite; 1 };

    require DBI;
    require File::Temp;
    require DBIx::QuickORM;

    my $dir  = File::Temp::tempdir(CLEANUP => 1);
    my $file = "$dir/json.sqlite";
    my $dsn  = "dbi:SQLite:dbname=$file";

    {
        my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
        $dbh->do('CREATE TABLE docs (doc_id INTEGER PRIMARY KEY, label TEXT, payload_json TEXT)');
        $dbh->do('INSERT INTO docs (label, payload_json) VALUES (?, ?)', undef, 'seed', '{"age":42,"tags":["x","y"]}');
        $dbh->disconnect;
    }

    my $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn}, auto_types => ['JSON']);

    my ($seed) = $con->handle('docs')->all;
    is(
        $seed->field('payload_json'),
        {age => 42, tags => ['x', 'y']},
        "auto-typed *json* column inflated the seeded row to a structure",
    );

    my $struct = {nums => [3, 2, 1], nested => {a => 1}};
    my $new = $con->handle('docs')->insert({label => 'fresh', payload_json => $struct});
    is($new->field('payload_json'), $struct, "JSON round-tripped on insert");

    # Re-fetch from a fresh connection so we read what was actually stored.
    my $con2 = DBIx::QuickORM->quick(credentials => {dsn => $dsn}, auto_types => ['JSON']);
    my ($fetched) = $con2->handle('docs')->where({label => 'fresh'})->all;
    is($fetched->field('payload_json'), $struct, "stored JSON read back from a new connection");

    # The raw stored value is a JSON string, not Perl-serialized.
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    my ($raw) = $dbh->selectrow_array('SELECT payload_json FROM docs WHERE label = ?', undef, 'fresh');
    $dbh->disconnect;
    like($raw, qr/^\{.*\}$/, "stored value is a JSON document string");
    is(Cpanel::JSON::XS::decode_json($raw), $struct, "raw stored JSON decodes back to the struct");
};

subtest deflate_without_affinity => sub {
    # JSON deflate does not use the affinity, so it must not croak when one
    # cannot be determined (e.g. a bare qorm_deflate(value => ...) call).
    my $out;
    ok(lives { $out = DBIx::QuickORM::Type::JSON->qorm_deflate(value => {a => 1}) }, "qorm_deflate works without an affinity") or note $@;
    is($out, '{"a":1}', "and still produces the JSON");
};

done_testing;
