#!/usr/bin/perl -w

use strict;
use Test;
use Business::SEDOL;

BEGIN { plan tests => 48 }

# Check some non-fixed income SEDOLs
my @values = qw/012345 7 012545 3 010100 0 217100 1 302013 5 466863 1 548418 2
                659745 4 706085 8 B1F3M5 9 B1H54P 7 B12345 6/;
while (@values) {
  my ($v, $expected) = splice @values, 0, 2;
  my $sdl = Business::SEDOL->new($v);
  my $c = $sdl->check_digit();
  ok($c, $expected, "check_digit of $v expected $expected; got $c\n");
  $sdl = Business::SEDOL->new($v.$expected);
  $c = $sdl->check_digit();
  ok($c, $expected, "check_digit of $v$expected expected $expected; got $c\n");
  ok($sdl->is_valid());
  $sdl->sedol("$v".(9-$expected));
  ok(!$sdl->is_valid());
}

__END__
