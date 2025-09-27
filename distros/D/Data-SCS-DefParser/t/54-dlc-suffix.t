#!perl

use lib 'lib';
use Test2::V0 -target => 'Data::SCS::DefParser';

use Archive::SCS;

my $data = CLASS->new(
  mount => 't/fixtures/dlc-suffix',
)->raw_data;

my %blythe = $data->{city}{blythe}->%*;
is $blythe{city_name},    'Blythe',     'blythe city_name';
is $blythe{country},      'california', 'blythe country';

my %ehrenberg = $data->{city}{ehrenberg}->%*;
is $ehrenberg{city_name}, 'Ehrenberg',  'ehrenberg city_name';
is $ehrenberg{country},   'arizona',    'ehrenberg country';

{ my $todo = todo 'Archive::SCS mounts (an undocumented feature) currently do not work with DLC suffix';

my $scs = Archive::SCS->new;
$scs->mount('t/fixtures/dlc-suffix/def');
$scs->mount('t/fixtures/dlc-suffix/dlc_az');

ok CLASS->new(mount => $scs)->raw_data->{city}{ehrenberg}, 'dlc suffix via archive mount';

}

done_testing;
