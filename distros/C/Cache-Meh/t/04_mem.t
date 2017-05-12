#!/usr/bin/env perl

use strict;
use Test::More;
use Cache::Meh;
use File::Spec::Functions qw(tmpdir catfile);

plan tests => 9;

my @test_values = qw(a b c d e 1 2 3);

my $cache = Cache::Meh->new(
    only_memory => 1,
    validity    => 1, # second
    lookup      => sub {
	    return shift @test_values
	},
);

isa_ok($cache, 'Cache::Meh', 'right object');
ok($cache->only_memory, 'only_memory set properly');
is($cache->get('bar'), 'a', 'got right value bar: a');
is($cache->get('foo'), 'b', 'got right value foo: b');

$cache->filename('test');

is($cache->filename(), 'test', 'got right filename');

my $fname = catfile(tmpdir(), $cache->filename());

isnt(-e $fname, 1, "$fname doesn't exist"); 

$cache->set('foo', 'qux');
isnt(-e $fname, 1, "$fname doesn't exist"); 
is($cache->get('foo'), 'qux', 'got right set value: qux');

sleep 1;

is($cache->get('foo'), 'c', 'got right value after expiration: c');





