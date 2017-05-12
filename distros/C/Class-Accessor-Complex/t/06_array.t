#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests => 17;

package Foo;
use parent 'Class::Accessor::Complex';
__PACKAGE__->mk_new->mk_array_accessors(qw(an_array));

package Bar;
use parent 'Class::Accessor::Complex';
__PACKAGE__->mk_new;

package main;
can_ok(
    'Foo', qw(
      an_array an_array_push an_array_pop an_array_unshift an_array_shift
      an_array_clear an_array_count an_array_set
      )
);
is(Foo->new->an_array_count, 0, 'count for new object');
my $o1 = Foo->new;
$o1->an_array(5 .. 8);
my @o1 = $o1->an_array;
is_deeply(\@o1, [ 5 .. 8 ], 'return array in list context');
$o1->an_array_push(9 .. 11);
is_deeply([ $o1->an_array ], [ 5 .. 11 ], 'after push',);
is($o1->an_array_count, 7, 'count after push');
my $el = $o1->an_array_shift;
is($el, 5, 'shifted element');
is_deeply([ $o1->an_array ], [ 6 .. 11 ], 'after shift',);
is($o1->count_an_array, 6, 'count after shift');
$el = $o1->an_array_pop;
is($el, 11, 'popped element');
is_deeply([ $o1->an_array ], [ 6 .. 10 ], 'after pop',);
is($o1->an_array_count, 5, 'count after pop');
my @gone = $o1->an_array_splice(1, 2, 19 .. 25);
is_deeply(\@gone, [ 7, 8 ], 'spliced elements');
is_deeply([ $o1->an_array ], [ 6, 19 .. 25, 9, 10 ], 'after splice',);
is($o1->an_array_count,                          10, 'count after splice');
is($o1->an_array_index(0),                       6,  'index 0');
is($o1->index_an_array($o1->an_array_count - 1), 10, 'last element');
is_deeply([ $o1->an_array_index(2, 8, 3) ], [ 20, 9, 21 ], 'indices 2, 5, 3');
