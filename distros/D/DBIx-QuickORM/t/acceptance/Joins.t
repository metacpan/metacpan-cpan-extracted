# Test origin: AI
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM;
use DBIx::QuickORM::Test;

my %BLOB = (PostgreSQL => 'BYTEA', MySQL => 'VARBINARY(20)', MariaDB => 'VARBINARY(20)', SQLite => 'BLOB', DuckDB => 'BLOB');

do_for_all_dbs {
    my ($db, $set) = @_;

    my $dbh = $db->connect;
    $dbh->do("CREATE TABLE customers (id INTEGER NOT NULL PRIMARY KEY, name VARCHAR(20), badge $BLOB{$set->{family}})");
    $dbh->do("CREATE TABLE employees (id INTEGER NOT NULL PRIMARY KEY, name VARCHAR(20), manager_id INTEGER)");
    $dbh->do("CREATE TABLE orders (id INTEGER NOT NULL PRIMARY KEY, customer_id INTEGER NOT NULL, rep_id INTEGER, amount INTEGER, FOREIGN KEY (customer_id) REFERENCES customers(id), FOREIGN KEY (rep_id) REFERENCES employees(id))");
    $dbh->do("CREATE TABLE notes (order_id INTEGER, body VARCHAR(20), FOREIGN KEY (order_id) REFERENCES orders(id))");

    # Table-level FOREIGN KEY clauses: older MySQL ignores inline REFERENCES. The self-reference is a
    # virtual key, since not every backend declares one.
    my $orm = DBIx::QuickORM->new(dbh => $dbh, fks => {employees => {employees => [{manager_id => 'id'}]}});

    my $bytes = "\x00\xff\xe9 \x01";
    $orm->insert(customers => {id       => 1, name => 'ann', badge => $bytes});
    $orm->insert(customers => {id       => 2, name => 'bob', badge => "\x01"});
    $orm->insert(employees => {id       => $_->[0], name => $_->[1], manager_id => $_->[2]}) for [1, 'boss', undef], [2, 'rep', 1];
    $orm->insert(orders    => {id       => $_->[0], customer_id => $_->[1], rep_id => $_->[2], amount => $_->[3]}) for [1, 1, 2, 10], [2, 1, 2, 20], [3, 2, undef, 5];
    $orm->insert(notes     => {order_id => 1, body => 'hi'});
    $orm->clear_cache;

    my $orders = $orm->handle('orders');

    subtest inner_and_left => sub {
        my @rows = $orders->join('customers')->left_join('employees', as => 'rep')->order_by('orders.id')->all;
        is(scalar(@rows), 3, "One join row per database row");
        isa_ok($rows[0], ['DBIx::QuickORM::JoinRow'], "Rows are join rows");
        is([$rows[0]->aliases],                                 ['orders', 'customers', 'rep'], "Components in join order, the table name by default");
        is([map { $_->row('orders')->field('id') } @rows],      [1, 2, 3],                      "the base rows");
        is([map { $_->row('customers')->field('name') } @rows], [qw/ann ann bob/],              "the inner-joined rows");
        is($rows[0]->row('rep')->field('name'),                 'rep',                          "a left-joined row");
        is($rows[2]->row('rep'),                                undef,                          "and undef where the left join matched nothing");
        isa_ok($rows[0]->row('customers'), ['DBIx::QuickORM::Row'], "Components use their tables' row classes");

        is([map { $_->row('orders')->field('id') } $orders->inner_join('employees', as => 'rep')->order_by('orders.id')->all], [1, 2], "inner_join drops unmatched rows");
        is($orders->join('customers')->count,                                                                                  3,      "count counts the joined rows");
    };

    subtest chained => sub {
        my $h    = $orders->left_join('employees', as => 'rep')->left_join('employees', as => 'manager', from => 'rep', link => {manager_id => 'id'})->order_by('orders.id');
        my @rows = $h->all;
        is($rows[0]->row('manager')->field('name'), 'boss', "from joins from another component: a self-join through 'as'");
        is($rows[2]->row('manager'),                undef,  "a left join from an unmatched component matches nothing");

        my $reports = $orm->handle('employees')->join('employees', as => 'report', link => {id => 'manager_id'});
        is([map { $_->row('report')->field('name') } $reports->all], ['rep'], "A link gives the direction of a self-join");
        my @notes = $orders->left_join('notes')->order_by('orders.id')->all;
        is($notes[0]->row('notes')->row_data, {order_id => 1, body => 'hi'}, "A component without a primary key is built but not ingested");
        is($notes[1]->row('notes'),           undef,                         "and undef when unmatched");
    };

    subtest names => sub {
        my $h = $orders->join('customers')->where({'customers.name' => 'ann', 'orders.amount' => {'>' => 15}});
        is([map { $_->row('orders')->field('id') } $h->all],                                                                               [2],       "where names fields as component.field");
        is([map { $_->row('orders')->field('id') } $orders->join('customers')->order_by([{-desc => 'customers.name'}, 'orders.id'])->all], [3, 1, 2], "and so does order_by");

        my $subset = $orders->join('customers')->fields(['customers.name'])->where({'orders.id' => 1})->only;
        is($subset->data,                                                                                                                         {'customers.name' => 'ann', 'customers.id' => 1, 'orders.id' => 1}, "fields selects a subset, with each primary key");
        is([map { $_->row('orders')->field('id') } $orders->join('customers')->where({'customers.badge' => $bytes})->order_by('orders.id')->all], [1, 2],                                                             "A binary field binds as binary through a join");
        is($orders->join('customers')->where({'orders.id' => 1})->only->data->{'customers.badge'},                                                $bytes,                                                             "and is fetched as bytes");

        like(dies { $orders->join('customers')->fields(['name'])->all },       qr/^A join names fields as component\.field; 'name' is not a field of a component/, "A plain name in fields croaks");
        like(dies { $orders->join('customers')->join('customers') },           qr/^The join already has a component named 'customers'/,                            "A taken name croaks");
        like(dies { $orm->handle('employees')->join('employees', as => 'x') }, qr/^There is more than one foreign key between 'employees' and 'employees'/,        "An ambiguous link croaks");
        like(dies { $orm->handle(\'SELECT 1')->join('customers') },            qr/^Joins start from a table handle/,                                               "Joins start from tables");
    };

    subtest rows => sub {
        $orm->clear_cache;
        my @rows = $orders->join('customers')->order_by('orders.id')->all;
        ref_is($rows[0]->row('customers'), $rows[1]->row('customers'), "A component repeated across rows is one row object within a result");
        ok($orm->is_canon(customers => $rows[0]->row('customers')), "and canon");

        my $again = $orders->join('customers')->order_by('orders.id')->first;
        ref_is($again->row('customers')->row_data, $rows[0]->row('customers')->row_data, "Another query gives the same canon hash");

        # Order 3: DuckDB refuses updates to rows another table's foreign key references.
        $rows[2]->row('orders')->update({amount => 6});
        is($orm->handle('orders')->find(3)->field('amount'), 6, "Writes go through the component rows");
        ok(!$rows[0]->can('update'), "join rows have no write methods");

        my $raw = $orders->join('customers')->row_class(undef)->order_by('orders.id')->last;
        is(ref($raw),               'HASH', "row_class undef gives each row's raw data");
        is($raw->{'orders.amount'}, 6,      "keyed component.field");
        like(dies { $orders->join('customers')->row_class('DBIx::QuickORM::Row')->first }, qr/^A join handle's row_class can only be undef/, "Any other row_class croaks");

        like(dies { $orders->join('customers')->insert({id => 9}) },         qr/^insert\(\) needs a handle on a table, not a query or join/,         "A join cannot be written through");
        like(dies { $orders->join('customers')->find(1) },                   qr/^find\(\) needs a handle on a table/,                                "nor looked up by primary key");
        like(dies { $orders->join('customers')->find_or_insert({id => 9}) }, qr/^find_or_insert\(\) needs a handle on a table, not a query or join/, "nor found or inserted");
    };
};

done_testing;
