#!/usr/local/bin/perl

package X;

use Class::MakeMethods::Emulator::MethodMaker
  get_set => [ qw / a b / ],
  get_set => 'c';

sub new { bless {}, shift; }

package main;
use lib qw ( ./t/emulator_class_methodmaker );
use Test;

my $o = new X;

TEST { 1 };
TEST { ! defined $o->a };
TEST { $o->a(123) };
TEST { $o->a == 123 };
TEST { ! defined $o->clear_a };
TEST { ! defined $o->a };

exit 0;

