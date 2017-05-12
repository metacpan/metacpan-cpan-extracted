#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests => 7;

package Test01;
use parent 'Class::Accessor::Complex';
__PACKAGE__->mk_new->mk_scalar_accessors(qw(method1));

package Test02;
use parent 'Class::Accessor::Complex';
__PACKAGE__->mk_new->mk_scalar_accessors(qw(method2 method3));

package Foo;
use parent 'Class::Accessor::Complex';
__PACKAGE__->mk_object_accessors(
    Test01 => 'comp1',
    Test02 => 'comp2',
  )->mk_forward_accessors(
    comp1 => 'method1',
    comp2 => [qw(method2 method3)],
  );

package main;
can_ok(
    'Foo', qw(
      comp1 comp2 method1 method2 method3
      )
);
my $o = Foo->new;
isa_ok($o->comp1, 'Test01');
isa_ok($o->comp2, 'Test02');
$o->method1(234);
is($o->comp1->method1, 234, 'method1 forward');
$o->method2(567);
is($o->comp2->method2, 567, 'method2 forward');
$o->method3('abc');
is($o->comp2->method3, 'abc', 'method3 forward');
is($o->comp2->method2, 567,   'method2 unchanged');
