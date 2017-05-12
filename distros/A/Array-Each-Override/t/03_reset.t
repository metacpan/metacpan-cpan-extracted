#! /usr/bin/perl

use strict;
use warnings;

use Test::More tests => 20;

use Array::Each::Override;

{
    my @numbers = qw<zero one two three four>;
    my ($i, $val) = each @numbers;
    is($i,   0,      'keys: iterated position 0');
    is($val, 'zero', 'keys: iterated value at position 0');
    is(scalar keys(@numbers), 5, 'keys: key count');
    ($i, $val) = each @numbers;
    is($i,   0,      'keys: iterated position 0 after reset');
    is($val, 'zero', 'keys: iterated value at position 0 after reset');
    ($i, $val) = each @numbers;
    is($i,   1,      'keys: iterated position 1 after reset');
    is($val, 'one',  'keys: iterated value at position 1 after reset');
}

{
    my @numbers = qw<zero one two three four>;
    my ($i, $val) = each @numbers;
    is($i,   0,      'values: iterated position 0');
    is($val, 'zero', 'values: iterated value at position 0');
    is(scalar values(@numbers), 5, 'values: value count');
    ($i, $val) = each @numbers;
    is($i,   0,      'values: iterated position 0 after reset');
    is($val, 'zero', 'values: iterated value at position 0 after reset');
    ($i, $val) = each @numbers;
    is($i,   1,      'values: iterated position 1 after reset');
    is($val, 'one',  'values: iterated value at position 1 after reset');
}

{
    my @numbers = qw<zero one two three four>;
    my @values = values @numbers;
    is("@values", "@numbers", "values: correct list");
}

{
    my @numbers = qw<zero one two three four>;
    my @keys = keys @numbers;
    is("@keys", '0 1 2 3 4', "keys: correct list");
}

{
    my $i = 0;
    my %hash = map { $_ => $i++ } qw<zero one two three four>;
    is(scalar keys(%hash), 5, 'hash scalar keys');
    is(scalar values(%hash), 5, 'hash scalar values');
    my @keys = sort keys(%hash);
    is("@keys", 'four one three two zero', 'hash list keys');
    my @values = sort values(%hash);
    is("@values", '0 1 2 3 4', 'hash list values');
}
