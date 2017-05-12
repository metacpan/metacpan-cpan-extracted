#! /usr/bin/env perl

use strict;
use warnings;
use Test::More;

TODO: {
  local $TODO = "Write tests for parallel building, such as testing the lockfile code is working";
	
  # This could be implemented by creating a builder which runs sleep($ENV{SLEEP})
  # during its build method, and then fork two children, one with SLEEP=5 and
  # the other with SLEEP=1 and make sure the SLEEP=5 child is reaped before the
  # SLEEP=1 child.  Or better, have the sleep=1 child verify that some file was
  # already built before its build method was called.
  fail;
}

done_testing;