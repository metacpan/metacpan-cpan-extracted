#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests => 21;

package Foo;
use parent 'Class::Accessor::Complex';
__PACKAGE__->mk_new->mk_class_array_accessors(qw(an_array));

package main;
is(Foo->new->an_array_count, 0, 'count for new object');
my $o1 = Foo->new;
my $o2 = Foo->new;
$o1->an_array(5 .. 8);
my @o1 = $o1->an_array;
is_deeply(\@o1,              [ 5 .. 8 ],        'return array in list context');
is_deeply([ $o1->an_array ], [ $o2->an_array ], 'mirrored in other object');
$o1->an_array_push(9 .. 11);
is_deeply([ $o1->an_array ], [ 5 .. 11 ], 'after push',);
is($o1->an_array_count, 7, 'count after push');
is_deeply([ $o1->an_array ], [ $o2->an_array ], 'mirrored in other object');
my $el = $o1->an_array_shift;
is($el, 5, 'shifted element');
is_deeply([ $o1->an_array ], [ 6 .. 11 ], 'after shift',);
is($o1->count_an_array, 6, 'count after shift');
is_deeply([ $o1->an_array ], [ $o2->an_array ], 'mirrored in other object');
$el = $o1->an_array_pop;
is($el, 11, 'popped element');
is_deeply([ $o1->an_array ], [ 6 .. 10 ], 'after pop',);
is($o1->an_array_count, 5, 'count after pop');
is_deeply([ $o1->an_array ], [ $o2->an_array ], 'mirrored in other object');
my @gone = $o1->an_array_splice(1, 2, 19 .. 25);
is_deeply(\@gone, [ 7, 8 ], 'spliced elements');
is_deeply([ $o1->an_array ], [ 6, 19 .. 25, 9, 10 ], 'after splice',);
is($o1->an_array_count, 10, 'count after splice');
is_deeply([ $o1->an_array ], [ $o2->an_array ], 'mirrored in other object');
is($o1->an_array_index(0),                       6,  'index 0');
is($o1->index_an_array($o1->an_array_count - 1), 10, 'last element');
is_deeply([ $o1->an_array_index(2, 8, 3) ], [ 20, 9, 21 ], 'indices 2, 5, 3');
