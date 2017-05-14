#!/usr/bin/perl

package X;

use Class::MakeMethods::Template::Universal
  abstract => [ qw / a b / ],
  abstract => 'c';

sub new { bless {}, shift; }

package Y;

use vars '@ISA';
@ISA = qw ( X );

package main;

use Test;
BEGIN { plan tests => 3 }

my $p = new X;
my $o = new Y;

ok( 1 );

eval { $p->a };
ok(
  $@ =~ /\QCan't locate abstract method "a" declared in "X" via "X"./ or
  $@ =~ /\QCan't locate abstract method "a" declared in "X", called from "X"./
);

eval { $o->b } ;
ok(
  $@ =~ /\QCan't locate abstract method "b" declared in "X" via "Y"./ or
  $@ =~ /\QCan't locate abstract method "b" declared in "X", called from "Y"./
);

exit 0;
