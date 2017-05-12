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

is(exception {
    $bucket->add('bar', 'value of bar', { links => [Data::Riak::Fast::Link->new( bucket => $bucket_name, riaktag => 'buddy', key =>'foo' )] });
    $bucket->add('baz', 'value of baz', { links => [$bucket->create_link( riaktag => 'buddy', key =>'foo' )] });
    $bucket->add('foo', 'value of foo', { links => [$bucket->create_link({ riaktag => 'not a buddy', key =>'bar' }), $bucket->create_link({ riaktag => 'not a buddy', key =>'baz' })] });
}, undef, '... no exception while adding links');

my $foo = $bucket->get('foo');
isa_ok($foo, 'Data::Riak::Fast::Result');

is(ref $foo->links, 'ARRAY', '... got an array ref');

my ($bar_link, $baz_link, $up_link) = @{ $foo->links };

my ($bar_link_header, $baz_link_header, $up_link_header) = map { $_->as_link_header } ($bar_link, $baz_link, $up_link);

isa_ok($bar_link, 'Data::Riak::Fast::Link');
is($bar_link->bucket, $bucket_name, '... got the right bucket');
is($bar_link->key, 'bar', '... got the right key');
is($bar_link->riaktag, 'not a buddy', '... got the right riaktag');

isa_ok($bar_link_header, 'HTTP::Headers::ActionPack::LinkHeader');
is($bar_link_header->href, ('/buckets/' . $bucket_name . '/keys/bar'), '... got the right href');
is($bar_link_header->params->{'riaktag'}, 'not+a+buddy', '... got the right riak tag (and it is url-encoded)');

isa_ok($baz_link, 'Data::Riak::Fast::Link');
is($baz_link->bucket, $bucket_name, '... got the right bucket');
is($baz_link->key, 'baz', '... got the right key');
is($baz_link->riaktag, 'not a buddy', '... got the right riaktag');

isa_ok($baz_link_header, 'HTTP::Headers::ActionPack::LinkHeader');
is($baz_link_header->href, ('/buckets/' . $bucket_name . '/keys/baz'), '... got the right href');
is($baz_link_header->params->{'riaktag'}, 'not+a+buddy', '... got the right riak tag (and it is url-encoded)');

isa_ok($up_link, 'Data::Riak::Fast::Link');
is($up_link->bucket, $bucket_name, '... got the right bucket');
ok(!$up_link->has_key, '... no key');
ok(!$up_link->has_riaktag, '... no riaktag');

isa_ok($up_link_header, 'HTTP::Headers::ActionPack::LinkHeader');
is($up_link_header->href, ('/buckets/' . $bucket_name), '... got the right href');
is($up_link_header->rel, 'up', '... got the right rel');

my $resultset = $foo->linkwalk([[ 'not a buddy', 1 ]]);
isa_ok($resultset, 'Data::Riak::Fast::ResultSet');

is(scalar @{$resultset->results}, 2, 'Got two Riak::Results back from linkwalking foo');

my ($buddy1, $buddy2) = $resultset->all;

isa_ok($buddy1, 'Data::Riak::Fast::Result');
is($buddy1->value, 'value of ' . $buddy1->key, '... go the right value');

{
    my ($foo_link, $up_link) = @{$buddy1->links};

    my ($foo_link_header, $up_link_header) = map { $_->as_link_header } ($foo_link, $up_link);

    isa_ok($foo_link, 'Data::Riak::Fast::Link');
    is($foo_link->bucket, $bucket_name, '... got the right bucket');
    is($foo_link->key, 'foo', '... got the right key');
    is($foo_link->riaktag, 'buddy', '... got the right riaktag');

    isa_ok($foo_link_header, 'HTTP::Headers::ActionPack::LinkHeader');
    is($foo_link_header->href, ('/buckets/' . $bucket_name . '/keys/foo'), '... got the right href');
    is($foo_link_header->params->{'riaktag'}, 'buddy', '... got the right riak tag');

    isa_ok($up_link, 'Data::Riak::Fast::Link');
    is($up_link->bucket, $bucket_name, '... got the right bucket');
    ok(!$up_link->has_key, '... no key');
    ok(!$up_link->has_riaktag, '... no riaktag');

    isa_ok($up_link_header, 'HTTP::Headers::ActionPack::LinkHeader');
    is($up_link_header->href, ('/buckets/' . $bucket_name), '... got the right href');
    is($up_link_header->rel, 'up', '... got the right rel');
}

isa_ok($buddy2, 'Data::Riak::Fast::Result');
is($buddy2->value, 'value of ' . $buddy2->key, '... go the right value');

{
    my ($foo_link, $up_link) = @{$buddy2->links};

    my ($foo_link_header, $up_link_header) = map { $_->as_link_header } ($foo_link, $up_link);

    isa_ok($foo_link, 'Data::Riak::Fast::Link');
    is($foo_link->bucket, $bucket_name, '... got the right bucket');
    is($foo_link->key, 'foo', '... got the right key');
    is($foo_link->riaktag, 'buddy', '... got the right riaktag');

    isa_ok($foo_link_header, 'HTTP::Headers::ActionPack::LinkHeader');
    is($foo_link_header->href, ('/buckets/' . $bucket_name . '/keys/foo'), '... got the right href');
    is($foo_link_header->params->{'riaktag'}, 'buddy', '... got the right riak tag');

    isa_ok($up_link, 'Data::Riak::Fast::Link');
    is($up_link->bucket, $bucket_name, '... got the right bucket');
    ok(!$up_link->has_key, '... no key');
    ok(!$up_link->has_riaktag, '... no riaktag');

    isa_ok($up_link_header, 'HTTP::Headers::ActionPack::LinkHeader');
    is($up_link_header->href, ('/buckets/' . $bucket_name), '... got the right href');
    is($up_link_header->rel, 'up', '... got the right rel');
}

remove_test_bucket($bucket);

done_testing;
