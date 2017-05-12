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

my ($bar, $baz);
is(exception {
    $bar = $bucket->add('bar', 'value of bar', { query => { returnbody => 'true' } });
    $baz = $bucket->add('baz', 'value of baz', { query => { returnbody => 'true' } });
}, undef, '... no exception while items');

my $bar_link = $bar->create_link(riaktag => 'not a buddy');
my $baz_link = $baz->create_link(riaktag => 'not a buddy');

is(exception {
    $bucket->add('foo', 'value of foo', { links => [ $bar_link, $baz_link ] });
}, undef, '... no exception while items');

{
    my $foo = $bucket->get('foo');
    isa_ok($foo, 'Data::Riak::Fast::Result');

    my ($bar_link, $baz_link, $up_link) = @{$foo->links};

    isa_ok($bar_link, 'Data::Riak::Fast::Link');
    is($bar_link->bucket, $bucket_name, '... got the right bucket');
    is($bar_link->key, 'bar', '... got the right key');
    is($bar_link->riaktag, 'not a buddy', '... got the right riaktag');

    isa_ok($baz_link, 'Data::Riak::Fast::Link');
    is($baz_link->bucket, $bucket_name, '... got the right bucket');
    is($baz_link->key, 'baz', '... got the right key');
    is($baz_link->riaktag, 'not a buddy', '... got the right riaktag');

    isa_ok($up_link, 'Data::Riak::Fast::Link');
    is($up_link->bucket, $bucket_name, '... got the right bucket');
    ok(!$up_link->has_key, '... no key');
    ok(!$up_link->has_riaktag, '... no riaktag');

    my $resultset = $foo->linkwalk([[ 'not a buddy', 1 ]]);
    isa_ok($resultset, 'Data::Riak::Fast::ResultSet');

    is(scalar @{$resultset->results}, 2, 'Got two Riak::Results back from linkwalking foo');

    my ($buddy1, $buddy2) = $resultset->all;

    isa_ok($buddy1, 'Data::Riak::Fast::Result');
    is($buddy1->value, 'value of ' . $buddy1->key, '... go the right value');

    {
        my ($up_link) = @{$buddy1->links};

        isa_ok($up_link, 'Data::Riak::Fast::Link');
        is($up_link->bucket, $bucket_name, '... got the right bucket');
        ok(!$up_link->has_key, '... no key');
        ok(!$up_link->has_riaktag, '... no riaktag');
    }

    isa_ok($buddy2, 'Data::Riak::Fast::Result');
    is($buddy2->value, 'value of ' . $buddy2->key, '... go the right value');

    {
        my ($up_link) = @{$buddy2->links};

        isa_ok($up_link, 'Data::Riak::Fast::Link');
        is($up_link->bucket, $bucket_name, '... got the right bucket');
        ok(!$up_link->has_key, '... no key');
        ok(!$up_link->has_riaktag, '... no riaktag');
    }
}

remove_test_bucket($bucket);

done_testing;
