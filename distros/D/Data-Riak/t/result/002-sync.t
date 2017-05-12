#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
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

my $bucket2 = Data::Riak::Bucket->new({
    name => $bucket_name,
    riak => $riak
});

is(exception {
    $bucket->add('foo', 'bar')
}, undef, '... got no exception adding element to the bucket');

my $obj = $bucket->get('foo');
isa_ok($obj, 'Data::Riak::Result');

is($obj->key, 'foo', '... the name of the item is foo');
is($obj->bucket_name, $bucket->name, '... the name of the bucket is as expected');
is($obj->location, ($obj->riak->base_uri . 'buckets/' . $bucket->name . '/keys/foo'), '... got the right location of the object');
is($obj->value, 'bar', '... the value is bar');

$bucket->add('foo', 'baz');

is(exception {
    $obj = $obj->sync;
}, undef, '... got no exception syncing an item');

is($obj->key, 'foo', '... the name of the item is foo');
is($obj->bucket_name, $bucket->name, '... the name of the bucket is as expected');
is($obj->location, ($obj->riak->base_uri . 'buckets/' . $bucket->name . '/keys/foo'), '... got the right location of the object');
is($obj->value, 'baz', '... the value is bar');

remove_test_bucket($bucket);

done_testing;
