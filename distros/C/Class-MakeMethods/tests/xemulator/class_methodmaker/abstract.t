#!/usr/local/bin/perl

package X;

use Class::MakeMethods::Emulator::MethodMaker
  abstract => [ qw / a b / ],
  abstract => 'c';

sub new { bless {}, shift; }

package Y;
use vars '@ISA';
@ISA = qw ( X );

package main;

BEGIN { unshift @INC, ( $0 =~ /\A(.*?)[\w\.]+\z/ )[0] }
use Test;

my $o = new Y;

TEST { 1 };
TEST {
  eval { $o->a } ;
  $@ =~ /\QCan't locate abstract method "a" declared in "X" via "Y"./ or
  $@ =~ /\QCan't locate abstract method "a" declared in "X", called from "Y"./;
};

exit 0;

