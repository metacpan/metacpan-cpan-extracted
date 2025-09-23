#!perl

use lib 'lib';
use Test2::V0 -target => 'Data::SCS::DefParser';

ok $Data::SCS::DefParser::tidy, 'tidy on by default';

{
  # tidy: skip currently useless clutter
  my %fixture = ( mount => ['t/fixtures/class-city'], parse => 'city.sii' );
  is scalar CLASS->new(%fixture)->data->{city}{hornbrook}{map_x_offsets}->@*, 0,
    'map_x_offsets, tidy on';
  local $Data::SCS::DefParser::tidy = 0;
  is scalar CLASS->new(%fixture)->data->{city}{hornbrook}{map_x_offsets}->@*, 8,
    'map_x_offsets, tidy off';

  %fixture = ( mount => ['t/fixtures/class-prefab'], parse => 'prefab.sii' );
  local $Data::SCS::DefParser::tidy = 1;
  is CLASS->new(%fixture)->data->{prefab}{us_gas_06}{detail_veg_max_distance}, undef,
    'detail_veg_max_distance, tidy on';
  local $Data::SCS::DefParser::tidy = 0;
  is CLASS->new(%fixture)->data->{prefab}{us_gas_06}{detail_veg_max_distance}, 25,
    'detail_veg_max_distance, tidy off';
}

{
  # tidy: fix data errors (leftovers from earlier versions etc.)
  my %fixture = ( mount => ['t/fixtures/tidy'], parse => 'mcs.sii' );
  is CLASS->new(%fixture)->data->{company}{permanent}{mcs_con_sit}, undef,
    'mcs_con_sit, tidy on';
  local $Data::SCS::DefParser::tidy = 0;
  is ref CLASS->new(%fixture)->data->{company}{permanent}{mcs_con_sit}, 'HASH',
    'mcs_con_sit, tidy off';
}

{
  # tidy: remove prefab data, except for that of company depots
  my %fixture = (
    mount => [qw( t/fixtures/class-company t/fixtures/class-prefab )],
    parse => [qw( def/company.sii prefab.sii )],
  );
  is CLASS->new(%fixture)->data->{prefab}{d_road_wrk2}, undef,
    'unused prefabs, tidy on';
  local $Data::SCS::DefParser::tidy = 0;
  is ref CLASS->new(%fixture)->data->{prefab}{d_road_wrk2}, 'HASH',
    'unused prefabs, tidy off';
}

done_testing;
