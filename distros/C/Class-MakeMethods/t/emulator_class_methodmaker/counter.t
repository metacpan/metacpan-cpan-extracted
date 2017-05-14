#!/usr/local/bin/perl

package X;


use Class::MakeMethods::Emulator::MethodMaker
  counter => [ qw / a b / ],
  abstract => 'c';

sub new { bless {}, shift; }

package main;
use lib qw ( ./t/emulator_class_methodmaker );
use Test;

my $o = new X;

TEST { 1 };
TEST { $o->a == 0 };
TEST { $o->a == 0 };
TEST { $o->a_incr == 1 };
TEST { $o->a_incr == 2 };
TEST { $o->a == 2 };

exit 0;

