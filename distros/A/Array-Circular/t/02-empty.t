#!/usr/bin/env perl
use warnings;
use strict;
use Array::Circular;
use Test::More;

my $a = Array::Circular->new;

subtest 'empty loop' => sub  {
    for ( 1 .. 10) {
	ok ! $a->next, "Value is undefined";
	is $a->me->{current}, 0, "Current index is 0";
	is $a->me->{loops}, undef, "Can't go round an empty thing";
    }   
};

subtest 'mutate empty into single value list' => sub {
    push @$a, 'stuff';
    is $a->current, 'stuff', "current entry now first element";
    for (1 .. 10) {
	is $a->next, 'stuff', "got only value";
	is $a->me->{current}, 0, "got only index";
	is $a->loops, $_, "Been around $_ times";
    }
};

subtest 'add another element and see what happens' => sub {
    push @$a, 'more stuff';
    is $a->previous, 'more stuff', 'picked up on new contents straight away';
    is $a->loops, 9, "Been around 9 times as we went back one";
};

done_testing;
