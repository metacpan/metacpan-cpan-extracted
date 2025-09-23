#!perl

use lib 'lib';
use Test2::V0 -target => 'Data::SCS::DefParser';

my $data = CLASS->new(
  mount => ['t/fixtures/class-company'],
  parse => [qw( def/company.sii def/city.sii )],
)->data;

my $gal_oil_gst = $data->{company}{permanent}{gal_oil_gst};
is $gal_oil_gst->{name},         'Gallon Oil', 'gal_oil_gst name';
is $gal_oil_gst->{trailer_look}, 'gallon',     'gal_oil_gst trailer_look';

is $gal_oil_gst->{company_def}, [
  {
    city   => 'carlsbad',
    prefab => 'us_gas_06',
  },
], 'gal_oil_gst company_def';

done_testing;
