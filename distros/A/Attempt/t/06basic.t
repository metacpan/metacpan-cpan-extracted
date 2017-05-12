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

attempts("foo");


##########################################################

package main;

use Test::More tests => 7;
use Test::Exception;

use strict;
use warnings;

################################################

# see what happens when we try again

$::count = 2;

lives_ok {
 My::Package::foo();
} "lives ok";

is($::count, 0, "Count decreased");

################################################

# see what happens when we run over allowed times

$::count = 3;

dies_ok{
 My::Package::foo();
} "dies ok";

is($::count, 1, "Count still above 0");

################################################

# is the caller okay?

$::count = 2;

My::Package::foo();

is($::c, "main", "caller is okay");

#################################################

# okay, list and scalar context;

$::count = 2;
my $scalar = My::Package::foo();

$::count = 2;
my @list = My::Package::foo();

is($scalar, "foo", "scalar context");
is($list[0],   "bar", "list context");

