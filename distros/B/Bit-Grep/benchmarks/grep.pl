#!/usr/bin/perl

use strict;
use warnings;

use Bit::Grep qw(bg_grep);
use Benchmark qw(cmpthese);

my @a = 0..1000;

my $v = '';
vec($v, $_, 1) = (rand > .7) for 0..$#a;

sub native {
    my @s = @a[grep vec($v, $_, 1), 0..$#a];
}

sub module {
    my @s = bg_grep $v => @a;
}

cmpthese(-1, { native => \&native,
               module => \&module });
