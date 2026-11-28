# Test origin: AI
use Test2::V0;
use lib 't/lib';

use DBI;
use DBIx::QuickORM;

package My::Row {
    use Object::HashBase qw{<orm <table row_data};
    use Role::Tiny::With qw/with/;
    with 'DBIx::QuickORM::Role::Row';
}

my $BOX = '+DBIx::QuickORM::Test::Type::Box';

package DBIx::QuickORM::Test::Type::Box {
    our $INFLATED  = 0;
    our $IMMUTABLE = 1;
    sub inflate                         { $INFLATED++; [split m/,/, $_[1]] }
    sub inflated_is_immutable_for_cache { $IMMUTABLE }
    sub clone_inflated                  { [@{$_[1]}] }
}

# Override points: field gives the raw form, and no cached value survives new row data.
package My::RawRow {
    use Object::HashBase qw{<orm <table row_data};
    use Role::Tiny::With qw/with/;
    with 'DBIx::QuickORM::Role::Row';

    sub field { my $self = shift; $self->raw_field(@_) }

    sub _inflation_cache {
        my $self = shift;
        my $data = $self->row_data;
        $self->{my_cache} = {data => $data, values => {}} unless $self->{my_cache} && $self->{my_cache}->{data} == $data;
        return $self->{my_cache}->{values};
    }
}

# Override point: hands out every typed value tagged.
package My::TagRow {
    use Object::HashBase qw{<orm <table row_data};
    use Role::Tiny::With qw/with/;
    with 'DBIx::QuickORM::Role::Row';

    sub _inflated_value { my $self = shift; my $v = $self->DBIx::QuickORM::Role::Row::_inflated_value(@_); ref($v) ? [@$v, 'tagged'] : $v }
}

sub orm {
    my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1});
    $dbh->do("CREATE TABLE t (id INTEGER PRIMARY KEY, tags TEXT, v TEXT, doc JSON)");
    $dbh->do("CREATE TABLE pairs (a INTEGER, b INTEGER, v TEXT, PRIMARY KEY (a, b))");
    return DBIx::QuickORM->new(dbh => $dbh, row_class => 'My::Row', types => {t => {tags => $BOX}}, @_);
}

subtest requires => sub {
    like(
        dies { Role::Tiny->apply_roles_to_package('My::Half', 'DBIx::QuickORM::Role::Row') },
        qr/missing orm, table, row_data, set_row_data/,
        "orm, table, row_data, and set_row_data are required",
    );
};

subtest accessors => sub {
    my $orm = orm();
    my $row = $orm->insert(t => {id => 1, tags => ['a', 'b'], v => 'x', doc => 'null'});

    is($row->raw_field('tags'),      'a,b',      "raw_field gives the raw value of a typed field");
    is($row->inflated_field('tags'), ['a', 'b'], "inflated_field inflates it");
    is($row->field('tags'),          ['a', 'b'], "field gives the inflated form");
    is($row->raw_field('v'),         'x',        "An untyped field's raw value");
    is($row->inflated_field('v'),    'x',        "is its inflated form too");
    is($row->raw_field('doc'),       'null',     "A JSON null reads raw as its text");
    is($row->inflated_field('doc'),  undef,      "and inflated as undef, with no fallback to the raw value");

    is([$row->raw_fields(qw/tags v/)],         ['a,b', 'x'], "raw_fields reads several");
    is([$row->raw_fields(['tags', 'v'])],      ['a,b', 'x'], "given as an arrayref too");
    is([$row->inflated_fields(qw/tags v/)],    [['a', 'b'], 'x'], "inflated_fields reads several");
    is([$row->inflated_fields(['tags', 'v'])], [['a', 'b'], 'x'], "given as an arrayref too");
    is([$row->fields(qw/tags v/)],             [['a', 'b'], 'x'], "fields gives the inflated form");

    like(dies { $row->raw_field('nope') },      qr/^The table 't' has no field 'nope'/, "raw_field croaks for an unknown field");
    like(dies { $row->inflated_field('nope') }, qr/^The table 't' has no field 'nope'/, "so does inflated_field");

    my $fetches = 0;
    my $mock    = mock 'DBIx::QuickORM::Connection' => (around => [refresh_row => sub { my $orig = shift; $fetches++; $orig->(@_) }]);
    my $hmock   = mock 'DBIx::QuickORM::Handle'     => (around => [first       => sub { my $orig = shift; $fetches++; $orig->(@_) }]);    # a row that is not canon
    for my $method (qw/raw_fields inflated_fields/) {
        $fetches = 0;
        my $half = My::Row->new(orm => $orm, table => 't', row_data => {id => 1});
        my @got  = $half->$method(qw/tags v doc/);
        is($got[1],  'x', "$method fetches missing fields");
        is($fetches, 1,   "$method fetches all of them with one query");
    }

    my $loose = My::Row->new(orm => $orm, table => undef, row_data => {a => 'raw', b => [1]});
    is([$loose->raw_fields(qw/a b/)],      ['raw', [1]], "A row with no table reads raw");
    is([$loose->inflated_fields(qw/a b/)], ['raw', [1]], "in both forms");
    is($loose->field('nope'),              undef, "with no field check");
};

