#!perl

use lib 'lib';
use Test2::V0 -target => 'Data::SCS::DefParser';

my $data = CLASS->new(
  mount => 't/fixtures/dlc-suffix',
)->raw_data;

my %blythe = $data->{city}{blythe}->%*;
is $blythe{city_name},    'Blythe',     'blythe city_name';
is $blythe{country},      'california', 'blythe country';

my %ehrenberg = $data->{city}{ehrenberg}->%*;
is $ehrenberg{city_name}, 'Ehrenberg',  'ehrenberg city_name';
is $ehrenberg{country},   'arizona',    'ehrenberg country';

done_testing;
