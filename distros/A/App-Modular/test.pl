#!/usr/bin/perl -w -I/home/baltasar/--useradm/work/inc

use strict;
use warnings;

use Test::Harness;

my ($dirh, @tests);

unless (opendir ($dirh, "t")) {
   print STDERR "unable to open directory 'tests' for reading ($!)";
}
@tests = grep { s/^(\w+\.t)$/t\/$1/ } readdir ($dirh);

print "running tests: @tests\n";

closedir ($dirh) || warn "cannot close directory: $!";

runtests (@tests);
