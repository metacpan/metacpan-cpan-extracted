#!/usr/bin/perl

use Test::More tests => 6;
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

my $foo;
dies_ok {
attempt
{
  $foo = bar();
  die "foo is '$foo'" unless $foo > 3;
} tries => 4;
} "dies ok";

is($foo,"3","foo test");

