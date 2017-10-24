#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 2;
use Set::Object;
use Data::Compare 0.06;

my $foo = {
    list => [qw(one two three)],
    set  => Set::Object->new( [1], [2], [3] ),
};
my $bar = {
    list => [qw(one two three)],
    set  => Set::Object->new( [1], [2], [3] ),
};

isnt $foo->{set}, $bar->{set}, 'set comparison';
ok Compare( $foo, $bar ), 'Data::Compare comparison';
