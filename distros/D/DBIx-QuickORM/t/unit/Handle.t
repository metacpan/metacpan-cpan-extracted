# Test origin: AI
use Test2::V0;
use lib 't/lib';

use DBI;
use DBIx::QuickORM;
use DBIx::QuickORM::Value qw/raw sql/;

my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1});
$dbh->do("CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT, note TEXT)");
$dbh->do("INSERT INTO t (id, name, note) VALUES ($_, 'n$_', 'x')") for 1 .. 3;
my $orm = DBIx::QuickORM->new(dbh => $dbh, row_class => undef);

subtest construction => sub {
    my $h = $orm->handle('t');
    isa_ok($h,         ['DBIx::QuickORM::Handle'],        "handle() returns a handle");
    isa_ok($h->source, ['DBIx::QuickORM::Source::Table'], "over a table source");
    ref_is($h->orm, $orm, "holding the ORM");

    isa_ok($orm->handle(\'SELECT 1')->source, ['DBIx::QuickORM::Source::Query'], "A scalar ref is a query");
    is($orm->handle(\['SELECT ?', 5])->source->binds, [5], "and a ref to an array is a query with binds");
    my $source = $orm->handle('t')->source;
    ref_is($orm->handle($source)->source, $source, "A source object is used as given");

    like(dies { $orm->handle([]) },                                        qr/^handle\(\) takes a table name/,               "Anything else croaks");
    like(dies { $orm->handle('nope') },                                    qr/^The table 'nope' is not in the database map/, "An unknown table croaks");
    like(dies { DBIx::QuickORM::Handle->new(orm => $orm, source => 't') }, qr/^A 'source' is required/,                      "A handle needs a source object");
};

subtest immutable => sub {
    my $h  = $orm->handle('t');
    my $h2 = $h->where({id => 1});
    ok($h2 != $h, "A modifier returns a new handle");
    is($h->where,  undef,     "and leaves the original alone");
    is($h2->where, {id => 1}, "Called without an argument it returns the setting");

    my $all = $h->order_by('id');
    is($all->first->{id}, 1, "The handle's reading methods use its cached iterator");
    ref_is($all->_iter, $all->_iter, "the same one every call");
    ok(!$all->limit(5)->{iterator}, "A modifier's new handle does not carry it over");
    ref_is_not($all->iter, $all->iter,  "iter is a new iterator every call");
    ref_is_not($all->iter, $all->_iter, "never the cached one");
    ref_is($all->iter->query, $all->_iter->query, "but every one shares the handle's query");
    ok(!$all->can('new_iter'), "new_iter is gone");
    is($all->next->{id}, 1, "next walks the handle's own iterator");
    is($all->next->{id}, 2, "keeping its position");
    my $it = $all->iter;
    is($it->next->{id}, 1, "an iterator from iter has its own position");
    $all->reset;
    is($all->next->{id}, 1, "reset rewinds the handle's own iterator");

    my $query = $all->_iter->query;
    is($all->clear, undef, "clear returns nothing");
    ok(!$all->{iterator}, "clear drops the cached iterator in place");
    ref_is_not($all->_iter->query, $query, "the next read sends the query again");
    is($it->next->{id}, 2, "an iterator from before clear keeps its rows");

    my $single = DBIx::QuickORM::Handle->new(orm => $orm, source => $h->source, state => 'single');
    is($single->limit(1)->state,  'single', "Modifiers keep the state");
    is($single->where({}),        T(),      "a new where");
    is($single->where({})->state, undef,    "drops it");

    like(dies { $h->where(1, 2) },   qr/^where\(\) takes one argument/,                "Modifiers take one argument");
    like(dies { $h->fields('id') },  qr/^fields\(\) takes an arrayref of field names/, "fields takes an arrayref");
    like(dies { $h->row_class([]) }, qr/^row_class\(\) takes a class name or undef/,   "row_class takes a class name");

    $dbh->do("CREATE TABLE IF NOT EXISTS v (id INTEGER PRIMARY KEY, t_id INTEGER REFERENCES t(id))");
    my $vorm  = DBIx::QuickORM->new(dbh => $dbh, row_class => undef);
    my $vh    = $vorm->handle('v')->where({id => 2});
    my %calls = (
        where      => [{id => 1}],
        and        => [{id => 1}],
        or         => [{id => 1}],
        order_by   => ['id'],
        limit      => [1],
        offset     => [1],
        fields     => [['id']],
        row_class  => [undef],
        group_by   => ['id'],
        having     => [{id => 1}],
        join       => ['t'],
        inner_join => ['t'],
        left_join  => ['t'],
    );
    for my $method (sort keys %calls) {
        my @args = @{$calls{$method}};
        like(
            dies { $vh->$method(@args); return },
            qr/^\Q$method\E\(\) returns a new handle and leaves this one unchanged; calling it in void context does nothing at \Q${\__FILE__}\E/,
            "$method() croaks in void context, at the caller",
        );
        ok(lives { my $x = $vh->$method(@args) }, "$method() is fine in scalar context");
    }
    ok(lives { $vh->where },          "A getter in void context is fine");
    ok(lives { $vh->where({})->all }, "So is a chain ending in a reader");
};

