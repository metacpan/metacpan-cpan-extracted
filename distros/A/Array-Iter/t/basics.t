#!perl

use strict;
use warnings;

use Array::Iter qw(list_iter array_iter);
use Test::More 0.98;

subtest array_iter => sub {
    my $iter = array_iter([1,2,3,4,5]);
    my @res; while (my $v = $iter->()) { push @res, $v }
    is_deeply(\@res, [1,2,3,4,5]);
};

subtest list_iter => sub {
    my $iter = list_iter(1,2,3,4,5);
    my @res; while (my $v = $iter->()) { push @res, $v }
    is_deeply(\@res, [1,2,3,4,5]);
};

done_testing;
