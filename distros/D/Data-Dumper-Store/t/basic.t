#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";

use Data::Dumper::Store;
use Test::More;

my $file = 'test.txt';

eval { Data::Dumper::Store->new() };
ok $@;

my $data = {
    key1 => 'val-1',
    key2 => 'val-2'
};

{
    ok my $store = Data::Dumper::Store->new(file => $file);

    ok $store->init($data);
    ok $store->get('key1');
    ok $store->get('key2');
    is_deeply $store->{data}, $data;
}

ok -e $file;

{
    ok my $store = Data::Dumper::Store->new(file => $file);
    is_deeply $store->{data}, $data;

    ok $store->set('key3', 'val-3');
    is $store->get('key3'), 'val-3';
    is $store->set('key3', 'val-4')->get('key3'), 'val-4';

    ok $store->commit();
}

ok -e $file;

{
    ok my $store = Data::Dumper::Store->new(file => $file);
    is $store->get('key3'), 'val-4';
}

my $struct = {
    cities => [
        {
            name    => 'Limassol',
            country => 'Cyprus',
            population => 'About 200k',
        },
        {
            name => 'Moscow',
            country => 'Russia',
            population => 'About 15M'
        }
    ]
};

{
    ok my $store = Data::Dumper::Store->new(file => $file);
    $store->init($struct);
}

{
    ok my $store = Data::Dumper::Store->new(file => $file);
    is_deeply $store->{data}, $struct;
}

{
    my $store = Data::Dumper::Store->new(file => $file);

}

unlink $file;


done_testing();