subtest and_or => sub {
    my $h = $orm->handle('t');
    my $line;
    like(dies { $line = __LINE__; my $x = $h->and({id => 1}) }, qr/^and\(\) needs a where to combine with; this handle has none, use where\(\) instead at \Q${\__FILE__}\E line $line\./, "and on a handle without a where croaks, pointing to where(), at the caller");
    like(dies { my $x = $h->or({id => 1}) }, qr/^or\(\) needs a where to combine with/, "and so does or");
    for my $empty ({}, [], '') {
        my $e    = $h->where($empty);
        my $name = ref($empty) || 'string';
        like(dies { my $x = $e->and({id => 1}) }, qr/^and\(\) needs a where/, "and on an empty $name where croaks");
        like(dies { my $x = $e->or({id => 1}) },  qr/^or\(\) needs a where/,  "and so does or on an empty $name where");
    }

    my $one = $h->where({id => 1});
    is([map { $_->{id} } $one->or({id => 3})->order_by('id')->all], [1, 3],                                "or widens the where");
    is([map { $_->{id} } $one->and({name => 'n2'})->all],           [],                                    "and narrows it");
    is([map { $_->{id} } $one->where({name => 'n2'})->all],         [2],                                   "while where replaces it");
    is($one->and({name => 'n1'})->where,                            {-and => [{id => 1}, {name => 'n1'}]}, "The builder combines the conditions");
    is($one->where,                                                 {id => 1},                             "leaving the original alone");

    is([map { $_->{id} } $one->or({id => raw(2)})->and({name => sql('= ?', 'n2')})->all], [2], "Markers work inside combined conditions");

    my $single = DBIx::QuickORM::Handle->new(orm => $orm, source => $h->source, state => 'single', where => {id => 2});
    is($single->and({id => 1})->state, undef, "and drops the state, as a new where does");

    like(dies { $h->and },        qr/^and\(\) takes one condition/, "and needs a condition");
    like(dies { $h->or({}, {}) }, qr/^or\(\) takes one condition/,  "or takes just one");
};

subtest where_builders => sub {
    my $h  = $orm->handle('t')->where({name => 'n1'});
    my $sa = $h->where_builders(['DBIx::QuickORM::WhereBuilder::SQLAbstract']);
    isa_ok($sa, ['DBIx::QuickORM::Handle'], "where_builders returns a new handle");
    is($sa->where_builders,         ['DBIx::QuickORM::WhereBuilder::SQLAbstract'], "holding the list");
    is($h->where_builders,          undef,                                         "and leaves the original without one");
    is([map { $_->{id} } $sa->all], [1],                                           "The handle's builders render its where");

    my %request = $h->_select_request;
    is($request{where_builders}, $orm->where_builders, "Without its own the handle sends the ORM's");
    %request = $orm->handle('t')->_select_request;
    ok(!exists $request{where_builders}, "and nothing without a where");

    like(dies { $h->where_builders(['DBIx::QuickORM::WhereBuilder::Simple'])->where(sql('id = 1'))->all }, qr/^No where builder can build this where/,           "A where no builder takes croaks when the query is built");
    like(dies { $h->where_builders([]) },                                                                  qr/^where_builders\(\) must be a non-empty arrayref/, "The list is checked as the ORM checks it");
    like(dies { $h->where_builders(['DBIx::QuickORM::WhereBuilder::Simple']); 1 },                         qr/^where_builders\(\) returns a new handle/,         "Void context croaks");
};

