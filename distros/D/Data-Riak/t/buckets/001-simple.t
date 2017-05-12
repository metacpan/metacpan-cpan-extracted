#!/usr/bin/env perl

use strict;
use warnings;

use Try::Tiny;

use Test::Fatal;
use Test::More;
use Test::Data::Riak;

use Data::Riak;
use Data::Riak::Bucket;

skip_unless_riak;

my $riak = riak_transport;
my $bucket_name = create_test_bucket_name;

my $bucket = Data::Riak::Bucket->new({
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

my $e = exception { $bucket->get('foo' => { accept => 'application/json' }) };
ok $e, 'asking for an incompatible content type fails';
isa_ok $e, 'Data::Riak::Exception::ClientError';
is $e->transport_response->code, 406,
    'asking for an incompatible content type fails with a 406';

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
    isa_ok $_, 'Data::Riak::Exception::ObjectNotFound';
    like $_, qr/Object not found/;
    isa_ok $_->request, 'Data::Riak::Request::GetObject';
    is $_->request->bucket_name, $bucket_name;
    is $_->request->key, 'foo';
    is $_->transport_response->code, "404",
        "Calling for a value that doesn't exist returns 404";
};

{
    sleep 5;
    my $res;
    is exception { $res = $bucket->remove('foo') }, undef,
        'removing a non-existent key is non-fatal';
    ok !$res->first->has_vector_clock, 'no vclock when removing missing keys';
}

$bucket->add('bar', 'value of bar', { links => [Data::Riak::Link->new( bucket => $bucket_name, riaktag => 'buddy', key =>'foo' )] });
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
isa_ok($resultset, 'Data::Riak::ResultSet');
is(scalar @{$resultset->results}, 2, 'Got two Riak::Results back from linkwalking foo');

my $dw_results = $bucket->linkwalk('bar', [ [ 'buddy', '_' ], [ $bucket_name, 'not a buddy', '_' ] ]);
is(scalar $dw_results->all, 2, 'Got two Riak::Results back from linkwalking bar');

{
    ok +(grep { $_ eq $bucket_name } @{ $riak->_buckets }),
       '_buckets lists our new bucket';
}

remove_test_bucket($bucket);

done_testing;




