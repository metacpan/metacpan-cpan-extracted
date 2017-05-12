#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Data::Riak::Fast;

use Data::Riak::Fast;
use Data::Riak::Fast::Bucket;

skip_unless_riak;

my $riak = Data::Riak::Fast->new(transport => Data::Riak::Fast::HTTP->new);

my $bucket_name = create_test_bucket_name;
my $bucket_name2 = create_test_bucket_name;

my $bucket = Data::Riak::Fast::Bucket->new({
    name => $bucket_name,
    riak => $riak
});

my $bucket2 = Data::Riak::Fast::Bucket->new({
    name => $bucket_name2,
    riak => $riak
});

is($bucket->count, 0, 'No keys in the bucket');
is($bucket2->count, 0, 'No keys in the bucket');

my $foo_user_data = '{"username":"foo","email":"foo@example.com"';
$bucket->add('123456', $foo_user_data);

$bucket->create_alias({ key => '123456', as => 'foo' });
$bucket->create_alias({ key => '123456', as => 'foo', in => $bucket2 });

my $obj = $bucket->get('123456');
my $resolved_obj = $bucket->resolve_alias('foo');
my $resolved_across_buckets_obj = $bucket2->resolve_alias('foo');

is($obj->value, $foo_user_data, "Calling for foo's data by ID works");
is($resolved_obj->value, $foo_user_data, "Calling for foo's data by alias works");
is($resolved_across_buckets_obj->value, $foo_user_data, "Calling for foo's data by a cross-bucket alias works");

remove_test_bucket($bucket);
remove_test_bucket($bucket2);

done_testing;
