#!/usr/local/bin/perl

package X;

use Class::MakeMethods::Emulator::MethodMaker -sugar;

make methods
  new => 'new',
  get_set => 'a';

package main;
BEGIN { unshift @INC, ( $0 =~ /\A(.*?)[\w\.]+\z/ )[0] }
use Test;

TEST { 1 };

my $o;
TEST { $o = new X };
TEST { ! defined $o->a };
TEST { $o->a(123) };
TEST { $o->a == 123 };
TEST { ! defined $o->clear_a };
TEST { ! defined $o->a };

exit 0;

