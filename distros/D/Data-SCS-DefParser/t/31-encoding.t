#!perl

use lib 'lib';
use Test2::V0 -target => 'Data::SCS::DefParser';

my $data = Data::SCS::DefParser->new(
  mount => ['t/fixtures/encoding'],
  parse => 'utf8.sii',
)->raw_data;

is $data->{utf8}{raw_bytes}{string}, "Gen\x{e8}ve", 'UTF-8 raw bytes';
is $data->{utf8}{x_escaped}{string}, "Gen\x{e8}ve", 'UTF-8 hex-escaped bytes';

like dies { Data::SCS::DefParser->new(
  mount => ['t/fixtures/encoding'],
  parse => 'magic.sii',
)->raw_data }, qr/SiiNunit/, 'unexpected magic dies';

like dies { Data::SCS::DefParser->new(
  mount => ['t/fixtures/encoding'],
  parse => 'block.sii',
)->raw_data }, qr/SiiNunit/, 'missing magic dies';

done_testing;
