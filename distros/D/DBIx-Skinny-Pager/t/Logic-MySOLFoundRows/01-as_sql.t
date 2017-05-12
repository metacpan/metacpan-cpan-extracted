use strict;
use warnings;
use Test::More;
use Test::Deep;
use DBIx::Skinny::Pager::Logic::MySQLFoundRows;

{
    my $rs = DBIx::Skinny::Pager::Logic::MySQLFoundRows->new;
    $rs->from(['some_table']);
    $rs->add_where(foo => "bar");
    $rs->add_select("count(*)" => 'cnt');
    my $expected_sql = <<END_OF_SQL;
SELECT SQL_CALC_FOUND_ROWS 
   count(*) AS cnt 
FROM some_table 
WHERE (foo = ?)
END_OF_SQL

    is_deeply(filter_sql($rs->as_sql), filter_sql($expected_sql), "normal case");
}

{
    my $rs = DBIx::Skinny::Pager::Logic::MySQLFoundRows->new;
    $rs->from(['some_table']);
    $rs->add_where(foo => "bar");
    $rs->add_select("count(*)" => 'SELECT');
    my $expected_sql = <<END_OF_SQL;
SELECT SQL_CALC_FOUND_ROWS 
   count(*) AS SELECT
FROM some_table 
WHERE (foo = ?)
END_OF_SQL

    is_deeply(filter_sql($rs->as_sql), filter_sql($expected_sql), "use select as column name.");
}
sub filter_sql {
    my $str = shift;
    [ split /\s+/, $str ];
}

done_testing();

