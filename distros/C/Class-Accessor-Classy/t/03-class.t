#!/usr/bin/perl

use warnings;
use strict;

use Test::More 'no_plan';

BEGIN {
  eval {require Class::Accessor::Classy};
  ok(!$@);
}

{
  package Foo;
  use Class::Accessor::Classy;
  ro bip => 'bop';
  ro_c fee => 'FEE';
  ro_c fie => 'FIE';
  ro_c foe => 'FOE';
  rw_c foo => 'FOO';
  rw_c bar => 'BAR';
  rw_c baz => 'BAZ';
  no  Class::Accessor::Classy;
}
ok(Foo->isa('Foo::--accessors'), 'isa Foo::--accessors');
can_ok('Foo',
  map({$_} qw(fee fie foe foo bar baz)),
  map({'set_' . $_} qw(foo bar baz))
);
is(Foo->$_, uc($_), "look $_") for(qw(fee fie foe foo bar baz));
for my $n (qw(foo bar baz)) {
  my $setter = 'set_' . $n;
  Foo->$setter($n);
  is(Foo->$n, $n, "setter $n");
  Foo->$setter(uc($n));
  is(Foo->$n, uc($n), "setter $n");
}

{
  package Deal;
  use Class::Accessor::Classy;
  rs_c g => \ (my $set_g) => 'g';
  my $set_h = rs_c 'h' => 'h';
  my ($set_i, $set_j) = rs_c i => 'i', j => 'j';
  no  Class::Accessor::Classy;
  package main;
  is($set_g, '--set_g');
  is($set_h, '--set_h');
  is($set_i, '--set_i');
  is($set_j, '--set_j');
  can_ok('Deal',
    map({$_, '--set_' . $_} qw(g h i j))
  );
  is(Deal->$_, $_, "look $_") for(qw(g h i j));
  Deal->$set_g('G');
  Deal->$set_h('H');
  Deal->$set_j('J');
  Deal->$set_i('I');
  is($set_g, '--set_g');
  is($set_h, '--set_h');
  is($set_i, '--set_i');
  is($set_j, '--set_j');
  is(Deal->$_, uc($_), "set $_") for(qw(g h i j));
}

# vi:ts=2:sw=2:et:sta
