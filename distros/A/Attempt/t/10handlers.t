#!/usr/bin/perl

BEGIN
{
  eval "use Attribute::Handlers";
  if ($@)
  {
    eval 'use Test::More skip_all => "No Attribute::Handlers"';
    exit;
  }
  eval "use Test::More tests => 7;"
}

package My::Package;
use Attribute::Attempts;

sub foo : attempts(tries => 3)
{
  $::count--;
  # print ("running: $::count\n");
  $::c = caller;
  die if $::count;
  return "foo" unless wantarray;
  return "bar";
}

##########################################################

package main;

use Test::More;
use Test::Exception;

use strict;
use warnings;

################################################

# see what happens when we try again

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

