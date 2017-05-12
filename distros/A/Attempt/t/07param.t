#!/usr/bin/perl

package My::Package;
use Sub::Attempts;

sub foo
{
  $::count--;
  # print ("running: $::count\n");
  $::c = caller;
  die if $::count;
  return "foo" unless wantarray;
  return "bar";
}

attempts("foo", tries => 3);

##########################################################

package main;

use Test::More tests => 4;
use Test::Exception;

use strict;
use warnings;

################################################

# see what ahppens when we try again

$::count = 3;

lives_ok {
 My::Package::foo();
} "lives ok";

is($::count, 0, "Count decreased");

################################################

# see what happens when we run over allowed times

$::count = 4;

dies_ok{
 My::Package::foo();
} "dies ok";

is($::count, 1, "Count still above 0");

