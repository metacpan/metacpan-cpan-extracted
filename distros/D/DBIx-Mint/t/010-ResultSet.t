#!/usr/bin/perl

use Test::More tests => 48;
use strict;
use warnings;

BEGIN {
    use_ok 'DBIx::Mint';
    use_ok 'DBIx::Mint::ResultSet';
}

my $mint = DBIx::Mint->instance;
isa_ok($mint, 'DBIx::Mint');

my $rs = DBIx::Mint::ResultSet->new(
    table => 'craters',
);
isa_ok($rs, 'DBIx::Mint::ResultSet');

# Tests for joining tables
{
    my $new_rs = $rs->inner_join(['table2','t2'], {  field1 => 't2.field2' })
                    ->left_join (['table3','t3'], {  field2 => 'field1'    });
    isa_ok($new_rs, 'DBIx::Mint::ResultSet');
    my ($sql, @bind) = $new_rs->select_sql;
    like( $sql, qr{FROM craters AS me INNER JOIN table2 AS t2 ON}, 'SQL from joined tables set correctly 1');
    like( $sql, qr{me\.field1 = t2\.field2},                       'SQL from joined tables set correctly 2');
    like( $sql, qr{LEFT OUTER JOIN table3 AS t3 ON},               'SQL from joined tables set correctly 3');
    like( $sql, qr{me\.field2 = t3\.field1},                       'SQL from joined tables set correctly 4');
}
{
    my $new_rs = $rs->inner_join(['table2','t2'], { 't2.field1' => 'me.field2', 'me.field3' => 't2.field4' });
    isa_ok($new_rs, 'DBIx::Mint::ResultSet');
    my ($sql,@bind) = $new_rs->select_sql;
    like( $sql, qr{INNER JOIN table2 AS t2 ON}, 'SQL from joined tables with multiple conditions set correctly 1');
    like( $sql, qr{me\.field3 = t2\.field4},    'SQL from joined tables with multiple conditions set correctly 2');
    like( $sql, qr{t2\.field1 = me\.field2},    'SQL from joined tables with multiple conditions set correctly 3');
}

# Tests for selecting columns (add_columns)
{
    my ($sql, @bind) = $rs->select_sql;
    like($sql, qr{SELECT \* FROM craters AS me},
        'Not specifying columns works as expected');
}

{
    my $newrs = $rs->select( qw{field1|F1 field2} );
    isa_ok($newrs, 'DBIx::Mint::ResultSet');
    my ($sql, @bind) = $newrs->select_sql;
    like($sql, qr{SELECT field1 AS F1, field2 FROM craters AS me},
        'Selecting columns works as expected');
}

# Tests for where clauses (add_conditions)
{
    my ($sql, @bind) = $rs->search({ name => 'Copernicus'})->select_sql;
    like($sql, qr{SELECT \* FROM craters AS me WHERE \( name = \? \)},
        'Added a condition to the where clause');
}
{
    my ($sql, @bind) = $rs->search({ name => 'Copernicus'})
                          ->search({ field1 => [1,2]})
                          ->select_sql;
    like($sql, qr{SELECT \* FROM craters AS me WHERE \( \( name = \? AND \( field1 = \? OR field1 = \? \) \) \)},
        'Added two independent conditions to the where clause');
}

# Tests for order by
{
    my $newrs = $rs->order_by(['colA', 'colB']);
    isa_ok($newrs, 'DBIx::Mint::ResultSet');
    my ($sql, @bind) = $newrs->select_sql;
    like( $sql, qr{ORDER BY colA, colB}, 
        'ORDER BY works correctly with an array ref of fields');
}
{
    my $newrs = $rs->order_by( {-desc => 'colA' } );
    isa_ok($newrs, 'DBIx::Mint::ResultSet');
    my ($sql, @bind) = $newrs->select_sql;
    like( $sql, qr{ORDER BY colA DESC}, 
        'ORDER BY works correctly with a hash ref');
}

