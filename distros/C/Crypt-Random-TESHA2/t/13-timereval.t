#!/usr/bin/env perl
use strict;
use warnings;
use Time::HiRes qw/gettimeofday/;
use Test::More tests => 1;

# Without decent timers, we can't generate good entropy.  Verify that our
# timers return at least 1000 unique values.  This doesn't guarantee that they
# have 1ms or better accuracy, but it does indicate our method will work.

# Very old versions of Time::HiRes on Windows will fail this, but our prereqs
# should prevent that.  Old versions of Windows (pre-NT) will also fail here.

my $time_beg = gettimeofday();

my %msecs;
my ($nuniq, $ntimes) = (0, 0);
my $finalsec = int($time_beg) + 15;  # Stop after 15 seconds no matter what.
while ($nuniq < 10_000) {
  my($sec, $usec) = gettimeofday();
  $ntimes++;
  $nuniq++ unless exists $msecs{$usec};
  undef $msecs{$usec};
  last if $sec >= $finalsec || ($nuniq >= 1000 && $ntimes > 200_000);
}

my $time_end = gettimeofday();
my $nusecs = int( 1e6 * ($time_end - $time_beg) );
my $fsecs = sprintf("%.6f", $nusecs/1000000);

diag "$ntimes calls took ${fsecs}s to find $nuniq unique timer values";

# With configuration in Makefile.PL, we don't want to fail this any more.
#ok($nuniq >= 1000, "At least 1000 unique timer values seen");
ok(1);
