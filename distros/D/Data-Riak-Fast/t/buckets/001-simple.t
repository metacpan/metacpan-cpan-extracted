#!/usr/bin/env perl

use strict;
use warnings;

use Try::Tiny;

use Test::Fatal;
use Test::More;
use Test::Data::Riak::Fast;

use Data::Riak::Fast;
use Data::Riak::Fast::Bucket;

skip_unless_riak;

my $riak = Data::Riak::Fast->new(transport => Data::Riak::Fast::HTTP->new);
my $bucket_name = create_test_bucket_name;

my $bucket = Data::Riak::Fast::Bucket->new({
    name => $bucket_name,
    riak => $riak
});

is($bucket->count, 0, 'No keys in the bucket');

my $props = $bucket->props;
is(ref $props, 'HASH', '... got back a HASH ref');

$bucket->add('foo', 'bar');

my $obj = $bucket->get('foo');
is($obj->value, 'bar', 'Check the value immediately after insertion');

is($obj->key, 'foo', "Name property is inflated correctly");
is($obj->bucket_name, $bucket_name, "Bucket name property is inflated correctly");

try {
    $bucket->get('foo' => { accept => 'application/json' });
} catch {
    is($_->code, "406", "asking for an incompatible content type fails with a 406");
};

is_deeply(
    $bucket->list_keys,
    ['foo'],
    '... got the keys we expected'
);

is($bucket->count, 1, 'One key in the bucket');

$bucket->remove('foo');
try {
    $bucket->get('foo')
} catch {
    is($_->value, "not found\n", "Calling for a value that doesn't exist returns not found");
    is($_->code, "404", "Calling for a value that doesn't exist returns 404");
};

$bucket->add('bar', 'value of bar', { links => [Data::Riak::Fast::Link->new( bucket => $bucket_name, riaktag => 'buddy', key =>'foo' )] });
$bucket->add('baz', 'value of baz', { links => [$bucket->create_link( riaktag => 'buddy', key =>'foo' )] });
$bucket->add('foo', 'value of foo', { links => [$bucket->create_link({ riaktag => 'not a buddy', key =>'bar' }), $bucket->create_link({ riaktag => 'not a buddy', key =>'baz' })] });

is_deeply(
    [ sort @{ $bucket->list_keys } ],
    ['bar', 'baz', 'foo'],
    '... got the keys we expected'
);

is($bucket->count, 3, 'Three keys in the bucket');

my $foo = $bucket->get('foo');
my $bar = $bucket->get('bar');
my $baz = $bucket->get('baz');

is($foo->value, 'value of foo', 'correct value for foo');
is($bar->value, 'value of bar', 'correct value for bar');
is($baz->value, 'value of baz', 'correct value for baz');

my $resultset = $bucket->linkwalk('foo', [[ 'not a buddy', '_' ]]);
isa_ok($resultset, 'Data::Riak::Fast::ResultSet');
is(scalar @{$resultset->results}, 2, 'Got two Riak::Results back from linkwalking foo');

my $dw_results = $bucket->linkwalk('bar', [ [ 'buddy', '_' ], [ $bucket_name, 'not a buddy', '_' ] ]);
is(scalar $dw_results->all, 2, 'Got two Riak::Results back from linkwalking bar');

remove_test_bucket($bucket);

done_testing;




