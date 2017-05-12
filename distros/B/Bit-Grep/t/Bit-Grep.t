#!/usr/bin/perl

use Test::More;
use List::Util qw(sum);
use Bit::Grep qw(bg_grep bg_sum);

for my $i (1..50) {
    my @a = (1..$i);
    my %h;
    $h{int rand @a} = 1 for 0..int rand @a;
    my @h = sort { $a <=> $b } keys %h;
    # diag "@h";
    my $v = '';
    vec($v, $_, 1) = 1 for @h;
    is_deeply([bg_grep $v, @a], [@a[@h]]);
    is(bg_sum($v, @a), sum(@a[@h]));
}

done_testing();
