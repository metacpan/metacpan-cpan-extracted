#!/usr/bin/env perl

use strict;
use Test::More;
use Cache::Meh;

plan tests => 3;

$ENV{TMPDIR} = '.';

my $cache = Cache::Meh->new(
    filename => 'blort',
    validity => 1, 
);

sleep(2);

my $value = $cache->get('some_key');

isa_ok($cache, 'Cache::Meh', 'Object right type');
is($value, undef, '$value is undef');
is(exists $cache->{'~~~~cache'}->{'some_key'}, '', 'key is gone');


