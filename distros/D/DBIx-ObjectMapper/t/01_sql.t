use Test::Base;
plan tests => ( 1 * blocks ) + 18;

use DBIx::ObjectMapper::SQL;

sub as_sql {
    my $param = shift;
    my ($sql, @bind) = $param->as_sql;
    return $sql . ' <= ' . join(',', @bind);
}

filters {
    input   => [qw(eval as_sql chomp)],
    expected => [qw(chomp)]
};

run_is;

{
    my $input = {
        column => [ 'customer_id', [ { count => 'order_id' }, 'cnt' ] ],
        from => [ [ 'order_mst' => 'orders' ] ],
        join => [
            [qw(order_goods_dtl order_id left)],
            [   'order_goods',
                [ [ 'order_goods.order_id' => \'order_mst.order_id' ], ],
                'left',
            ]
        ],
        where => [
            [   'order_insdate', 'between',
                [ '2008-01-01 00:00:00', '2009-01-01 00:00:00' ]
            ],
            [ 'order_status', 'not in', [ 1, 2, 3, 4 ] ],
            [ 'name', 'not like', '%hoge%' ],
        ],
        group_by => 'customer_id',
        order_by => 'customer_id',
        limit    => 10,
        offset   => 20,
        having   => [ [ { 'count' => 'order_id' }, '>', '1' ], ],
        driver   => 'Pg',
    };
    my $sql = DBIx::ObjectMapper::SQL->select(%$input);
    $input = { %$sql };

    my $clone = $sql->clone;
    is_deeply { %$clone }, $input;
    ok $clone != $input, "$clone != $input";

    for my $meth ( keys %$input ) {
        next if $meth eq 'driver';
        is_deeply $sql->$meth, $clone->$meth;
        if( ref $sql->{$meth} ) {
            isnt $sql->{$meth}, $clone->{$meth};
        }
    }
};


__END__
=== SELECT1
--- input
DBIx::ObjectMapper::SQL->select(
   column => [ 'customer_id', [ { count => 'order_id' }, 'cnt' ] ],
   from   => [ ['order_mst' => 'orders'] ],
   join  => [
       [qw(order_goods_dtl order_id left)],
       [
           'order_goods',
           [
               [ 'order_goods.order_id' => \'order_mst.order_id' ],
           ],
           'left',
       ]
   ],
   where => [
       [ 'order_insdate', 'between', [
           '2008-01-01 00:00:00',
           '2009-01-01 00:00:00'
       ]],
       [ 'order_status', 'not in', [1,2,3,4] ],
       [ 'name', 'not like', '%hoge%' ],
   ],
   group_by => 'customer_id',
   order_by => 'customer_id',
   limit => 10,
   offset => 20,
   having => [
       [ { 'count' => 'order_id' }, '>', '1' ],
   ],
   driver => 'Pg',
);
--- expected
SELECT customer_id, COUNT(order_id) AS cnt FROM order_mst AS orders LEFT JOIN order_goods_dtl USING(order_id) LEFT JOIN order_goods ON ( order_goods.order_id = order_mst.order_id ) WHERE ( order_insdate BETWEEN ? AND ? AND order_status NOT IN (?,?,?,?) AND name NOT LIKE ? ) GROUP BY customer_id HAVING ( COUNT(order_id) > ? ) ORDER BY customer_id LIMIT 10 OFFSET 20 <= 2008-01-01 00:00:00,2009-01-01 00:00:00,1,2,3,4,%hoge%,1

=== SELECT2
--- input
my $sql = DBIx::ObjectMapper::SQL->select()
->column ( qw(a b c d) )
->where(
        [ 'a' , '=', 1 ],
        [ { sum => 'd' }, '>', 100 ],
        [  'text', '@@', 'hogefuga' ]
)
->limit(100)
->offset(2)
->order_by('hogehoge desc');

$sql->add_column({ sum => 'd' });
$sql->add_from( 'table' );
$sql->add_where(
        {
            or => [
                [ 'c', '=', 1 ],
                [ d => 2 ],
            ]
        }
);
$sql->add_order_by('fugafuga');

