#!perl -w
use strict;
use Test::More tests => 1;
use DBIx::PivotQuery 'pivot_sql';

my $p = pivot_sql(
    rows    => ['region'],
    columns => ['date'],
    aggregate => ['sum(amount) as amount'],
    sql => <<'SQL',
  select
      region
    , "date"
    , amount
    , address
  from mytable
SQL
);

my $expected = <<SQL;
select
    region
  , date
  , sum(amount) as amount
  from (
  select
      region
    , "date"
    , amount
    , address
  from mytable

) foo
group by region
       , date
order by region
       , date
SQL

is $p, $expected, "We create the expected SQL";