subtest fields => sub {
    is($orm->handle('t')->fields(['name'])->where({id => 2})->only, {id => 2, name => 'n2'}, "fields selects a subset, always with the primary key");

    my $full = $orm->handle('t')->where({id => 2})->only;
    my $part = $orm->handle('t')->fields(['name'])->where({id => 2})->only;
    ref_is($part, $full, "Rows from a subset are ingested like any other: an unchanged row keeps the held hash");
};

subtest row_class => sub {
    ok(!DBIx::QuickORM::Test::Row->can('new'), "the test row class is not loaded yet");
    my $loaded = $orm->handle('t')->row_class('DBIx::QuickORM::Test::Row');
    ok(DBIx::QuickORM::Test::Row->can('new'), "row_class loads a class that is not loaded");
    isa_ok($loaded->first, ['DBIx::QuickORM::Test::Row'], "and builds rows with it");
    like(dies { my $h = $orm->handle('t')->row_class('No::Such::Row') }, qr{^The row class 'No::Such::Row' could not be loaded: Can't locate No/Such/Row\.pm}, "one that cannot be loaded croaks");
    like(dies { my $h = $orm->handle('t')->row_class('not a class') },   qr/^The row class 'not a class' is not a valid package name/,                         "and so does a name that is not a package name");

    my $classy = DBIx::QuickORM->new(dbh => $dbh, row_classes => {t => 'DBIx::QuickORM::Test::Row'});
    isa_ok($classy->handle('t')->first, ['DBIx::QuickORM::Test::Row'], "Rows use the table's row class");
    is(ref($classy->handle('t')->row_class(undef)->first), 'HASH', "row_class(undef) on the handle means row data");

    my $data = $classy->handle('t')->data_only;
    is(ref($data->first), 'HASH', "data_only means row data");
    is($data->row_class,  undef,  "as row_class(undef)");
    isa_ok($data->row_class('DBIx::QuickORM::Test::Row')->first, ['DBIx::QuickORM::Test::Row'], "row_class(\$class) undoes it");
    like(dies { $data->data_only(1) }, qr/^data_only\(\) takes no arguments/,   "data_only takes no argument");
    like(dies { $data->data_only },    qr/^data_only\(\) returns a new handle/, "and croaks in void context");
    isa_ok($classy->handle('t')->row_class('DBIx::QuickORM::Row')->first, ['DBIx::QuickORM::Row'], "a class on the handle wins");
    isa_ok($classy->handle(\'SELECT 1 AS one')->first,                    ['DBIx::QuickORM::Row'], "Query rows use the ORM's row class");
    is(ref($classy->handle(\'SELECT 1 AS one')->row_class(undef)->first), 'HASH', "unless the handle sets one");
    isa_ok($classy->handle('t')->row_class('DBIx::QuickORM::Row')->find(1), ['DBIx::QuickORM::Row'], "Delegated primitives build rows as the handle does");
};

subtest guards => sub {
    my $q = $orm->handle(\'SELECT id FROM t');
    like(dies { $q->$_({}) }, qr/^$_\(\) needs a handle on a table, not a query/,     "$_ croaks on a query handle") for qw/insert find update_row delete_row refresh_row update/;
    like(dies { $q->delete }, qr/^delete\(\) needs a handle on a table, not a query/, "delete too");

    my $w = $orm->handle('t')->where({id => 1});
    like(dies { $w->$_({id => 1}) },                    qr/^$_\(\) works on the whole table, but the handle has a where/, "$_ croaks with a where") for qw/insert find update_row delete_row refresh_row/;
    like(dies { $orm->handle('t')->limit(1)->find(1) }, qr/but the handle has a limit/,                                   "and with a limit");

    like(dies { $orm->handle('t')->order_by('id')->delete },            qr/^delete\(\) cannot honor the handle's order_by/,      "Bulk writes croak with an order");
    like(dies { $orm->handle('t')->limit(1)->offset(1)->update({}) },   qr/^update\(\) cannot honor the handle's limit, offset/, "or a limit and offset");
    like(dies { $orm->handle('t')->update('x') },                       qr/^update\(\) takes one hashref of changes/,            "update takes a hashref");
    like(dies { $orm->handle('t')->update({nope => 1}) },               qr/^The table 't' has no field 'nope'/,                  "and only fields of the table");
    like(dies { $orm->handle('t')->delete(1) },                         qr/^delete\(\) takes only 'mark_deleted => \$bool'/,     "delete takes only mark_deleted");
    like(dies { $orm->handle('t')->delete(mark_deleted => 1, x => 1) }, qr/^delete\(\) takes only 'mark_deleted => \$bool'/,     "and nothing else");
};

subtest aggregate => sub {
    $dbh->do("CREATE TABLE g (id INTEGER PRIMARY KEY, kind TEXT, n INTEGER)");
    $dbh->do("INSERT INTO g (id, kind, n) VALUES (1, 'a', 1), (2, 'a', 2), (3, 'b', 5)");
    my $g = DBIx::QuickORM->new(dbh => $dbh, row_class => undef)->handle('g');

    is([$g->group_by('kind')->order_by('kind')->all], [{kind => 'a'}, {kind => 'b'}], "group_by alone selects the grouped fields, as hashrefs");
    is($g->group_by('kind')->group_by,                ['kind'],                       "group_by returns its fields");
    is(
        [$g->group_by('kind')->fields({kind => 'kind', total => sql('SUM(n)')})->having(sql('SUM(n) > 3'))->all],
        [{kind => 'b', total => 5}],
        "Computed fields and having",
    );
    is([$g->fields(['kind'])->group_by('kind')->having({kind => 'b'})->all], [{kind => 'b'}], "A field list under group_by selects those fields, no primary key added");
    is($g->fields({total => sql('SUM(n)')})->only,                           {total => 8},    "Computed fields without group_by aggregate the whole table");
    isa_ok($g->group_by('kind')->row_class('DBIx::QuickORM::Row')->first,          ['DBIx::QuickORM::Row'],          "A handle row_class wraps computed rows");
    isa_ok(DBIx::QuickORM->new(dbh => $dbh)->handle('g')->group_by('kind')->first, ['DBIx::QuickORM::AggregateRow'], "With a row class resolved they are aggregate rows");
    is(DBIx::QuickORM->new(dbh => $dbh)->handle('g')->group_by('kind')->row_class(undef)->first, {kind => 'a'}, "unless the handle's row_class is undef");
    ok(!$g->orm->is_canon(g => {id => 1}), "Nothing is ingested");

    like(dies { $g->group_by('kind')->count },         qr/^count\(\) cannot count groups \(the handle has a group_by\)/,     "count croaks with group_by");
    like(dies { $g->having(sql('1 = 1'))->count },     qr/the handle has a having/,                                          "and with having");
    like(dies { $g->having(sql('1 = 1'))->all },       qr/^A handle with having\(\) needs group_by\(\) or fields to select/, "having needs something to select");
    like(dies { $g->group_by('kind')->$_({id => 1}) }, qr/^$_\(\) works on the whole table, but the handle has a group_by/,  "$_ croaks with group_by") for qw/insert find update_row delete_row refresh_row/;
    like(dies { $g->having(sql('1 = 1'))->delete },    qr/^delete\(\) cannot honor the handle's having/,                     "bulk writes croak with having");
    like(dies { $g->group_by(['kind']) },              qr/^group_by\(\) takes field names/,                                  "group_by takes field names");
    like(dies { $g->fields({}) },                      qr/^fields\(\) takes an arrayref of field names or a hashref/,        "computed fields cannot be empty");
    like(
        dies {
            $g->fields({n => sub { 1 }})
        },
        qr/^Column 'n' must be a field name, an sql\(\) marker/,
        "and take column specs"
    );
    is($g->fields({n => \'COUNT(*)'})->only, {n => 3}, "\\'SQL' is short for sql('SQL')");
    like(dies { $g->fields({n => \''}) }, qr/^sql\(\) needs the SQL as a string/, "and checked as sql() checks it");
};

subtest columns => sub {
    $dbh->do("CREATE TABLE c (id INTEGER PRIMARY KEY, code TEXT UNIQUE, info TEXT)");
    $dbh->do("CREATE TABLE cc (a INTEGER, b INTEGER, PRIMARY KEY (a, b))");
    $dbh->do("CREATE TABLE o (id INTEGER PRIMARY KEY, c_id INTEGER REFERENCES c(id), extra TEXT, n INTEGER, label VARCHAR(50))");
    my $orm  = DBIx::QuickORM->new(dbh => $dbh, types => {o => {extra => 'JSON'}}, like_aggregates => ['Sum']);
    my $o    = $orm->handle('o');
    my $cols = sub { $o->fields({@_})->_columns };

    # Every column is named for itself, in the source's table.
    my $c_id = {table => 'o', name => 'x', orm_type => DNE, db_type => 'INTEGER', type => 'integer', affinity => 'numeric', fk => {c => [{x => 'id'}]}};
    is($cols->(x => 'c_id'),                                                  {x    => {expr => 'c_id', %$c_id}},                                                                                                                       "A plain field takes the field's facts and its foreign key");
    is($cols->(x => 'o.c_id'),                                                {x    => {expr => 'o.c_id', %$c_id}},                                                                                                                     "qualified too");
    is($cols->(x => sql('1')),                                                {x    => {expr => sql('1'), table => 'o', name => 'x'}},                                                                                                  "sql() has no facts");
    is($cols->(x => [max => 'c_id']),                                         {x    => {expr => ['MAX', 'c_id'], %$c_id}},                                                                                                              "max keeps the field's facts");
    is($cols->(x => [MIN => 'extra'])->{x},                                   {expr => ['MIN', 'extra'], table => 'o', name => 'x', orm_type => 'DBIx::QuickORM::Type::JSON', db_type => 'TEXT', type => 'text', affinity => 'string'}, "and so does min, with the type");
    is($cols->(x => [count => 'c_id']),                                       {x    => {expr => ['COUNT', 'c_id'], table => 'o', name => 'x'}},                                                                                         "count does not");
    is($cols->(x => [count => '*']),                                          {x    => {expr => ['COUNT', '*'], table => 'o', name => 'x'}},                                                                                            "'*' is no field: unchecked, with no facts");
    is($cols->(x => [max => '*']),                                            {x    => {expr => ['MAX', '*'], table => 'o', name => 'x'}},                                                                                              "even for max, and any function may take it");
    is($cols->(x => {agg => [count => '*'], type => 'JSON', fk => 'c'})->{x}, {expr => ['COUNT', '*'], table => 'o', name => 'x', orm_type => 'DBIx::QuickORM::Type::JSON', fk => {c => [{x => 'id'}]}},                                "A hash with agg => [func, '*'] still takes type and fk");
    is($cols->(x => [avg => 'c_id']),                                         {x    => {expr => ['AVG', 'c_id'], table => 'o', name => 'x'}},                                                                                           "nor an unknown function");
    is($cols->(x => [SUM => 'c_id']),                                         {x    => {expr => ['SUM', 'c_id'], %$c_id}},                                                                                                              "like_aggregates adds to the set, without regard to case");
    is($o->fields(['c_id'])->group_by('c_id')->_columns, {c_id => {expr => 'c_id', %$c_id, name => 'c_id', fk => {c => [{c_id => 'id'}]}}}, "Grouped fields are plain columns");

    is($cols->(x => {sql => sql('COUNT(*)'), type => 'JSON', db_type => 'json'}),                      {x => {expr => sql('COUNT(*)'), table => 'o', name => 'x', orm_type => 'DBIx::QuickORM::Type::JSON', db_type => 'json', type => 'json', affinity => 'string'}}, "A hash gives type, and db_type with the facts that follow from it");
    is($cols->(x => {agg => [count => 'n'], like => 'c_id'}),                                          {x => {expr => ['COUNT', 'n'], %$c_id}},                                                                                                                        "like copies a field's facts");
    is($cols->(x => {agg => [max => 'c_id'], like => 'n'}),                                            {x => {expr => ['MAX', 'c_id'], table => 'o', name => 'x', orm_type => DNE, db_type => 'INTEGER', type => 'integer', affinity => 'numeric'}},                   "With like, the column has only like's facts, none of what agg implied");
    is($cols->(x => {sql => sql('1'), like => 'label'})->{x}->{size},                                  50,                                                                                                                                                             "like copies the size");
    is($cols->(x => {sql => sql('1'), like => 'label', db_type => 'integer'})->{x},                    {expr => sql('1'), table => 'o', name => 'x', orm_type => DNE, db_type => 'integer', type => 'integer', affinity => 'numeric'},                                 "An explicit db_type replaces the size like gave");
    is($cols->(x => {agg => [max => 'c_id'], type => '+DBIx::QuickORM::Type::UUID'})->{x}->{orm_type}, 'DBIx::QuickORM::Type::UUID',                                                                                                                                   "type overrides what agg implied");
    is($cols->(x => {sql => sql('1'), fk => 'c'})->{x}->{fk},                                          {c => [{x => 'id'}]},                                                                                                                                           "fk => table is its primary key");
    is($cols->(x => {sql => sql('1'), fk => [c => 'code']})->{x}->{fk},                                {c => [{x => 'code'}]},                                                                                                                                         "fk => [table, field]");
    is($cols->(x => {sql => sql('1'), fk => {c => 'info'}})->{x}->{fk},                                {c => [{x => 'info'}]},                                                                                                                                         "fk => {table => field}");
    is($cols->(x => {agg => [max => 'c_id'], fk => {o => 'id'}})->{x}->{fk},                           {o => [{x => 'id'}]},                                                                                                                                           "and replaces the implied foreign keys");

    like(dies { $cols->(x => [max => 'nope']) },                           qr/^Column 'x' names 'nope', which is not a field of the handle's source/,             "An unknown field croaks");
    like(dies { $cols->(x => 'nope') },                                    qr/^Column 'x' names 'nope'/,                                                          "as a plain field too");
    like(dies { $cols->(x => ['max(1); --' => 'n']) },                     qr/^Column 'x' names the function 'max\(1\); --', which is not a word/,                "A function name that is not a word croaks");
    like(dies { $cols->(x => [max => 'n', 1]) },                           qr/^'agg' in column 'x' must be \[func, field\]/,                                      "agg takes two items");
    like(dies { $cols->(x => {agg => [max => 'n'], sql => sql('1')}) },    qr/^Column 'x' needs exactly one of 'sql' or 'agg'/,                                   "both sql and agg croak");
    like(dies { $cols->(x => {like => 'n'}) },                             qr/^Column 'x' needs exactly one of 'sql' or 'agg'/,                                   "and so does neither");
    like(dies { $cols->(x => {sql => sql('1'), bogus => 1}) },             qr/^Unknown key\(s\) in column 'x': bogus/,                                            "An unknown key croaks");
    like(dies { $cols->(x => {sql => 'COUNT(*)'}) },                       qr/^'sql' in column 'x' must be an sql\(\) marker/,                                    "sql takes a marker");
    like(dies { $cols->(x => {sql => sql('1'), fk => 'nope'}) },           qr/^'fk' in column 'x' names the table 'nope', which is not in the database map/,      "fk to an unknown table croaks");
    like(dies { $cols->(x => {sql => sql('1'), fk => [c => 'nope']}) },    qr/^'fk' in column 'x' names 'c\.nope', which is not a field/,                         "and to an unknown field");
    like(dies { $cols->(x => {sql => sql('1'), fk => 'cc'}) },             qr/^'fk' in column 'x' names the table 'cc', whose primary key is not a single field/, "A bare table needs a single-field primary key");
    like(dies { $cols->(x => {sql => sql('1'), fk => [c => 'id', 'x']}) }, qr/^'fk' in column 'x' must be a table, \[table, field\], or \{table => field\}/,      "fk has three forms");
    like(dies { $cols->(x => {sql => sql('1'), type => 'Nope'}) },         qr/^'type' names the type 'Nope', which could not be loaded/,                          "An unknown type croaks");

    is([$o->fields({x => sql('1')})->join('c')->fields({x => [max => 'c.id']})->_columns->{x}->{expr}], [['MAX', 'c.id']], "Join columns name alias.field");
    my $joined = $o->join('c')->fields({x => 'c.id'})->_columns->{x};
    is([$joined->{name}, exists $joined->{table}], ['x', ''], "and are named for themselves with no table: a join has none");
    like(dies { $o->fields({x => 'c_id'})->join('c')->all }, qr/^Column 'x' names 'c_id', which is not a field of the handle's source/, "and a column set before the join is checked again after it");
    is($o->join('c')->fields({x => [count => '*']})->_columns->{x}->{expr},   ['COUNT', '*'],                             "'*' on a join is not qualified");
    is($orm->handle(\'SELECT 1 AS a')->fields({x => [max => 'a']})->_columns, {x => {expr => ['MAX', 'a'], name => 'x'}}, "A query source knows no fields, so names pass unchecked, and has no table");

    like(dies { DBIx::QuickORM->new(dbh => $dbh, like_aggregates => ['bad name']) }, qr/^'like_aggregates' must be an arrayref of function names/, "like_aggregates takes function names");
};

subtest find => sub {
    is($orm->handle('t')->find(3)->{name},                          'n3',  "find takes a primary key value");
    is($orm->handle('t')->find({id => 1})->{id},                    1,     "or a hash");
    is($orm->handle('t')->find(99),                                 undef, "and is undef when there is no such row");
    is($orm->handle('t')->find([2])->{name},                        'n2',  "or an arrayref");
    is($orm->handle('t')->find({id => 2, name => 'other'})->{name}, 'n2',  "A hash may hold other fields, so row data works");

    my $rows = DBIx::QuickORM->new(dbh => $dbh);
    my $row  = $rows->handle('t')->find(2);
    isa_ok($row, ['DBIx::QuickORM::Row'], "A row object");
    is($orm->handle('t')->find($row)->{name}, 'n2', "works as its row data");

    # Declared key order (a, b) differs from the column order (b, a).
    $dbh->do("CREATE TABLE cp (b TEXT, a INTEGER, v TEXT, PRIMARY KEY (a, b))");
    $dbh->do("INSERT INTO cp (b, a, v) VALUES ('x', 1, 'one'), ('y', 2, 'two')");
    my $corm = DBIx::QuickORM->new(dbh => $dbh, row_class => undef);
    my $cp   = $corm->handle('cp');
    is($corm->db_map->pk('cp'),            ['a', 'b'], "The compound key is in declared order");
    is($cp->find({a => 2, b => 'y'})->{v}, 'two',      "find takes a hashref of a compound key");
    is($cp->find([1, 'x'])->{v},           'one',      "and an arrayref in the key's declared order");
    is($cp->find(['x', 1]),                undef,      "not the column order");

    like(dies { $cp->find(1) },                   qr/^The table 'cp' has a compound primary key \(a, b\); give a hashref of its fields or an arrayref of its values in that order/, "A plain value for a compound key croaks");
    like(dies { $cp->find([1]) },                 qr/^The table 'cp' has 2 primary key field\(s\) \(a, b\), but the arrayref holds 1 value\(s\)/,                                   "an arrayref of the wrong length croaks");
    like(dies { $cp->find({a => 1}) },            qr/^The primary key field 'b' of the table 'cp' is missing or undefined/,                                                         "a hash missing a key field croaks");
    like(dies { $orm->handle('t')->find(undef) }, qr/^The primary key field 'id' of the table 't' is missing or undefined/,                                                         "an undef value croaks");

    $dbh->do("CREATE TABLE nk (v TEXT)");
    my $norm = DBIx::QuickORM->new(dbh => $dbh, row_class => undef);
    like(dies { $norm->handle('nk')->find(1) }, qr/^The table 'nk' has no primary key/, "A table without a primary key croaks");

    my ($file, $line) = (__FILE__, __LINE__ + 1);
    like(dies { $orm->handle('t')->find_or_insert({name => 'x'}, by => []) }, qr/^'by' must be a non-empty arrayref of field names at \Q$file\E line $line\./, "find_or_insert reports its caller's line");
};

done_testing;
