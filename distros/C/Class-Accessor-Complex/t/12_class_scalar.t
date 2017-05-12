#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests => 5;

package Foo;
use parent 'Class::Accessor::Complex';
__PACKAGE__->mk_new->mk_class_scalar_accessors(qw(a_scalar));

package main;
can_ok(
    'Foo', qw(
      a_scalar a_scalar_clear
      )
);
my $o1 = Foo->new;
$o1->a_scalar(23);
my $o2 = Foo->new;
is($o1->a_scalar, 23, 'value present in first object');
is($o2->a_scalar, 23, 'value present in second object');
$o2->clear_a_scalar;
is($o1->a_scalar, undef, 'value undef in first object');
is($o2->a_scalar, undef, 'value undef in second object');
