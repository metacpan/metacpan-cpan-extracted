# Test origin: AI
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM;
use DBIx::QuickORM::Test;
use DBIx::QuickORM::Value qw/sql/;

do_for_all_dbs {
    my ($db, $set) = @_;

    my $dbh = $db->connect;
    $dbh->do("CREATE TABLE customers (id INTEGER NOT NULL PRIMARY KEY, name VARCHAR(20), tier INTEGER)");
    $dbh->do(<<"    EOT");
        CREATE TABLE orders (
            id INTEGER NOT NULL PRIMARY KEY, customer_id INTEGER NOT NULL, status VARCHAR(10), amount INTEGER, created DATE, rep_id INTEGER,
            FOREIGN KEY (customer_id) REFERENCES customers(id), FOREIGN KEY (rep_id) REFERENCES customers(id)
        )
    EOT
    $dbh->do("CREATE TABLE tags (id INTEGER NOT NULL PRIMARY KEY, ref_uuid VARCHAR(36))");

    # Two ORMs over one handle, for reads only: row objects (the default) and hashrefs.
    my $orm = DBIx::QuickORM->new(dbh => $dbh, like_aggregates => ['Sum']);
    my $raw = DBIx::QuickORM->new(dbh => $dbh, row_class       => undef);
    $orm->insert(customers => {id => $_->[0], name => $_->[1], tier => $_->[2]}) for [1, 'ann', 1], [2, 'bob', 2], [3, 'cy', 1];
    $orm->insert(orders => {id => $_->[0], customer_id => $_->[1], status => $_->[2], amount => $_->[3], created => $_->[4], rep_id => $_->[5]})
        for [1, 1, 'ok', 10, '2026-01-01', 2], [2, 1, 'ok', 20, '2026-01-05', 2], [3, 1, 'void', 99, '2026-01-03', undef], [4, 2, 'ok', 5, '2026-02-01', undef],
        [5, 2, 'ok', 6, '2026-02-02', undef], [6, 2, 'ok', 7, '2026-02-03', undef], [7, 3, 'ok', 1, '2026-03-01', 1];
    $orm->insert(tags => {id => 1, ref_uuid => '0d8f5a2e-3c1b-4b7a-9e2f-6a1d4c3b2a10'});
    $orm->clear_cache;

    my $orders = $raw->handle('orders');

    subtest table => sub {
        my @rows = $orders->where({status => {'!=' => 'void'}})->group_by('customer_id')->fields({customer_id => 'customer_id', n => sql('COUNT(*)'), total => sql('SUM(amount)')})->having(sql('COUNT(*) > 1'))->order_by({-desc => 'total'})->all;
        is(\@rows,                                                [{customer_id => 1, n => 2, total => 30}, {customer_id => 2, n => 3, total => 18}], "group_by, computed fields, having, and an order naming a computed field");
        is(ref($rows[0]),                                         'HASH',                                                                             "Computed rows are hashrefs when the ORM's row class is undef");
        is($raw->connection->lookup->lookup(orders => {id => 1}), undef,                                                                              "and nothing enters the lookup table");

        is([$orders->group_by('status')->order_by('status')->all],                   [{status => 'ok'}, {status => 'void'}], "group_by alone selects the grouped fields");
        is([$orders->group_by('status')->having({status => 'void'})->all],           [{status => 'void'}],                   "having names a grouped field");
        is($orders->fields({n => sql('COUNT(*)'), top => sql('MAX(amount)')})->only, {n => 7, top => 99},                    "Computed fields without group_by aggregate the whole table");
        is($orders->fields({n => \'COUNT(*)'})->only,                                {n => 7},                               "\\'SQL' is short for sql('SQL')");
        isa_ok($orders->group_by('status')->row_class('DBIx::QuickORM::Row')->first, ['DBIx::QuickORM::Row'], "A handle row_class wraps computed rows");

        # Literal comparison values: SQLite sends binds as text, which never equals a count.
        my $per = $orders->group_by('customer_id')->fields({customer_id => 'customer_id', n => [count => '*'], total => sql('SUM(amount) + ?', 5)})->order_by('customer_id');
        is([map { $_->{customer_id} } $per->having({n => {'>' => \'2'}})->all],                                        [1, 2], "having names a computed column, on every database");
        is([map { $_->{customer_id} } $per->having({-or => [{n => {'=' => \'1'}}, {total => {'>' => \'130'}}]})->all], [1, 3], "nested, and with the column's binds");
        is([map { $_->{customer_id} } $per->having({customer_id => {'>' => \'1'}, n => {'=' => \'3'}})->all],          [2],    "beside a grouped field");
        is([map { $_->{customer_id} } $per->having(sql('COUNT(*) = 1'))->all],                                         [3],    "sql() is sent as written");

        like(dies { $orders->group_by('status')->count },        qr/^count\(\) cannot count groups/,                                    "count croaks on a grouped handle");
        like(dies { $orders->group_by('status')->find(1) },      qr/^find\(\) works on the whole table, but the handle has a group_by/, "so do the primary key delegations");
        like(dies { $orders->having(sql('1 = 1'))->insert({}) }, qr/^insert\(\) works on the whole table, but the handle has a having/, "and insert");
    };

    subtest join => sub {
        my $joined = $orders->join('customers', link => {customer_id => 'id'})->where({'orders.status' => 'ok'});
        is(
            [$joined->group_by('customers.name')->fields({name => 'customers.name', total => sql('SUM(orders.amount)')})->order_by('name')->all],
            [{name => 'ann', total => 30}, {name => 'bob', total => 18}, {name => 'cy', total => 1}],
            "Computed fields over a join",
        );
        is([$joined->group_by('customers.name')->having(sql('COUNT(*) > 2'))->all], [{'customers.name' => 'bob'}], "group_by alone names each grouped field component.field");
        is($joined->fields({n => sql('COUNT(*)')})->only,                           {n => 6},                      "a whole-join aggregate");
        like(dies { $joined->fields({n => 'amount'})->all }, qr/^Column 'n' names 'amount', which is not a field of the handle's source/, "Computed fields over a join name component.field");
    };

    subtest columns => sub {
        is(
            [$orders->group_by('customer_id')->fields({customer_id => 'customer_id', top => [max => 'amount'], low => {agg => [MIN => 'amount']}, n => [count => 'id']})->order_by('customer_id')->all],
            [{customer_id => 1, top => 99, low => 10, n => 3}, {customer_id => 2, top => 7, low => 5, n => 3}, {customer_id => 3, top => 1, low => 1, n => 1}],
            "[func, field] and {agg => [func, field]} columns",
        );
        is(
            [$orders->join('customers', link => {customer_id => 'id'})->group_by('customers.name')->fields({name => 'customers.name', top => [max => 'orders.amount']})->order_by('name')->all],
            [{name => 'ann', top => 99}, {name => 'bob', top => 7}, {name => 'cy', top => 1}],
            "and over a join, naming alias.field",
        );
        is($raw->handle('customers')->fields({u => [upper => 'name']})->where({id => 1})->only, {u => 'ANN'}, "Any word is a function");

        my $per = $orders->group_by('customer_id')->order_by('customer_id');
        is([$per->fields({customer_id => 'customer_id', n => [count => '*']})->all], [{customer_id => 1, n => 3}, {customer_id => 2, n => 3}, {customer_id => 3, n => 1}], "[count => '*'] counts each group's rows");
        my $typed = $orm->handle('orders')->group_by('customer_id')->order_by('customer_id')->fields({customer_id => 'customer_id', n => {agg => [count => '*'], fk => 'customers'}})->first;
        is($typed->field('n'),                                                       3,    "the hash form, {agg => [count => '*']}");
        is($typed->follow_fk('customers', link => {n => 'id'})->only->field('name'), 'cy', "takes the fk it is given");
        my $bad = $orders->fields({n => [max => '*']});
        is(ref($bad), 'DBIx::QuickORM::Handle', "A function that does not take '*' builds");
        isa_ok(dies { $bad->all }, ['DBIx::QuickORM::Exception::DB'], "and fails when the query runs, with the database's error");
        is(
            [$orders->join('customers', link => {customer_id => 'id'})->group_by('customers.name')->fields({name => 'customers.name', n => [count => '*']})->order_by('name')->all],
            [{name => 'ann', n => 3}, {name => 'bob', n => 3}, {name => 'cy', n => 1}],
            "[count => '*'] over a join",
        );
    };

    subtest aggregate_rows => sub {
        my $by_customer = $orm->handle('orders')->group_by('customer_id')->order_by('customer_id');

        my $row = $by_customer->fields({customer_id => 'customer_id', last => [max => 'created'], n => [count => 'id'], label => sql("'x'")})->first;
        isa_ok($row,                ['DBIx::QuickORM::AggregateRow'],         "Computed rows are aggregate rows when the ORM uses row objects");
        isa_ok($row->field('last'), ['DBIx::QuickORM::Type::DateTime::Lazy'], "max keeps the field's type");
        is($row->field('last')->datetime_ref->ymd, '2026-01-05', "and inflates its value");
        ok(!ref($row->raw_field('last')), "raw_field gives the value as fetched");
        is([$row->fields(qw/n label/)], [3, 'x'], "Untyped columns read as fetched");
        is($row->pk,                    undef,    "An aggregate row has no primary key");

        my $h = $row->follow_fk('customers');
        is($h->state,               'single', "A plain field keeps its foreign key; to a primary key it is single");
        is($h->only->field('name'), 'ann',    "and follows it");

        my $counts = $by_customer->fields({n => [count => 'customer_id'], m => [MAX => 'amount']})->first;
        like(dies { $counts->follow_fk('customers') }, qr/^No column of the aggregate row has a foreign key to 'customers'/, "count and an untyped max keep no foreign key");

        my $sum = $orm->handle('orders')->where({id => 7})->group_by('id')->fields({c => [sum => 'customer_id']})->only;
        is($sum->follow_fk('customers')->only->field('name'), 'cy', "like_aggregates adds sum to the functions that keep the field's facts");

        my $liked = $by_customer->fields({x => {agg => [max => 'customer_id'], like => 'amount'}, d => {agg => [max => 'created'], like => 'amount'}})->first;
        ok(!ref($liked->field('d')), "like takes nothing from the agg field: no DateTime from created");
        is($liked->field('d'), $liked->raw_field('d'), "so the value reads as fetched");
        like(dies { $liked->follow_fk('customers') }, qr/^No column of the aggregate row has a foreign key to 'customers'/, "and none of customer_id's foreign keys");

        my $retyped = $orm->handle('tags')->fields({j => {sql => sql("'[1,2]'"), like => 'ref_uuid', type => 'JSON'}})->first;
        is($retyped->field('j'), [1, 2], "An explicit type inflates, though the like field (text UUID) reads as fetched");

        my $forms = $by_customer->fields({by_pk => {agg => [max => 'customer_id'], fk => 'customers'}, by_pair => {sql => sql('MAX(customer_id)'), fk => [customers => 'id']}, by_tier => {agg => [max => 'customer_id'], fk => {customers => 'tier'}}})->first;
        is($forms->follow_fk('customers', link => {by_pk   => 'id'})->only->field('name'), 'ann', "fk => table targets its primary key");
        is($forms->follow_fk('customers', link => {by_pair => 'id'})->only->field('name'), 'ann', "fk => [table, field]");
        my $tier = $forms->follow_fk('customers', link => {by_tier => 'tier'});
        is($tier->state,                                'multi',       "fk => {table => field}; a target that is not unique is multi");
        is([sort map { $_->field('name') } $tier->all], ['ann', 'cy'], "and finds every match");

        my @reps = $by_customer->fields({customer_id => 'customer_id', rep => [max => 'rep_id']})->all;
        like(dies { $reps[0]->follow_fk('customers') }, qr/^More than one column of the aggregate row has a foreign key to 'customers'; choose one with 'link'/, "Two columns with keys to one table are ambiguous");
        is($reps[0]->follow_fk('customers', link => {rep         => 'id'})->only->field('name'), 'bob', "link picks the column");
        is($reps[0]->follow_fk('customers', link => {customer_id => 'id'})->only->field('name'), 'ann', "either one");
        like(dies { $reps[0]->follow_fk('customers', link => {rep => 'tier'}) }, qr/^The link \(rep => tier\) matches no foreign key from a column to 'customers'/, "A link matching no key croaks");

        my $null = $reps[1]->follow_fk('customers', link => {rep => 'id'});
        is($reps[1]->field('rep'), undef,    "A NULL key column");
        is($null->state,           'single', "keeps the single state");
        is([$null->all],           [],       "and matches nothing");

        my $joined = $orm->handle('orders')->join('customers', link => {customer_id => 'id'})->group_by('orders.customer_id')->fields({cid => 'orders.customer_id', last => [max => 'orders.created']})->order_by('cid')->first;
        is($joined->field('last')->datetime_ref->ymd,            '2026-01-05', "Join aggregates name alias.field and keep its type");
        is($joined->follow_fk('customers')->only->field('name'), 'ann',        "and its foreign key");

        like(dies { $row->update({n => 1}) }, qr/^Cannot update a row without a primary key/,  "update croaks");
        like(dies { $row->$_ },               qr/^Cannot $_ a row without a primary key/,      "$_ croaks") for qw/delete refresh is_canon/;
        like(dies { $row->set_row_data({}) }, qr/^An aggregate row's data cannot be replaced/, "and so does replacing its data");
        is($orm->connection->lookup->lookup(orders => {id => 1}), undef, "Nothing enters the lookup table");
    };
};

done_testing;
