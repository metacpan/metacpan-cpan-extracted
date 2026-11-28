# Test origin: AI
use Test2::V0;
use lib 't/lib';

use DBI;
use DBIx::QuickORM;
use DBIx::QuickORM::AggregateRow;

my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1});
$dbh->do("CREATE TABLE c (id INTEGER PRIMARY KEY, code TEXT UNIQUE)");
$dbh->do("INSERT INTO c (id, code) VALUES (1, 'a'), (2, 'b')");
my $orm = DBIx::QuickORM->new(dbh => $dbh);

my $JSON = 'DBIx::QuickORM::Type::JSON';
my $DT   = 'DBIx::QuickORM::Type::DateTime';
require DBIx::QuickORM::Type::JSON;
require DBIx::QuickORM::Type::DateTime;

sub agg_row {
    my ($data, %columns) = @_;
    return DBIx::QuickORM::AggregateRow->new(orm => $orm, source => $orm->handle('c')->source, columns => \%columns, row_data => $data);
}

subtest construction => sub {
    like(dies { DBIx::QuickORM::AggregateRow->new(columns => {},   row_data => {}) }, qr/^An 'orm' is required/,         "orm is required");
    like(dies { DBIx::QuickORM::AggregateRow->new(orm     => $orm, row_data => {}) }, qr/^'columns' must be a hashref/,  "columns must be a hashref");
    like(dies { DBIx::QuickORM::AggregateRow->new(orm     => $orm, columns  => {}) }, qr/^'row_data' must be a hashref/, "row_data must be a hashref");

    my $row = agg_row({n => 1}, n => {});
    ok($row->DOES('DBIx::QuickORM::Role::Row'), "An aggregate row does the row role");
    is($row->table, undef, "It has no table");
    is($row->pk,    undef, "and no primary key");
    like(dies { $row->set_row_data({}) }, qr/^An aggregate row's data cannot be replaced/, "Its data cannot be replaced");
};

subtest fields => sub {
    my $row = agg_row({doc => '{"a":1}', n => 3, nothing => undef}, doc => {orm_type => $JSON, affinity => 'string'}, n => {}, nothing => {orm_type => $JSON});

    is($row->raw_field('doc'),           '{"a":1}',      "raw_field gives the fetched value");
    is($row->field('doc'),               {a => 1},       "field inflates through the column's type");
    is([$row->fields(qw/doc n/)],        [{a => 1}, 3],  "fields too; an untyped column reads as fetched");
    is($row->field('nothing'),           undef,          "NULL stays undef");
    is([$row->raw_fields(['n', 'doc'])], [3, '{"a":1}'], "raw_fields takes an arrayref");

    $row->field('doc')->{a} = 99;
    is($row->field('doc'), {a => 1}, "A JSON value is handed out as a copy");

    my $day = agg_row({d => '2026-01-05'}, d => {orm_type => $DT, type => 'date', db_type => 'date', affinity => 'string'});
    isa_ok($day->field('d'), ['DBIx::QuickORM::Type::DateTime::Lazy'], "A DateTime column inflates");
    ref_is($day->field('d'), $day->field('d'), "and an immutable type's cached value is handed out itself");

    like(dies { $row->field('bogus') },     qr/^The aggregate row has no column 'bogus'/, "An unknown column croaks");
    like(dies { $row->raw_field('bogus') }, qr/^The aggregate row has no column 'bogus'/, "in the raw form too");
};

subtest follow_fk => sub {
    my $row = agg_row({cid => 1, other => 2, code => 'b', none => undef}, cid => {fk => {c => [{cid => 'id'}]}}, other => {fk => {c => [{other => 'id'}]}}, code => {fk => {c => [{code => 'code'}]}}, none => {fk => {gone => [{none => 'id'}]}});

    like(dies { $row->follow_fk('c') }, qr/^More than one column of the aggregate row has a foreign key to 'c'; choose one with 'link'/, "Several columns with a key to the table croak");
    my $h = $row->follow_fk('c', link => {cid => 'id'});
    isa_ok($h, ['DBIx::QuickORM::Handle'], "follow_fk returns a handle");
    is($h->where,                                                        {'c.id' => 1}, "whose where holds the column's value, qualified");
    is($h->state,                                                        'single',      "single for a primary key target");
    is($h->only->field('code'),                                          'a',           "finding the row");
    is($row->follow_fk('c', link => {code => 'code'})->state,            'single',      "single for a unique key target too");
    is($row->follow_fk('c', link => {other => 'id'})->only->field('id'), 2,             "link picks the column");

    my $multi = agg_row({n => 1}, n => {fk => {c => [{n => 'id'}]}});
    is($multi->follow_fk('c')->only->field('id'), 1, "Without link the only column with a key is used");

    my $null = agg_row({n => undef}, n => {fk => {c => [{n => 'id'}]}})->follow_fk('c');
    is($null->state, 'single', "A NULL value keeps the state");
    is([$null->all], [],       "and matches nothing");

    my $plain = agg_row({total => 2}, total => {});
    is($plain->follow_fk('c', via => {total => 'id'})->only->field('code'), 'b', "via follows a column with no key");
    like(dies { $plain->follow_fk('c',    via => {totl  => 'id'}) },  qr/^'via' names 'totl', which is not a column of the aggregate row/, "via checks the column");
    like(dies { $plain->follow_fk('nope', via => {total => 'id'}) },  qr/^The table 'nope' is not in the database map/,                    "and the table");
    like(dies { $plain->follow_fk('c',    via => {total => 'idd'}) }, qr/^'via' names 'idd', which is not a field of 'c'/,                 "and the target field");
    like(dies { $plain->follow_fk('c',    via => {total => 'id', x => 'id'}) }, qr/^'via' must be one \{column => target_field\}/, "one pair");
    like(dies { $row->follow_fk('c', link => {cid => 'id'}, via => {cid => 'id'}) }, qr/^Give 'link' or 'via', not both/, "not with link");

    like(dies { $row->follow_fk('c', link => {cid => 'code'}) },              qr/^The link \(cid => code\) matches no foreign key from a column to 'c'/, "A link matching no key croaks");
    like(dies { $row->follow_fk('c', link => {cid => 'id', other => 'id'}) }, qr/^'link' must be one \{column => target_field\}/,                        "link names one column");
    like(dies { $row->follow_fk('nope') },                                    qr/^No column of the aggregate row has a foreign key to 'nope'/,           "No key to the table croaks");
    like(dies { $row->follow_fk('gone') },                                    qr/^The table 'gone' is not in the database map/,                          "A key to a table outside the map croaks");
    like(dies { $row->follow_fk('c', bogus => 1) },                           qr/^Unknown argument\(s\) to follow_fk\(\): bogus/,                        "Unknown arguments croak");
    like(dies { $row->follow_fk(undef) },                                     qr/^follow_fk\(\) needs the table to follow to/,                           "The table is required");
};

subtest no_pk => sub {
    my $row = agg_row({n => 1}, n => {});
    like(dies { $row->update({n => 2}) }, qr/^Cannot update a row without a primary key/, "update croaks");
    like(dies { $row->$_ },               qr/^Cannot $_ a row without a primary key/,     "$_ croaks") for qw/delete refresh is_canon/;
};

done_testing;
