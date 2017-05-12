#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Data::Riak::Fast;

use Data::Riak::Fast;
use Data::Riak::Fast::Bucket;

skip_unless_riak;

my $bucket = Data::Riak::Fast::Bucket->new({
    name => create_test_bucket_name,
    riak => Data::Riak::Fast->new(transport => Data::Riak::Fast::HTTP->new)
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

isa_ok($obj->content_type, 'HTTP::Headers::ActionPack::MediaType');
is($obj->content_type->type, 'text/plain', '... got the right content type');

isa_ok($obj->last_modified, 'HTTP::Headers::ActionPack::DateHeader');

like($obj->etag, qr/^"[a-zA-Z0-9]*"$/, '... got an etag');
like($obj->vector_clock, qr/^.*\=$/, '... got a vector_clock');

is($obj->status_code, 200, '... got the right status code');
isa_ok($obj->http_message, 'HTTP::Message');

is($obj->riak, $bucket->riak, 'Derived host is correct');

remove_test_bucket($bucket);

done_testing;
