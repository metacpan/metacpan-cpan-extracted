#!perl

use lib 'lib';
use Test2::V0 -target => 'Data::SCS::DefParser';

my $data = CLASS->new(
  mount => ['t/fixtures/include'],
  parse => 'include.sii',
)->raw_data;

is $data->{foo}{attr}, 'ok', 'include attribute, file name txt';
is $data->{bar}{unit}, 'ok', 'include unit block, file name sui';

ok dies { CLASS->new(
  mount => ['t/fixtures/include'],
  parse => 'missing.sii',
)->raw_data }, 'include file does not exist';

ok dies { CLASS->new(
  mount => ['t/fixtures/include'],
  parse => 'inline.sii',
)->raw_data }, 'inline include dies';

done_testing;