return $sql;
--- expected
SELECT a, b, c, d, SUM(d) FROM table WHERE ( a = ? AND SUM(d) > ? AND text @@ ? AND ( c = ? OR d = ? ) ) ORDER BY hogehoge desc, fugafuga LIMIT 2, 100 <= 1,100,hogefuga,1,2

=== INSERT
--- input
DBIx::ObjectMapper::SQL->insert(
    into   => 'hoge',
    values => {
        a => 1,
        b => 2,
        c => 3,
        d => 4,
    }
);
--- expected
INSERT INTO hoge ( a, b, c, d ) VALUES (?,?,?,?) <= 1,2,3,4

=== INSERT2
--- input
DBIx::ObjectMapper::SQL->insert(
    into   => 'hoge',
    values => {
        id => \'nextval(\'hoge_seq\')',
        b => 2,
        c => 3,
        d => 4,
    }
);
--- expected
INSERT INTO hoge ( b, c, d, id ) VALUES (?,?,?,nextval('hoge_seq')) <= 2,3,4

=== INSERT SELECT
--- input
DBIx::ObjectMapper::SQL->insert()
->into('hoge')
->values(
    [ qw(a b c d) ] => DBIx::ObjectMapper::SQL->select
                    ->from('hoge2')
                    ->where(
                        [ a => 1 ],
                        [ b => 2 ],
                    )
);
--- expected
INSERT INTO hoge ( a, b, c, d ) SELECT * FROM hoge2 WHERE ( a = ? AND b = ? ) <= 1,2

=== INSERT SELECT add
--- input
my $sql = DBIx::ObjectMapper::SQL->insert();
$sql->into('hoge');
$sql->add_values(
    [ qw(a b c d) ] => DBIx::ObjectMapper::SQL->select
                    ->from('hoge2')
                    ->where(
                        [ a => 1 ],
                        [ b => 2 ],
                    )
);
return $sql;
--- expected
INSERT INTO hoge ( a, b, c, d ) SELECT * FROM hoge2 WHERE ( a = ? AND b = ? ) <= 1,2

=== INSERT MULTI ARRAY
--- input
DBIx::ObjectMapper::SQL->insert()
->into('hoge')
->values(
    [ qw(a b c d) ],
    [ qw(1 2 3 4) ],
    [ qw(5 6 7 8) ],
    [ qw(9 10 11 12) ],
);
--- expected
INSERT INTO hoge ( a, b, c, d ) VALUES (?,?,?,?), (?,?,?,?), (?,?,?,?) <= 1,2,3,4,5,6,7,8,9,10,11,12

=== INSERT MULTI HASH
--- input
DBIx::ObjectMapper::SQL->insert()
->into('hoge')
->values(
    { a => 1, b => 2, c => 3, d => 4 },
    { a => 5, b => 6, c => 7, d => 8 },
    { a => 9, b => 10, c => 11, d => 12},
);
--- expected
INSERT INTO hoge ( a, b, c, d ) VALUES (?,?,?,?), (?,?,?,?), (?,?,?,?) <= 1,2,3,4,5,6,7,8,9,10,11,12


=== INSERT MULTI ADD
--- input
my $sql = DBIx::ObjectMapper::SQL->insert();
$sql->into('hoge');
$sql->add_values(
    [ qw(a b c d) ],
    [ qw(1 2 3 4) ],
    [ qw(5 6 7 8) ],
    [ qw(9 10 11 12) ],
);
return $sql;
--- expected
INSERT INTO hoge ( a, b, c, d ) VALUES (?,?,?,?), (?,?,?,?), (?,?,?,?) <= 1,2,3,4,5,6,7,8,9,10,11,12

=== INSERT ADD
--- input
my $sql = DBIx::ObjectMapper::SQL->insert();
$sql->into('foo');
$sql->values( a => 1, b => 2 );
$sql->add_values( c => 3 );

return $sql;
--- expected
INSERT INTO foo ( a, b, c ) VALUES (?,?,?) <= 1,2,3

=== UPDATE
--- input
DBIx::ObjectMapper::SQL->update(
    table => 'foo',
    set   => {
         a => 1,
         b => 2,
    },
    where => [
        [ c => 1 ],
    ]
);
--- expected
UPDATE foo SET a = ? , b = ? WHERE ( c = ? ) <= 1,2,1

