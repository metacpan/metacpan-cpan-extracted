#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

my @build_order;

{
    package A; sub BUILD { push @build_order, 'A'; }
    package B; use Class; extends 'A'; sub BUILD { push @build_order, 'B'; }
    package C; use Class; extends 'A'; sub BUILD { push @build_order, 'C'; }
    package D; use Class; extends qw/B C/; sub BUILD { push @build_order, 'D'; }
}

my $obj = D->new;

is_deeply(\@build_order, [qw/A B C D/], 'BUILD hooks called in correct order and only once');
done_testing;
