use Test::More tests => 13;

BEGIN {
        use_ok('DBomb::Query');
};

## Create a bunch of random query objects to put it through the ringer.
ok(new DBomb::Query(qw(col1 col2)), 'new Query object');
ok(new DBomb::Query(qw(col1 col2))->from('tbl1')->from('tbl2'), 'new Query object');
ok(new DBomb::Query(qw(col1 col2))->from('tbl1')->from('tbl2')->join('tbl3'), 'new Query object');
ok(new DBomb::Query(qw(col1 col2))->from('tbl1')->from('tbl2')->join('tbl3')->on("x=y"), 'new Query object');
ok(new DBomb::Query(qw(col2))->join('tbl1','tbl2'), 'new Query object');
ok(new DBomb::Query(qw(col2))->join('tbl1','tbl2')->limit(10), 'new Query object');
ok(new DBomb::Query(qw(col2))->join('tbl1','tbl2')->limit(4,10), 'new Query object');
ok(new DBomb::Query(qw(col2 col2))->order_by('col2','col1')->limit(10), 'new Query object');
ok(new DBomb::Query(qw(col2 col2))->order_by('col2','col1')->desc, 'new Query object');
ok(new DBomb::Query(qw(col2 col2))->order_by('col2','col1')->desc->order_by('col3'), 'new Query object');
ok(new DBomb::Query(qw(col2 col2))->left_join('col2','col1'), 'new Query object');
ok(new DBomb::Query(qw(col2 col2))->right_join('col2','col1'), 'new Query object');

# vim:set ft=perl ai si et ts=4 sts=4 sw=4 tw=0
