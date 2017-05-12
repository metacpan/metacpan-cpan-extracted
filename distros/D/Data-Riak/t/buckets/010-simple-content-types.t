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

$bucket->add('foo', '{"bar":1}', { content_type => 'application/json' });

{
    my $obj = $bucket->get('foo');
    is($obj->value, '{"bar":1}', 'Check the value immediately after insertion');

    is($obj->key, 'foo', "Name property is inflated correctly");
    is($obj->bucket_name, $bucket_name, "Bucket name property is inflated correctly");

    is($obj->content_type->type, 'application/json', '... got the right type');
}

my $e = exception { $bucket->get('foo' => { accept => 'text/html' }) };
isa_ok $e, 'Data::Riak::Exception::ClientError';
is $e->transport_response->code, 406,
    'asking for an incompatible content type fails with a 406';

remove_test_bucket($bucket);

done_testing;




