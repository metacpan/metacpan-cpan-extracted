#!/usr/bin/perl

use Test::More tests => 4;
use Test::Exception;
use Attempt;

use strict;
use warnings;

my $foo = attempt
{
  3;
};

is($foo,"3","returned val worked");

$foo = attempt
{
  if ($foo == 3) { return 4; }
  return 3;
};

is($foo,"4","return worked");

$foo = attempt
{
  wantarray ? ("Buffy") : "willow";
};

is($foo, "willow", "scalar context check");

my @foo = attempt
{
  wantarray ? ("Buffy") : "willow";
};

is($foo[0], "Buffy", "list context check");


