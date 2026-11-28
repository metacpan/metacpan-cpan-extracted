# Test origin: AI
use Test2::V0;

use DBI;
use DBIx::QuickORM;
use DBIx::QuickORM::Type::JSON;

my $T      = 'DBIx::QuickORM::Type::JSON';
my %STRING = (affinity => 'string');

subtest claims => sub {
    is([$T->base_types], ['json', 'jsonb'], "Base types");
    ok($T->matches($_,  \%STRING), "'$_' matches by name") for qw/json data_json json_data a_json_b JSON_x/;
    ok(!$T->matches($_, \%STRING), "'$_' does not")        for qw/jsonish xjson data/;
    ok(!$T->matches(data_json => {affinity => 'numeric'}), "A field that is not a string does not match");
    is(warnings { ok(!$T->matches(data_json => {}), "nor does a record with no affinity") }, [], "which gives no warnings");
};

subtest convert => sub {
    my $data = {b => [1, "caf\x{e9}"], a => undef};
    my $text = $T->deflate($data, \%STRING);
    is($text,                        qq/{"a":null,"b":[1,"caf\x{e9}"]}/, "A reference deflates to canonical JSON text, as characters");
    is($T->inflate($text, \%STRING), $data,                              "which inflates back");

    my $bytes = $text;
    utf8::encode($bytes);
    is($T->inflate($bytes, \%STRING), $data, "Text returned as UTF-8 bytes inflates too");

    is($T->deflate('{"x":1}', \%STRING), '{"x":1}', "A plain value is taken as encoded and sent as given");
    is($T->inflate('"hi"', \%STRING),    'hi',      "Any JSON value inflates, including a top-level string");
    is($T->is_inflated('{"x":1}'),       undef,     "A plain value may be JSON text or not, so is_inflated cannot tell");
    is($T->is_inflated('hi'),            undef,     "even one that is not JSON text");
    is($T->is_inflated({x => 1}),        1,         "A reference is inflated");
    is($T->is_inflated([1]),             1,         "an array too");

    ok(!$T->inflated_is_immutable_for_cache, "Inflated data can change, so rows hand out copies");
    my $copy = $T->clone_inflated($data);
    is($copy, $data, "clone_inflated copies inflated data");
    ok($copy != $data && $copy->{b} != $data->{b}, "deeply");
    my $bools = $T->inflate('{"t":true,"f":false}', \%STRING);
    is($T->deflate($T->clone_inflated($bools), \%STRING), '{"f":false,"t":true}', "Copied booleans still deflate as booleans");
};

subtest through_the_orm => sub {
    my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1});
    $dbh->do("CREATE TABLE docs (id INTEGER PRIMARY KEY, data JSON, extra_json TEXT, note TEXT)");
    my $orm = DBIx::QuickORM->new(dbh => $dbh, row_class => undef);

    is($orm->db_map->field(docs  => $_)->{orm_type}, $T, "'$_' is autotyped") for qw/data extra_json/;
    ok(!$orm->db_map->field(docs => 'note')->{orm_type}, "'note' is not");

    $orm->insert(docs => {id => 1, data => {k => [1, 2]}, extra_json => '[3]'});
    is([$dbh->selectrow_array('SELECT data, extra_json FROM docs')], ['{"k":[1,2]}', '[3]'], "The ORM deflates references and sends plain values as given");
};

done_testing;
