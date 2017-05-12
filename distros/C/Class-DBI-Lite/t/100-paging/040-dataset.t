#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use lib qw( lib t/lib );

use_ok( 'My::City' );

my $ds = My::City->dataset(
  data_sql  => <<"SQL",
select * from cities
SQL
  count_sql => <<"SQL",
select count(*) from cities
SQL
  page_number => 1,
  page_size   => 10,
  sort_field  => 'city_name',
  sort_dir    => 'asc',
  filters     => { }
);

ok( $ds, "Got dataset" );

ok( my $res = $ds->execute( My::City->db_Main ), "Got result" );

is(
  $res->{page_size} => 10,
  "res.page_size == 10"
);

is(
  $res->{page_count} => 100,
  "res.page_count == 100"
);


