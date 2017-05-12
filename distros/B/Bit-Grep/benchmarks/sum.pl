#!/usr/bin/perl

use strict;
use warnings;

use Bit::Grep qw(bg_sum);
use Benchmark qw(cmpthese);
use List::Util qw(sum);

my @a = 0..1000;

my $v = '';
vec($v, $_, 1) = (rand > .7) for 0..$#a;

sub native {
    my $s = 0;
    vec($v, $_, 1) and $s += $a[$_] for 0..$#a;
}

sub native_lu {
    my $s = sum @a[grep vec($v, $_, 1), 0..$#a];
}

sub module {
    my $s = bg_sum $v => @a;
}

cmpthese(-1, { native    => \&native,
               native_lu => \&native_lu,
               module    => \&module });
