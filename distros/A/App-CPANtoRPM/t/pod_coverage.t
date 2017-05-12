#!/usr/bin/perl

#
# Test that the POD documentation is complete.
#

use strict;
use Test::More;

# Don't run tests for installs
unless ( $ENV{RELEASE_TESTING} ) {
   plan( skip_all => "Author tests not required for installation" );
}

eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage"
  if $@;

eval "use File::Basename";
plan skip_all => "File::Basename required for testing POD coverage"
  if $@;

# If there is a file pod_coverage.ign, it should be a list of module
# name substrings to ignore (any module with any of these substrings
# will be ignored).

# Find the pod_coverage.ign file

my($testdir);
if (-f "$0") {
   my $COM = $0;
   $testdir   = dirname($COM);
   $testdir   = '.'  if (! $testdir);
} elsif (-d 't') {
   $testdir   = 't';
} else {
   $testdir   = '.';
}

my @ign = ();
if (-f "$testdir/pod_coverage.ign") {
   open(IN,"$testdir/pod_coverage.ign");
   @ign = <IN>;
   close(IN);
   chomp(@ign);
}

chdir("..")  if ($testdir eq '.');

if (@ign) {

   my @mod = all_modules();

   MOD:
   foreach my $mod (@mod) {
      foreach my $ign (@ign) {
         next MOD  if ($mod =~ /\Q$ign\E/);
      }
      pod_coverage_ok($mod);
   }
   done_testing();

} else {
   all_pod_coverage_ok();
}
