use strict;
use warnings;
use Test::More;
use DBIx::Skinny::Pager::Logic::PlusOne;

sub filter_sql {
    my $str = shift;
    [ split /\s+/, $str ];
}

{
    my $rs = DBIx::Skinny::Pager::Logic::PlusOne->new;
    $rs->from(['some_table']);
    $rs->add_where(foo => "bar");
    $rs->select([qw(foo bar baz)]);
    $rs->limit(10);
    $rs->offset(20);
    my $expected_sql = <<END_OF_SQL;
SELECT
   foo, bar, baz
FROM some_table 
WHERE (foo = ?)
LIMIT 11
OFFSET 20
END_OF_SQL

    is_deeply(filter_sql($rs->as_sql), filter_sql($expected_sql), "should execute limit + 1");
    is($rs->limit, 10, 'should not have side effect');
}

done_testing();

