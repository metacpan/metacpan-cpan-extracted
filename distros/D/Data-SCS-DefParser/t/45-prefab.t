#!perl

use lib 'lib';
use Test2::V0 -target => 'Data::SCS::DefParser';
no warnings 'experimental::builtin';

my $data = CLASS->new(
  mount => ['t/fixtures/class-prefab'],
  parse => 'prefab.sii',
)->data;

my $d_road_wrk2 = $data->{prefab}{d_road_wrk2};
is $d_road_wrk2->{allowed_trailer_length}, '25', 'd_road_wrk2 allowed_trailer_length';
is $d_road_wrk2->{disabled_depot}, 'd_road_wrk2c', 'd_road_wrk2 disabled_depot';
is $d_road_wrk2->{name}, 'tx_roadwork_01', 'd_road_wrk2 name';
is $d_road_wrk2->{prefab_desc}, '/prefab/roadwork/tx_roadwork_01.ppd', 'd_road_wrk2 prefab_desc';
is $d_road_wrk2->{running_timer}, '10000, 30000', 'd_road_wrk2 running_timer';

my $d_road_wrk2c = $data->{prefab}{d_road_wrk2c};
is $d_road_wrk2c->{name}, 'tx_roadwork_01_clear', 'd_road_wrk2c name';
is $d_road_wrk2c->{prefab_desc}, '/prefab/roadwork/tx_roadwork_clear_01.ppd', 'd_road_wrk2c prefab_desc';

my $us_gas_06 = $data->{prefab}{us_gas_06};
is $us_gas_06->{prefab_desc}, '/prefab/gas/nm_gas_station1_depot.ppd', 'us_gas_06 prefab_desc';
is $us_gas_06->{slow_time}, builtin::true, 'us_gas_06 slow_time';

done_testing;
