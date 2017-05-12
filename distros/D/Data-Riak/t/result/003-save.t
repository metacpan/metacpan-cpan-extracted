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

my $new_obj = $obj->save(new_value => 'baz');
is($obj->value, 'bar', '... the content was not changed');
is($new_obj->value, 'baz', '... the clone has the new content');
is($new_obj->key, 'foo', '... but still the same key');

my $obj2 = $bucket2->get('foo');
isa_ok($obj2, 'Data::Riak::Result');

is($obj2->key, 'foo', '... the name of the item is foo');
is($obj2->bucket_name, $bucket->name, '... the name of the bucket is as expected');
is($obj2->location, ($obj2->riak->base_uri . 'buckets/' . $bucket->name . '/keys/foo'), '... got the right location of the object');
is($obj2->value, 'baz', '... the updated value is baz');

remove_test_bucket($bucket);

done_testing;
