#!/usr/bin/perl

use warnings;
use strict;

use Test::More qw(no_plan);

{
  package bar;
  use Class::Accessor::Classy;
  with 'new';
  lv 'foo';
  no  Class::Accessor::Classy;
}

{
my $bar = bar->new(foo => 2);
isa_ok($bar, 'bar');
can_ok($bar, 'foo');

is($bar->foo, 2);
is($bar->foo = 3, 3);
is($bar->foo, 3);
}

{
my $bar = bar->new;
isa_ok($bar, 'bar');
is($bar->foo, undef);
is($bar->foo = 3, 3);
is($bar->foo, 3);
}

# vim:ts=2:sw=2:et:sta
