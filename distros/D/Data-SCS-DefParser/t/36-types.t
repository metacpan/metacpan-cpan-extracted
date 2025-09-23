#!perl

use v5.36;
use lib 'lib';
use Test2::V0 -target => 'Data::SCS::DefParser';

my $values = CLASS->new(
  mount => ['t/fixtures/types'],
  parse => 'values.sii',
)->raw_data;

is $values->{types}{string}, 'String value', 'string';

is $values->{types}{float_f}, 1.23, 'float, decimal notation';
is $values->{types}{float_e}, -.62e+4, 'float, scientific notation';
is $values->{types}{float_b}, 1, 'float, binary32 notation';

is $values->{types}{float2}, '1, 2.4', 'float2';
is $values->{types}{float3}, '1, 0.54, 3.875', 'float3';
is $values->{types}{float4}, '1, 5.4, 3, 9', 'float4';

is $values->{types}{fixed}, 10, 'fixed';
is $values->{types}{signed}, -15, 'signed';

is $values->{types}{fixed2}, '20, 69', 'fixed2';
is $values->{types}{fixed3}, '10, 22, 33', 'fixed3';
is $values->{types}{fixed4}, '10, 22, 33, 44', 'fixed4';

no warnings 'experimental::builtin';
is $values->{types}{true}, builtin::true, 'true';
is $values->{types}{false}, builtin::false, 'false';

is $values->{types}{token}, 'value', 'token';
is $values->{types}{owner_ptr}, '.some.nameless.unit', 'owner pointer';
is $values->{types}{link_ptr}, 'some.named.unit', 'link pointer';
is $values->{types}{resource_tie}, 'path/to/some/resource.pma', 'resource tie';

is $values->{types}{hex}, '685FAF', 'hex';

like dies { CLASS->new(
  mount => ['t/fixtures/types'],
  parse => 'unknown-value.sii',
)->raw_data }, qr/value format/, 'unknown value format';

my $arrays = CLASS->new(
  mount => ['t/fixtures/types'],
  parse => 'arrays.sii',
)->raw_data;

is $arrays->{types}{array}, [qw( one two three )], 'array, dynamic';
is $arrays->{types}{fixed}, [qw( value value2 )], 'array, fixed-length';
is $arrays->{types}{empty}, 0, 'array, zero-length';
is $arrays->{types}{index}, [undef, qw( one two )], 'array, with index';

like dies { CLASS->new(
  mount => ['t/fixtures/types'],
  parse => 'unknown-type.sii',
)->raw_data }, qr/data format/, 'unknown data format';

done_testing;
