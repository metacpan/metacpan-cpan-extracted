#!/usr/bin/env perl

use strict;
use warnings;

use Try::Tiny;

use Test::More;
use Test::Fatal;
use Test::Data::Riak::Fast;

BEGIN {
    skip_unless_riak;
    use_ok('Data::Riak::Fast::Link');
}

use Data::Riak::Fast;

my $riak = Data::Riak::Fast->new(transport => Data::Riak::Fast::HTTP->new);
my $bucket_name = create_test_bucket_name;
my $bucket = $riak->bucket( $bucket_name );

{
    $bucket->add('foo', 'bar', {
        links => [
            Data::Riak::Fast::Link->new(
                bucket => $bucket->name,
                riaktag => 'buddy',
                key => 'baz'
            ),
            Data::Riak::Fast::Link->new(
                bucket => $bucket->name,
                riaktag => 'buddy',
                key => 'bazzo'
            ),
            Data::Riak::Fast::Link->new(
                bucket => $bucket->name,
                riaktag => 'buddy',
                key => 'qux'
            ),
            Data::Riak::Fast::Link->new(
                bucket => $bucket->name,
                riaktag => 'best buddy',
                key => 'baz'
            ),
        ]
    });

    my $foo = $bucket->get('foo');
    $foo->remove_link({ key => 'qux' })->save;
    my $server_foo = $bucket->get('foo');

    is(scalar @{$server_foo->links}, '4', '... three manual links plus the "up"');
    $bucket->remove('foo');
}

{
    $bucket->add('foo', 'bar', {
        links => [
            Data::Riak::Fast::Link->new(
                bucket => $bucket->name,
                riaktag => 'buddy',
                key => 'baz'
            ),
            Data::Riak::Fast::Link->new(
                bucket => $bucket->name,
                riaktag => 'buddy',
                key => 'bazzo'
            ),
            Data::Riak::Fast::Link->new(
                bucket => $bucket->name,
                riaktag => 'buddy',
                key => 'qux'
            ),
            Data::Riak::Fast::Link->new(
                bucket => $bucket->name,
                riaktag => 'best buddy',
                key => 'baz'
            ),
        ]
    });

    my $foo = $bucket->get('foo');
    $foo->remove_link({ riaktag => 'buddy' })->save;
    my $server_foo = $bucket->get('foo');

    is(scalar @{$server_foo->links}, '2', '... one manual link plus the "up"');
    $bucket->remove('foo');
}

{
    $bucket->add('foo', 'bar', {
        links => [
            Data::Riak::Fast::Link->new(
                bucket => $bucket->name,
                riaktag => 'buddy',
                key => 'baz'
            ),
            Data::Riak::Fast::Link->new(
                bucket => $bucket->name,
                riaktag => 'buddy',
                key => 'bazzo'
            ),
            Data::Riak::Fast::Link->new(
                bucket => $bucket->name,
                riaktag => 'buddy',
                key => 'qux'
            ),
            Data::Riak::Fast::Link->new(
                bucket => $bucket->name,
                riaktag => 'best buddy',
                key => 'baz'
            ),
        ]
    });

    my $foo = $bucket->get('foo');
    $foo->remove_link({ riaktag => 'best buddy', key => 'qux '})->save;
    my $server_foo = $bucket->get('foo');

    is(scalar @{$server_foo->links}, '4', '... all four manual links plus the "up"');
    $bucket->remove('foo');
}


remove_test_bucket($bucket);

done_testing;


