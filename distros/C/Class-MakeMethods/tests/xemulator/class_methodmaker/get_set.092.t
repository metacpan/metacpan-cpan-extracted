#!/usr/local/bin/perl

package X;

use Class::MakeMethods::Emulator::MethodMaker
  get_set => [ qw / a b / ],
  get_set => 'c';

sub new { bless {}, shift; }

package main;
BEGIN { unshift @INC, ( $0 =~ /\A(.*?)[\w\.]+\z/ )[0] }
use Test;

my $o = new X;

TEST { 1 };
TEST { ! defined $o->a };
TEST { $o->a(123) };
TEST { $o->a == 123 };
TEST { ! defined $o->clear_a };
TEST { ! defined $o->a };

exit 0;

