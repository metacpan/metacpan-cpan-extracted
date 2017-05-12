#!/usr/bin/perl

use Test::More tests => 8;
use Test::Exception;
use Attempt;

use strict;
use warnings;

{
  my $c = 0;

  sub bar
  {
    ok(1,"call test ".($c+1));
    return $c++;
  }
}

my $time = time;

my $foo;
lives_ok {
attempt
{
  $foo = bar();
  die "foo is '$foo'" unless $foo > 2;
} tries => 4, delay => 3;
} "lives ok";

is($foo,"3","foo test");
cmp_ok(time, '>', $time+7, "time check 1/2");
cmp_ok(time, '<', $time+11, "time check 2/2");
