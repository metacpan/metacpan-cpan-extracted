#!/usr/bin/perl

use Test::More tests => 4;
use Test::Exception;
use Attempt;

use strict;
use warnings;

my $foo;

{
  my $c = 0;

  sub bar
  {
    ok(1,"call test ".($c+1));
    return $c++;
  }
}

lives_ok {
attempt
{
  $foo = bar() or die("crap");
};
} "lives ok";

is($foo,"1","foo test");

