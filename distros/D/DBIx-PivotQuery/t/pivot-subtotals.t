#!perl -w
use strict;
use Test::More tests => 4;
use DBIx::PivotQuery 'pivot_by';
use DBIx::RunSQL;
use DBD::SQLite;

my $sql = join "", <DATA>;

my $test_dbh = DBIx::RunSQL->create(
    dsn     => 'dbi:SQLite:dbname=:memory:',
    sql     => \$sql,
);

my $l = pivot_by(
    dbh     => $test_dbh,
    rows    => ['region','customer'],
    columns => ['date'],
    aggregate => ['sum(amount) as amount'],
    placeholder_values => [],
    sql => <<'SQL',
  select
      region
    , "date"
    , amount
    , customer
  from mytable
SQL
);

is_deeply $l->[0],
          [qw(region customer Q1 Q2 Q3 Q4)], "We find all values for the 'date' column and use them as column headers";

my $m = pivot_by(
    dbh     => $test_dbh,
    rows    => ['region', undef],
    columns => ['date'],
    aggregate => ['sum(amount) as amount'],
    placeholder_values => [],
    headers => 0,
    sql => <<'SQL',
  select
      region
    , "date"
    , amount
    , customer
  from mytable
SQL
);

is_deeply [ map { $_->[1] } @$m ], [ (undef) x 4 ],
    "The second column is empty for the subtotals by Region";

my $subtotals = pivot_by(
    dbh     => $test_dbh,
    rows    => ['region','customer'],
    columns => ['date'],
    aggregate => ['sum(amount) as amount'],
    placeholder_values => [],
    subtotals => 1,
    headers => 1,
    sql => <<'SQL',
  select
      region
    , "date"
    , amount
    , customer
  from mytable
SQL
);

is 0+@$subtotals, 1 # header
                 +5 # region+customer
                 +4 # region
                 +1 # totals
   , "We get the expected number of rows";

is_deeply $subtotals->[-1], [undef, undef, 575, 375, 225, 425]
   , "The last row is the grand total";

#use Text::Table;
#my $t = Text::Table->new(@{ shift @$subtotals });
#$t->load(@$subtotals);
#print $t;


__DATA__

create table mytable (
    region varchar(10) not null
  , "date" varchar(2) not null
  , amount decimal(18,2) not null
  , customer integer
);
insert into mytable ("date",region,amount,customer) values ('Q1','North',150,1);
insert into mytable ("date",region,amount,customer) values ('Q2','North',50 ,1);
insert into mytable ("date",region,amount,customer) values ('Q3','North',50 ,1);
insert into mytable ("date",region,amount,customer) values ('Q4','North',10 ,1);
insert into mytable ("date",region,amount,customer) values ('Q1','West', 100,1);
insert into mytable ("date",region,amount,customer) values ('Q3','West', 100,1);
insert into mytable ("date",region,amount,customer) values ('Q4','West', 200,1);
insert into mytable ("date",region,amount,customer) values ('Q1','East', 75 ,1);
insert into mytable ("date",region,amount,customer) values ('Q2','East', 75 ,1);
insert into mytable ("date",region,amount,customer) values ('Q3','East', 75 ,1);
insert into mytable ("date",region,amount,customer) values ('Q4','East', 175,1);
insert into mytable ("date",region,amount,customer) values ('Q1','South',125,1);
insert into mytable ("date",region,amount,customer) values ('Q2','South',125,1);
insert into mytable ("date",region,amount,customer) values ('Q3','South',0  ,1);
insert into mytable ("date",region,amount,customer) values ('Q4','South',20 ,1);

insert into mytable ("date",region,amount,customer) values ('Q1','South',125,2);
insert into mytable ("date",region,amount,customer) values ('Q2','South',125,2);
insert into mytable ("date",region,amount,customer) values ('Q3','South',0  ,2);
insert into mytable ("date",region,amount,customer) values ('Q4','South',20 ,2);
