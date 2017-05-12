#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Data::Riak::Fast;

use Data::Riak::Fast;
use Data::Riak::Fast::Bucket;

BEGIN {
    skip_unless_riak;
    skip_unless_leveldb;
}

my $riak = Data::Riak::Fast->new(transport => Data::Riak::Fast::HTTP->new);

my $bucket_name = create_test_bucket_name;
my $bucket = Data::Riak::Fast::Bucket->new({
    name => $bucket_name,
    riak => $riak
});

is($bucket->count, 0, 'No keys in the bucket');

my $foo_user_data = '{"username":"foo","email":"foo@example.com","name_first":"Foo","name_last":"Fooly"';
my $bar_user_data = '{"username":"bar","email":"bar@example.com","name_first":"Bar","name_last":"Barly"';
my $baz_user_data = '{"username":"baz","email":"baz@example.net","name_first":"Baz","name_last":"Barly"';

$bucket->add(
    'foo-uuid',
    $foo_user_data,
    {
        indexes => [
            { field => 'email_bin', values => [ 'foo@example.com', 'example.com' ]},
            { field => 'username_bin', values => [ 'foo' ]},
            { field => 'name_bin', values => [ 'Foo', 'Fooly', 'Foo Fooly' ]}
        ]
    }
);

is($bucket->count, 1, '1 keys in the bucket');

$bucket->add(
    'bar-uuid',
    $bar_user_data,
    {
        indexes => [
            { field => 'email_bin', values => [ 'bar@example.com', 'example.com' ]},
            { field => 'username_bin', values => [ 'bar' ]},
            { field => 'name_bin', values => [ 'Bar', 'Barly', 'Bar Barly' ]}
        ]
    }
);

is($bucket->count, 2, '2 keys in the bucket');

$bucket->add(
    'baz-uuid',
    $baz_user_data,
    {
        indexes => [
            { field => 'email_bin', values => [ 'baz@example.net', 'example.net' ]},
            { field => 'username_bin', values => [ 'baz' ]},
            { field => 'name_bin', values => [ 'Baz', 'Barly', 'Baz Barly' ]}
        ]
    }
);

is($bucket->count, 3, '3 keys in the bucket');

my $search;
$search = $bucket->pretty_search_index({ field => 'email_bin', values => 'example.com' });
is_deeply(
    $search,
    [ 'bar-uuid', 'foo-uuid' ],
    '... example.com search returns the expected results'
);

$search = $bucket->pretty_search_index({ field => 'username_bin', values => 'baz' });
is_deeply(
    $search,
    [ 'baz-uuid' ],
    '... username search for baz returns the expected results'
);

$search = $bucket->pretty_search_index({ field => 'name_bin', values => 'Foo Fooly' });
is_deeply(
    $search,
    [ 'foo-uuid' ],
    '... name search returns the expected results'
);

$search = $bucket->pretty_search_index({ field => 'name_bin', values => 'Barly' });
is_deeply(
    $search,
    [ 'bar-uuid', 'baz-uuid' ],
    '... last name search returns the expected results'
);

remove_test_bucket($bucket);

done_testing;