# Tests for group_by
{
    my $newrs = $rs->group_by('field1');
    isa_ok($newrs, 'DBIx::Mint::ResultSet');
    my ($sql, @bind) = $newrs->select_sql;
    like( $sql, qr{SELECT \* FROM craters AS me GROUP BY field1}, 
        'GROUP BY works correctly with a single argument');
}
{
    my $newrs = $rs->group_by(qw{field1 field2});
    isa_ok($newrs, 'DBIx::Mint::ResultSet');
    my ($sql, @bind) = $newrs->select_sql;
    like( $sql, qr{SELECT \* FROM craters AS me GROUP BY field1, field2}, 
        'GROUP BY works correctly with more than one argument');
}

# Tests for having
{
    my $newrs = $rs->group_by('field1')->having({'field2' => {'>' => 15}});
    isa_ok($newrs, 'DBIx::Mint::ResultSet');
    my ($sql, @bind) = $newrs->select_sql;
    like( $sql, qr{GROUP BY field1\s+HAVING \( field2 > \? \)}, 
        'GROUP BY / HAVING works correctly with a single argument');
    is( $bind[0], 15, 'Bound values are correct for GROUP BY/HAVING');
}
{
    my $newrs = $rs->group_by(qw{field1 field2})
                   ->having({field3 => {'>' => 15}, field4 => {'=' => 13}});
    isa_ok($newrs, 'DBIx::Mint::ResultSet');
    my ($sql, @bind) = $newrs->select_sql;
    like( $sql, qr{GROUP BY field1, field2\s+HAVING \( \( field3 > \? AND field4 = \? \) \)}, 
        'GROUP BY/HAVING works correctly with more than one argument');
    is_deeply( \@bind, [15,13], 'Bound values are correct for GROUP BY/HAVING');
}

# Tests for page, limit, offset, set_rows_per_page
{
    my $newrs = $rs->page(3);
    isa_ok($newrs, 'DBIx::Mint::ResultSet');
    my ($sql, @bind) = $newrs->select_sql;
    like( $sql, qr{LIMIT ?},    'Paging sets LIMIT correctly');
    like( $sql, qr{OFFSET ?},   'Paging sets OFFSET correctly');
    is_deeply( \@bind, [10,20], 'Bound values are correct when paging');
}
{
    my $newrs = $rs->page();   # Returns page 1
    isa_ok($newrs, 'DBIx::Mint::ResultSet');
    my ($sql, @bind) = $newrs->select_sql;
    like( $sql, qr{LIMIT ?},    'Paging sets LIMIT correctly');
    like( $sql, qr{OFFSET ?},   'Paging sets OFFSET correctly');
    is_deeply( \@bind, [10, 0], 'Bound values are correct when paging (with undefined page number)');
}
{
    my $newrs = $rs->limit(1);
    isa_ok($newrs, 'DBIx::Mint::ResultSet');
    my ($sql, @bind) = $newrs->select_sql;
    like( $sql, qr{LIMIT ?}, 
        'limit results in correct SQL');
    is( $bind[0], 1, 'Bound values are correct for LIMIT clause');
}
{
    my $newrs = $rs->limit(5)->offset(32);
    isa_ok($newrs, 'DBIx::Mint::ResultSet');
    my ($sql, @bind) = $newrs->select_sql;
    like( $sql, qr{OFFSET ?}, 
        'offset results in correct SQL');
    is( $bind[1], 32, 'Bound values are correct for OFFSET clause');
}
{
    my $newrs = $rs->set_rows_per_page(25)->page(3);
    isa_ok($newrs, 'DBIx::Mint::ResultSet');
    my ($sql, @bind) = $newrs->select_sql;
    # LIMIT 25 OFFSET 50
    is_deeply( \@bind, [25,50], 'Bound values are correct after changing rows_per_page');
}


done_testing();
