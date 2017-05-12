#!/usr/bin/env perl

use strict;
use Test::More;
use Cache::Meh;
use Digest::SHA qw(sha1);

plan tests => 2;

$ENV{TMPDIR} = '.';

my $cache = Cache::Meh->new(
    filename => 'blort',
    validity => 10, # seconds
    lookup => sub { 
        my $key = shift;
        return sha1($key);
    },
);

my $value = $cache->get('some_key');

isa_ok($cache, 'Cache::Meh', 'Object right type');
is(sha1('some_key'), $value, 'SHA matches');

