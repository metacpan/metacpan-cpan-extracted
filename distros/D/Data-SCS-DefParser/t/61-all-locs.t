#!perl

use lib 'lib';
use Test2::V0 -target => 'Data::SCS::DefParser';

my $parser = CLASS->new( mount => ['t/fixtures/class-company'] );

my %companies = (
  gal => { branches => ['gal_oil_gst'] },
);

is [my @locs = $parser->all_locations(\%companies)], [
  {
    branch  => 'gal_oil_gst',
    city    => 'carlsbad',
    company => 'gal',
    country => 'california',
    prefab  => 'us_gas_06',
  },
  {
    branch  => 'gal_oil_gst',
    city    => 'hornbrook',
    company => 'gal',
    country => 'california',
    prefab  => 'd_oil_gst',
  },
], 'all_locations';

is [$parser->all_locations(\%companies, $parser->data)], [@locs], 'all_locations with data';

is +($parser->all_locations)[0], {
  branch  => 'gal_oil_gst',
  city    => 'carlsbad',
  company => undef,
  country => 'california',
  prefab  => 'us_gas_06',
}, 'all_locations without company ids';

done_testing;
