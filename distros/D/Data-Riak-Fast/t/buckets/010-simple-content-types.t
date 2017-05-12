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

$bucket->add('foo', '{"bar":1}', { content_type => 'application/json' });

{
    my $obj = $bucket->get('foo');
    is($obj->value, '{"bar":1}', 'Check the value immediately after insertion');

    is($obj->key, 'foo', "Name property is inflated correctly");
    is($obj->bucket_name, $bucket_name, "Bucket name property is inflated correctly");

    is($obj->content_type->type, 'application/json', '... got the right type');
}

try {
    $bucket->get('foo' => { accept => 'text/html' });
} catch {
    is($_->code, "406", "asking for an incompatible content type fails with a 406");
};

remove_test_bucket($bucket);

done_testing;




