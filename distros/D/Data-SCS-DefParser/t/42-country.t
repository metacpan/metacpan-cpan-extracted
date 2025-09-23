#!perl

use lib 'lib';
use Test2::V0 -target => 'Data::SCS::DefParser';

my $data = CLASS->new(
  mount => ['t/fixtures/class-country'],
  parse => 'country.sii',
)->data;

my $ca = $data->{country}{data}{california};
is $ca->{country_code},     'CA',             'country_code';
is $ca->{country_id},       '1',              'country_id';
is $ca->{iso_country_code}, 'usca',           'iso_country_code';
is $ca->{name},             'California',     'name';
is $ca->{name_localized},   '@@california@@', 'name_localized';

done_testing;
