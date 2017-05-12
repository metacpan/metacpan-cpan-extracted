#!/bin/env perl

# Simulate the way that CHI is used.

use strict;
use warnings;
use Test::More;

eval { require CHI; };
plan skip_all => 'CHI not installed.' if $@;
plan 'no_plan';
import CHI;

my $cache = CHI->new(driver => 'File');
my $key   = join("|", ('Parcel Post', 'Germany', '5', 'Package'));
my $rate  = $cache->get($key);

if (not defined $rate) {
    sleep(1);
    $rate = '5.99';
    $cache->set($key, $rate, "30 minutes");
}

ok(1, 'CHI works as expected.');
