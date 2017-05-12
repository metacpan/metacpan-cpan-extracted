#!/usr/local/bin/perl

package X;

BEGIN { unshift @INC, ( $0 =~ /\A(.*?)[\w\.]+\z/ )[0] }
use Test;

use Class::MakeMethods::Emulator::MethodMaker
  list => [ qw / a b / ],
  list => 'c';

sub new { bless {}, shift; }
my $o = new X;

TEST { 1 };
TEST { ! scalar @{$o->a} };
TEST { $o->push_a(123, 456) };
TEST { $o->unshift_a('baz') };
TEST { $o->pop_a == 456 };
TEST { $o->shift_a eq 'baz' };

TEST { $o->b(123, 'foo', [ qw / a b c / ], 'bar') };
TEST {
  my @l = $o->b;
  $l[0] == 123 and
  $l[1] eq 'foo' and
  $l[2] eq 'a' and
  $l[3] eq 'b' and
  $l[4] eq 'c' and
  $l[5] eq 'bar'
};

TEST {
  $o->splice_b(1, 2, 'baz');
  my @l = $o->b;
  $l[0] == 123 and
  $l[1] eq 'baz' and
  $l[2] eq 'b' and
  $l[3] eq 'c' and
  $l[4] eq 'bar'
};

TEST { ref $o->b_ref eq 'ARRAY' };
TEST { ! scalar @{$o->clear_b} };
TEST { ! scalar @{$o->b} };

exit 0;