=== UPDATE ADD
--- input
my $sql = DBIx::ObjectMapper::SQL->update;
$sql->table('foo');
$sql->set( a => 1 );
$sql->where( [qw(c 1)] );

$sql->add_set( b => 2 );
$sql->add_where( [ d => q(hoge) ] );

return $sql;
--- expected
UPDATE foo SET a = ? , b = ? WHERE ( c = ? AND d = ? ) <= 1,2,1,hoge

=== UPDATE CHAIN
--- input
DBIx::ObjectMapper::SQL->update->table('foo')->set( a => 1 )->where( [qw(c 1)] );
--- expected
UPDATE foo SET a = ? WHERE ( c = ? ) <= 1,1

=== UPDATE DIRECT
--- input
DBIx::ObjectMapper::SQL->update->table('foo')->set( a => \'a + 1', b => 1 )->where( [qw(c 1)] );
--- expected
UPDATE foo SET a = a + 1 , b = ? WHERE ( c = ? ) <= 1,1


=== DELETE
--- input
DBIx::ObjectMapper::SQL->delete(
    table => 'bar',
    where => [
        [ qw(a 1) ],
        [ qw(b 2) ],
    ]
);
--- expected
DELETE FROM bar WHERE ( a = ? AND b = ? ) <= 1,2

=== DELETE ADD
--- input
my $sql = DBIx::ObjectMapper::SQL->delete()->where([ qw(a 1) ]);
$sql->add_table('bar');
$sql->add_where(
    [ qw(b 2) ],
);
--- expected
DELETE FROM bar WHERE ( a = ? AND b = ? ) <= 1,2

=== SELECT JOIN
--- input
DBIx::ObjectMapper::SQL->select(
    from => 'hoge',
    join  => [
       [
           'order_goods',
           [
               [ 'order_goods.order_id', 1 ],
           ],
           'left',
       ]
   ],
   where =>[ [ qw( a 2 ) ] ]
);
--- expected
SELECT * FROM hoge LEFT JOIN order_goods ON ( order_goods.order_id = ? ) WHERE ( a = ? ) <= 1,2

=== UNION
--- input
my $q = DBIx::ObjectMapper::SQL->union(
    driver => 'Pg',
    sets => [
       DBIx::ObjectMapper::SQL->select(
         from => 'table1',
         column => [qw(id name)],
         where => [[qw(id 1)]],
       ),
       DBIx::ObjectMapper::SQL->select(
         from => 'table2',
         column => [qw(id name)],
         where => [[qw(id 1)]],
       ),
    ],
    order_by => [qw(id)],
    group_by => [qw(id)],
    limit    => 10,
    offset   => 100,
);
$q->add_sets(
       DBIx::ObjectMapper::SQL->select(
         from => 'table3',
         column => [qw(id name)],
         where => [[qw(id 1)]],
       ),
);
return $q;
--- expected
( SELECT id, name FROM table1 WHERE ( id = ? ) ) UNION ( SELECT id, name FROM table2 WHERE ( id = ? ) ) UNION ( SELECT id, name FROM table3 WHERE ( id = ? ) ) GROUP BY id ORDER BY id LIMIT 10 OFFSET 100 <= 1,1,1

=== UNION Chain
--- input
DBIx::ObjectMapper::SQL->new('Pg')->union->sets(
       DBIx::ObjectMapper::SQL->select(
         from => 'table1',
         column => [qw(id name)],
         where => [[qw(id 1)]],
       ),
       DBIx::ObjectMapper::SQL->select(
         from => 'table2',
         column => [qw(id name)],
         where => [[qw(id 1)]],
       ),
       DBIx::ObjectMapper::SQL->select(
         from => 'table3',
         column => [qw(id name)],
         where => [[qw(id 1)]],
       ),
)->order_by('id')->group_by('id')->limit(10)->offset(100);

--- expected
( SELECT id, name FROM table1 WHERE ( id = ? ) ) UNION ( SELECT id, name FROM table2 WHERE ( id = ? ) ) UNION ( SELECT id, name FROM table3 WHERE ( id = ? ) ) GROUP BY id ORDER BY id LIMIT 10 OFFSET 100 <= 1,1,1

