#!perl

use lib 'lib';
use Test2::V0 -target => 'Data::SCS::DefParser';

my $data = CLASS->new(
  mount => ['t/fixtures/class-city'],
  parse => 'city.sii',
)->data;

my $hornbrook = $data->{city}{hornbrook};
is $hornbrook->{city_name},        'Hornbrook',      'hornbrook city_name';
is $hornbrook->{country},          'california',     'hornbrook country';

my $los_angeles = $data->{city}{los_angeles};
is $los_angeles->{city_name},      'Los Angeles',    'los_angeles city_name';
is $los_angeles->{country},        'california',     'los_angeles country';
is $los_angeles->{population},     '3800000',        'los_angeles population';
is $los_angeles->{vehicle_brands}, ['kenworth'],     'los_angeles vehicle_brands';

done_testing;
