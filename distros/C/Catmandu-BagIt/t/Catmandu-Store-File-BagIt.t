#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Store::File::BagIt';
    use_ok $pkg;
}

require_ok $pkg;

dies_ok {$pkg->new} 'dies ok on not enough parameters';

my $store = $pkg->new(root => 't/data2', keysize => 9);

ok $store , 'got a store';

my $bags = $store->bag();

ok $bags , 'store->bag()';

isa_ok $bags , 'Catmandu::Store::File::BagIt::Index';

is $store->path_string('1234'), 't/data2/000/001/234', 'path_string(1234)';

is $store->path_string('0001234'), 't/data2/000/001/234',
    'path_string(0001234)';

ok !$store->path_string('00000001234'), 'path_string(00000001234) fails';

ok !$store->bag('1235') , 'bag(1235) doesnt exist';

lives_ok {$store->bag('1')} 'bag(1) exists';

dies_ok sub {
    $pkg->new(root => 't/data2', keysize => 13);
}, 'dies on wrong keysize';

lives_ok sub {
    $pkg->new(root => 't/data2', keysize => 12);
}, 'dies on connecting to a store with the wrong keysize';

note("uuid upper");
{
    my $store = $pkg->new(root => 't/data3', uuid => 1);

    ok $store , 'got a store';

    my $bags = $store->bag();

    ok $bags , 'store->bag()';

    isa_ok $bags , 'Catmandu::Store::File::BagIt::Index';

    is $store->path_string('7D9DEBD0-3B84-11E9-913F-EA3D2282636C')
            , 't/data3/7D9/DEB/D0-/3B8/4-1/1E9/-91/3F-/EA3/D22/826/36C'
            , 'path_string(7D9DEBD0-3B84-11E9-913F-EA3D2282636C)';

    ok ! $store->path_string('7D9DEBD') , 'path_string(7D9DEBD) fails';

    ok !$store->bag('7D9DEBD') , 'bag(1235) doesnt exist';

    lives_ok {$store->bag('7D9DEBD0-3B84-11E9-913F-EA3D2282636C')} 'bag(7D9DEBD0-3B84-11E9-913F-EA3D2282636C) exists';
}

note("uuid lower");
{
    my $store = $pkg->new(root => 't/data3', uuid => 1, default_case => 'lower');

    ok $store , 'got a store';

    my $bags = $store->bag();

    ok $bags , 'store->bag()';

    isa_ok $bags , 'Catmandu::Store::File::BagIt::Index';

    is $store->path_string('7D9DEBD0-3B84-11E9-913F-EA3D2282636C')
            , 't/data3/7d9/deb/d0-/3b8/4-1/1e9/-91/3f-/ea3/d22/826/36c'
            , 'path_string(7D9DEBD0-3B84-11E9-913F-EA3D2282636C)';

    ok ! $store->path_string('7D9DEBD') , 'path_string(7D9DEBD) fails';

    ok !$store->bag('7D9DEBD') , 'bag(1235) doesnt exist';

    lives_ok {$store->bag('7D9DEBD0-3B84-11E9-913F-EA3D2282636C')} 'bag(7D9DEBD0-3B84-11E9-913F-EA3D2282636C) exists';
}

done_testing;