=== INTERSECT
--- input
DBIx::ObjectMapper::SQL->new('Pg')->intersect->sets(
       DBIx::ObjectMapper::SQL->select(
         from => 'table1',
         column => [qw(id name)],
         where => [[qw(id 1)]],
       ),
       DBIx::ObjectMapper::SQL->select(
         from => 'table2',
         column => [qw(id name)],
         where => [[qw(id 1)]],
       ),
)->order_by('id')->group_by('id')->limit(10)->offset(100);

--- expected
( SELECT id, name FROM table1 WHERE ( id = ? ) ) INTERSECT ( SELECT id, name FROM table2 WHERE ( id = ? ) ) GROUP BY id ORDER BY id LIMIT 10 OFFSET 100 <= 1,1

=== EXCEPT
--- input
DBIx::ObjectMapper::SQL->new('Pg')->except->sets(
       DBIx::ObjectMapper::SQL->select(
         from => 'table1',
         column => [qw(id name)],
         where => [[qw(id 1)]],
       ),
       DBIx::ObjectMapper::SQL->select(
         from => 'table2',
         column => [qw(id name)],
         where => [[qw(id 1)]],
       ),
)->order_by('id')->group_by('id')->limit(10)->offset(100);

--- expected
( SELECT id, name FROM table1 WHERE ( id = ? ) ) EXCEPT ( SELECT id, name FROM table2 WHERE ( id = ? ) ) GROUP BY id ORDER BY id LIMIT 10 OFFSET 100 <= 1,1


=== SUBQUERY1
--- input
my $sql = DBIx::ObjectMapper::SQL->select->column(qw(id text))->from('parent')->join(
  [
   [
    DBIx::ObjectMapper::SQL->select->from('child')->where( [ 'id', '>', 10 ] ),
    'c',
   ],
    [ [ 'parent.id', \'c.parent_id' ] ],
  ]
)->where( [ 'parent_id', 1 ] );

$sql;
--- expected
SELECT id, text FROM parent LEFT OUTER JOIN ( SELECT * FROM child WHERE ( id > ? ) ) AS c ON ( parent.id = c.parent_id ) WHERE ( parent_id = ? ) <= 10,1

=== SUBQUERY2
--- input
DBIx::ObjectMapper::SQL->select->column('col1')->from('tab1')->where(
    [ { exists => DBIx::ObjectMapper::SQL->select->column('1')->from('tab2')->where( [ 'col2', \'tab1.col2'] ) } ]
);
--- expected
SELECT col1 FROM tab1 WHERE ( EXISTS( SELECT 1 FROM tab2 WHERE ( col2 = tab1.col2 ) ) ) <= 

=== SUBQUERY3
--- input
DBIx::ObjectMapper::SQL->select->from('testm')->where(
    [
       'key',
       '=',
        [ DBIx::ObjectMapper::SQL->select->column({distinct => 'code1'})
          ->from('test2m')->where( ['code1', 'like', 'a%']) ]
    ]
);
--- expected
SELECT * FROM testm WHERE ( key IN (( SELECT DISTINCT(code1) FROM test2m WHERE ( code1 LIKE ? ) )) ) <= a%

=== SUBQUERY4
--- input
DBIx::ObjectMapper::SQL->select->from('testm')->where(
   [
       'key',
       '>',
       { any => DBIx::ObjectMapper::SQL->select->column({distinct => 'code1'})->from('test2m')->where( [ 'code1', 'like', 'a%'] ) }
   ]
);
--- expected
SELECT * FROM testm WHERE ( key > ANY( SELECT DISTINCT(code1) FROM test2m WHERE ( code1 LIKE ? ) ) ) <= a%

=== DIRECT input
--- input
DBIx::ObjectMapper::SQL->select->from('table')->where( \'id=1', [ 'cd', 1 ] );

--- expected
SELECT * FROM table WHERE ( id=1 AND cd = ? ) <= 1

=== natural join
--- input
DBIx::ObjectMapper::SQL->select->from('hoge')->join( ['fuga', undef, 'natural'] );

--- expected
SELECT * FROM hoge NATURAL JOIN fuga <= 