subtest inflation_cache => sub {
    my $orm = orm();
    my $row = $orm->insert(t => {id => 1, tags => ['a', 'b']});
    isa_ok($row, ['My::Row'], "Any class consuming the role works as a row class");

    local $DBIx::QuickORM::Test::Type::Box::INFLATED = 0;
    my $tags = $row->field('tags');
    is($tags, ['a', 'b'], "field inflates through the type");
    ref_is($row->field('tags'), $tags, "and hands out the cached value when the type says it is immutable");
    is($DBIx::QuickORM::Test::Type::Box::INFLATED, 1,     "inflating once");
    is($row->field('v'),                           undef, "NULL reads as undef");

    {
        local $DBIx::QuickORM::Test::Type::Box::IMMUTABLE = 0;
        my $copy = $row->field('tags');
        is($copy, ['a', 'b'], "A type that is not immutable hands out a copy");
        ok($copy != $tags, "not the cached value");
        push @$copy => 'c';
        is($row->field('tags'),                        ['a', 'b'], "so changing it does not change the next read");
        is($DBIx::QuickORM::Test::Type::Box::INFLATED, 1,          "which still comes from the cache");
    }

    my $data = $row->row_data;
    $row->set_row_data({%$data, v => 'new'});
    ref_is($row->field('tags'), $tags, "New row data keeps the cached value of a field whose raw value did not change");
    is($DBIx::QuickORM::Test::Type::Box::INFLATED, 1, "without inflating again");

    $row->set_row_data({%{$row->row_data}, tags => 'a,b,c'});
    my $new = $row->field('tags');
    is($new, ['a', 'b', 'c'], "A changed raw value is inflated again");
    ok($new != $tags, "into a new value, however the row data was set");

    $row->set_row_data({%{$row->row_data}, tags => undef});
    is($row->field('tags'), undef, "A value that became NULL reads as undef");
    ok(!exists $row->_inflation_cache->{tags}, "and is dropped from the cache");

    $row->set_row_data({id => 1, v => 'new'});
    ok(!exists $row->_inflation_cache->{tags}, "A field the new row data lacks is dropped from the cache");

    $row->set_row_data({id => 1, tags => 'q'});
    my $other = My::Row->new(orm => $orm, table => 't', row_data => $row->row_data);
    ok($other->field('tags') != $row->field('tags'), "Each row object has its own cache");
};

subtest override_points => sub {
    my $orm = orm(row_class => 'My::RawRow');
    my $row = $orm->insert(t => {id => 1, tags => ['a', 'b'], v => 'x'});
    is($row->field('tags'),          'a,b',      "A class overriding field changes the default form");
    is($row->inflated_field('tags'), ['a', 'b'], "and inflated_field still inflates");

    local $DBIx::QuickORM::Test::Type::Box::INFLATED = 0;
    $row->set_row_data({%{$row->row_data}, v => 'y'});
    $row->inflated_field('tags');
    is($DBIx::QuickORM::Test::Type::Box::INFLATED, 1, "A class overriding _inflation_cache sets the carry-over policy (here: none)");

    my $tag = My::TagRow->new(orm => $orm, table => 't', row_data => $row->row_data);
    is($tag->field('tags'), ['a', 'b', 'tagged'], "A class overriding _inflated_value sets what a read hands out");
    is($tag->field('v'),    'y',                  "for every field it reads");
};

subtest pk => sub {
    my $orm  = orm();
    my $pair = $orm->insert(pairs => {a => 1, b => 2, v => 'x'});
    is($pair->pk, {a => 1, b => 2}, "pk holds every primary key field");

    my $half = My::Row->new(orm => $orm, table => 'pairs', row_data => {a => 1});
    is($half->pk, {a => 1, b => undef}, "with undef for one the row data lacks");
    like(dies { $half->refresh }, qr/^Cannot refresh a row without a primary key \(table 'pairs'\)/, "which is not usable");
};

subtest primitives => sub {
    my $orm = orm();
    my $row = $orm->insert(t => {id => 1, tags => ['a']});

    my @calls;
    my $record = sub { my $orig = shift; my (undef, undef, $arg, @rest) = @_; push @calls => [$arg, @rest]; $orig->(@_) };
    my $mock   = mock 'DBIx::QuickORM' => (around => [update_row => $record, refresh_row => $record]);

    ref_is($row->update({tags => ['b', 'c'], v => 'box:z'}), $row, "update returns the row");
    my ($arg, $changes, %opts) = @{$calls[0]};
    ref_is($arg, $row, "after passing itself to the ORM's update_row");
    is($opts{raw},          1,                             "with raw => 1");
    is($changes,            {tags => 'b,c', v => 'box:z'}, "and the changes deflated by the primitives' rules");
    is($row->field('tags'), ['b', 'c'],                    "and takes the new row data");

    $row->update({v => 'box:y'});
    is($row->raw_field('v'), 'box:y', "In void context it takes the new row data too");

    ok($row->is_canon, "is_canon asks the Connection");
    ref_is($row->refresh,   $row, "refresh returns the row");
    ref_is($calls[-1]->[0], $row, "after passing itself to the ORM's refresh_row");

    like(dies { $row->update('x') },                       qr/^update\(\) needs a hashref of changes/,                                        "Changes must be a hashref");
    like(dies { $row->update({v => 'box:x'}, data => 1) }, qr/^update\(\) always returns the row; use the ORM's update_row\(\) for row data/, "update takes no data option");
    like(dies { $row->refresh(data => 1) },                qr/^refresh\(\) takes no arguments/,                                               "refresh takes no arguments");
    like(dies { $row->update({v => [1]}) },                qr/^The field .v. of .t. has no type to deflate a reference with/,                 "A reference on a field without a type croaks");
    like(dies { $row->update({nope => [1]}) },             qr/^The table 't' has no field 'nope'/,                                            "An unknown field is reported before anything is deflated");

    is($row->delete, 1, "delete calls the Connection's delete_row");
    ok($row->was_deleted && !$row->is_in_db, "and the row is marked deleted");
    like(dies { $row->update({v => 'box:x'}) }, qr/^Cannot update a row that is not in the database; insert it first/, "so it can no longer be updated");
};

done_testing;
