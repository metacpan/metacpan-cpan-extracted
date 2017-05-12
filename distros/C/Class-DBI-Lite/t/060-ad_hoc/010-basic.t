#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use lib qw( lib t/lib );

use Data::Dumper;

use_ok('My::Model');
use_ok('My::City');
use_ok('My::State');

map { $_->delete } My::City->retrieve_all;

My::City->find_or_create(
  state_id  =>
    My::State->find_or_create(
      state_name => 'Colorado',
      state_abbr => 'CO'
    )->id,
  city_name => 'Denver',
);

my ($city) = My::Model->ad_hoc(
  sql         => 'SELECT * FROM cities WHERE city_name = ?',
  args        => ['Denver'],
  isa         => 'My::City',
  primary_key => 'city_id',
);

is( $city->city_name => 'Denver' );

my ($state_plus) = My::Model->ad_hoc(
  sql => <<"SQL",
SELECT states.*, COUNT(*) AS city_count
FROM states
  INNER JOIN cities
    ON cities.state_id = states.state_id
WHERE states.state_name = ?
GROUP BY states.state_id
SQL
  args        => ['Colorado'],
  primary_key => 'state_id',
);

is( $state_plus->city_count => 1 );

eval {
  $state_plus->create( );
};
ok( $@ );
like $@ => qr/Cannot call 'create' on a /;

eval {
  $state_plus->update( );
};
ok( $@ );
like $@ => qr/Cannot call 'update' on a /;

eval {
  $state_plus->delete( );
};
ok( $@ );
like $@ => qr/Cannot call 'delete' on a /;


$state_plus->no_existo_rama;


