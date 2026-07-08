use Test2::V0 -target => 'DBIx::QuickORM', '!meta', '!pass';
use DBIx::QuickORM;

use lib 't/lib';
use DBIx::QuickORM::Test;

# group_by / having and the column() aggregate helper. A grouped or aggregate
# result is plain data (no row identity), so it is read via data_only or through
# column()/count(); fetching Rows from a grouped handle throws. Writes reject
# group_by/having in two layers (the Handle method and the SQL builder).

# Builder-level check (backend independent): GROUP BY / HAVING land between WHERE
# and ORDER BY, and their binds are ordered where < having < limit.
subtest builder => sub {
    require DBIx::QuickORM::SQLBuilder::SQLAbstract;
    my $b = DBIx::QuickORM::SQLBuilder::SQLAbstract->new(quote_char => q{"}, name_sep => q{.});

    my $sql = $b->qorm_select(
        source   => "orders",
        fields   => ["category", \"COUNT(*) AS n"],
        where    => {status => "paid"},
        group_by => "category",
        having   => \"COUNT(*) > 2",
        order_by => {-desc => "n"},
        limit    => 5,
    );

    like($sql->{statement}, qr/WHERE .* GROUP BY .* HAVING .* ORDER BY .* LIMIT/s, "clauses in WHERE/GROUP BY/HAVING/ORDER BY/LIMIT order");
    is([map { $_->{value} } @{$sql->{bind}}], ['paid', 5], "binds are where-value then limit (literal HAVING carries none)");

    for my $meth (qw/insert update delete/) {
        my $args = "_${meth}_args";
        like(dies { $b->$args({group_by => 'x'}) }, qr/group_by/, "$meth args reject group_by (builder guard)");
        like(dies { $b->$args({having   => 'x'}) }, qr/having/,   "$meth args reject having (builder guard)");
    }
};

do_for_all_dbs {
    my $db = shift;

    db mydb => sub {
        dialect curdialect();
        db_name 'quickdb';
        connect sub { $db->connect };
    };

    orm myorm => sub {
        db 'mydb';
        autofill;
        schema myschema => sub {
            table orders => sub { };
        };
    };

    my $con = orm('myorm')->connect;
    note "dialect: " . $con->dialect->dialect_name;

    $con->insert(orders => {category => 'a', total => 10, qty => 1});
    $con->insert(orders => {category => 'a', total => 20, qty => 2});
    $con->insert(orders => {category => 'a', total => 30, qty => 3});
    $con->insert(orders => {category => 'b', total => 5,  qty => 1});
    $con->insert(orders => {category => 'b', total => 15, qty => 1});

    my $h = $con->handle('orders');

    subtest group_by_select => sub {
        my @rows =
            sort { $a->{category} cmp $b->{category} }
            $h->fields(['category', \'SUM(total) AS s'])->group_by('category')->data_only->all;

        is(scalar(@rows), 2, "two groups");
        is($rows[0]->{category}, 'a', "first group category a");
        is($rows[0]->{s} + 0,    60,  "group a sum = 60");
        is($rows[1]->{category}, 'b', "second group category b");
        is($rows[1]->{s} + 0,    20,  "group b sum = 20");
    };

    subtest having => sub {
        # Repeat the expression (portable: Postgres does not allow HAVING to
        # reference a SELECT alias).
        my @rows = $h->fields(['category', \'SUM(total) AS s'])
            ->group_by('category')
            ->having(\'SUM(total) > 30')
            ->data_only->all;

        is(scalar(@rows), 1, "one group passes having");
        is($rows[0]->{category}, 'a', "only group a (sum 60 > 30)");
    };

    subtest column_aggregates => sub {
        is($h->column('total')->sum + 0,   80, "sum over all rows");
        is($h->column('total')->min + 0,   5,  "min");
        is($h->column('total')->max + 0,   30, "max");
        is($h->column('total')->avg + 0,   16, "avg");
        is($h->column('total')->count + 0, 5,  "count");
        is($h->column('order_id')->func('COUNT') + 0, 5, "func(COUNT)");

        # Literal expression, emitted verbatim.
        is($h->column(\'total * qty')->sum + 0, 160, "sum of a literal expression (total*qty)");

        # Reuses the handle's where.
        is($h->where({category => 'a'})->column('total')->sum + 0, 60, "aggregate honors the handle where");
    };

    subtest column_values => sub {
        my @all = sort { $a <=> $b } $h->column('total')->all;
        is(\@all, [5, 10, 15, 20, 30], "column->all returns every value");

        my @a = sort { $a <=> $b } $h->where({category => 'a'})->column('total')->all;
        is(\@a, [10, 20, 30], "column->all honors the handle where");

        my $it = $h->where({category => 'b'})->column('total')->iterator;
        my @b;
        while (defined(my $v = $it->next)) { push @b => $v }
        is([sort { $a <=> $b } @b], [5, 15], "column->iterator yields each value");
    };

    subtest non_row_guard => sub {
        like(dies { $h->group_by('category')->all }, qr/grouped or aggregate/, "grouped ->all without data_only throws");
        like(dies { $h->group_by('category')->one }, qr/grouped or aggregate/, "grouped ->one without data_only throws");
        like(dies { $h->having(\'SUM(total) > 0')->iterator }, qr/grouped or aggregate/, "having ->iterator without data_only throws");
    };

    subtest write_guards => sub {
        like(dies { $h->group_by('category')->insert({category => 'z', total => 1}) }, qr/group_by/, "insert rejects group_by");
        like(dies { $h->having(\'x')->insert({category => 'z', total => 1}) },          qr/having/,   "insert rejects having");
        like(dies { $h->group_by('category')->update({total => 1}) },                   qr/group_by/, "update rejects group_by");
        like(dies { $h->group_by('category')->delete },                                 qr/group_by/, "delete rejects group_by");

        my $row = $h->where({category => 'b'})->order_by('order_id')->limit(1)->one;
        like(dies { $con->handle($row)->group_by('category')->cas({total => $row->field('total')}, {total => 999}) }, qr/group_by/, "cas rejects group_by");
    };
};

done_testing;
