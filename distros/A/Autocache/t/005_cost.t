#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use Autocache qw(autocache);

Autocache->initialise(filename => 't/005_cost.t.conf');

my @numbers = (1, 2);
sub cheap {
    return shift @numbers;
}

my @more_numbers = (1, 2);
sub expensive {
    sleep 2;
    return shift @more_numbers;
}

autocache 'cheap';
autocache 'expensive';

is(cheap(), 1, 'First cheap() gives first item in list');
is(cheap(), 2, 'Second cheap() gives second item in list');
is(expensive(), 1, 'First expensive() gives first item in list');
is(expensive(), 1, 'Second expensive() gives cached first item in list');
