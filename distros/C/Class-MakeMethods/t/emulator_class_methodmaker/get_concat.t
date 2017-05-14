#!/usr/local/bin/perl

package X;

use lib qw ( ./t/emulator_class_methodmaker );
use Test;

use Class::MakeMethods::Emulator::MethodMaker 
  get_concat => 'x',
  get_concat => {'name' => 'y', 'join' => "\t"},
  ;

sub new { bless {}, shift; }

my $o = new X;

TEST { 1 };
TEST { ! defined $o->x };
TEST { $o->x('foo') };
TEST { $o->x eq 'foo' };
TEST { $o->x('bar') };
TEST { $o->x eq 'foobar' };
TEST { ! defined $o->clear_x };
TEST { ! defined $o->x };

TEST { ! defined $o->y };
TEST { $o->y ('one') };
TEST { $o->y eq 'one' };
TEST { $o->y ('two') };
TEST { $o->y eq "one\ttwo" };

exit 0;

