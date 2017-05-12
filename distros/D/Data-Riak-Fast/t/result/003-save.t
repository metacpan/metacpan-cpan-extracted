#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
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

my $bucket2 = Data::Riak::Fast::Bucket->new({
    name => $bucket_name,
    riak => $riak
});

is(exception {
    $bucket->add('foo', 'bar')
}, undef, '... got no exception adding element to the bucket');

my $obj = $bucket->get('foo');
isa_ok($obj, 'Data::Riak::Fast::Result');

is($obj->key, 'foo', '... the name of the item is foo');
is($obj->bucket_name, $bucket->name, '... the name of the bucket is as expected');
is($obj->location, ($obj->riak->base_uri . 'buckets/' . $bucket->name . '/keys/foo'), '... got the right location of the object');
is($obj->value, 'bar', '... the value is bar');

$obj->value('baz');
is($obj->value, 'baz', '... the content was changed');

is(exception {
    $obj->save;
}, undef, '... got no exception saving element in the bucket');

my $obj2 = $bucket2->get('foo');
isa_ok($obj2, 'Data::Riak::Fast::Result');

is($obj2->key, 'foo', '... the name of the item is foo');
is($obj2->bucket_name, $bucket->name, '... the name of the bucket is as expected');
is($obj2->location, ($obj2->riak->base_uri . 'buckets/' . $bucket->name . '/keys/foo'), '... got the right location of the object');
is($obj2->value, 'baz', '... the updated value is baz');

remove_test_bucket($bucket);

done_testing;
