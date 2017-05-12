#! /usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;

use Array::Each::Override;

is(count_array([]), 0, 'iterate empty array');
is(count_array([1]), 1, 'iterate single-element array');

my @numbers = qw<zero one two three four>;
{
    my @numbers_copy = @numbers;
    while (my ($i, $val) = each @numbers_copy) {
        is($val, $numbers[$i], "correct iterated value at pos $i");
    }
    while (my ($i, $val) = each @numbers_copy) {
        is($val, $numbers[$i], "correct repeat iterated values at pos $i");
    }
}

sub count_array {
    my ($array) = @_;
    my $keys = 0;
    while (my ($i, $val) = each @$array) {
        $keys++;
    }
    return $keys;
}
