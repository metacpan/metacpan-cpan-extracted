#!perl

use lib 'lib';
use Test2::V0 -target => 'Data::SCS::DefParser';

my $data = CLASS->new(
  mount => ['t/fixtures/unit-names'],
  parse => 'units.sii',
)->raw_data;

is $data->{single_cmpnt}, {single => 'ok'}, 'single component';
is $data->{two}{components}, {long => 'ok'}, 'long class name, two components';
is $data->{one}{two}{three}, {many => 'ok'}, 'three components';
is $data->{1}{2}{3}{456}, {digits => 'ok'}, 'digits';
is $data->{'a_1'}{'2a'}{'_3'}{'4_'}{'5_6a'}, {mixed => 'ok'}, 'mixed digits and non-digits';

is $data->{_class}{foo}{bar}, {nameless => 'ok'}, 'nameless unit deserialized with _class';

is CLASS->new(
  mount => ['t/fixtures/unit-names'],
  parse => 'case.sii',
)->raw_data->{UPPER}{Case}, {error => 1}, 'tokens cannot contain upper case chars';

is CLASS->new(
  mount => ['t/fixtures/unit-names'],
  parse => 'length.sii',
)->raw_data->{too_long_token}, {error => 1}, 'tokens cannot be longer than 12 chars';

like dies { CLASS->new(
  mount => ['t/fixtures/unit-names'],
  parse => 'hyphen.sii',
)->raw_data }, qr/hyphen-token/, 'tokens cannot contain hyphen';

done_testing;
