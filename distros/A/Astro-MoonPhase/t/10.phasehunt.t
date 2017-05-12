#! /usr/bin/perl
#---------------------------------------------------------------------
# $Id$
#
# Test Astro::MoonPhase's phasehunt function
#---------------------------------------------------------------------

use strict;
use FindBin '$Bin';
use Test::More tests => 70;

use Astro::MoonPhase;

use vars '@navyPhases';
require "$Bin/testphase.pl";

#---------------------------------------------------------------------
while (<DATA>) {
  # Read time for test:
  m/^([0-9A-F]+)\s/i or next;

  my $time = hex $1;

  my $testName = asDate($time);

  ##printf "%08x = %s\n", $time, $testName; next;

  # Extract the official answer from the Navy's list:
  my $navy = 0;
  while ($navyPhases[$navy + 4] <= $time) {
    $navy += 4;
  }

  # See what Astro::MoonPhase says:
  my (@test) = phasehunt($time);

  # Compare the results:
  foreach my $i (0 .. 4) {
    # Allow 3 min. 20 sec. fuzz:
    my $pass = abs($navyPhases[$navy + $i] - $test[$i]) < 200;
    ok($pass, "index $i $testName");
    unless ($pass) {
      diag("              Navy: " . asDate($navyPhases[$navy + $i]));
      diag("  Astro::MoonPhase: " . asDate($test[$i]));
    }
  } # end foreach index in the phase list
} # end while DATA

__DATA__

00100000 = 1970-01-13 03:16:16 UTC
01234567 = 1970-08-09 22:25:43 UTC
0fedcba9 = 1978-06-21 02:00:09 UTC
12340000 = 1979-09-05 16:42:40 UTC
1a000000 = 1983-10-28 16:46:56 UTC
23457430 = 1988-10-02 00:11:28 UTC
23f57430 = 1989-02-12 12:10:24 UTC
24000000 = 1989-02-20 12:09:36 UTC
25000000 = 1989-09-02 16:29:52 UTC
34560000 = 1997-10-28 15:08:48 UTC
34f00000 = 1998-02-22 10:37:52 UTC
3f000000 = 2003-06-30 09:16:48 UTC
3f00d000 = 2003-07-01 00:04:16 UTC
4c100000 = 2010-06-09 20:56:32 UTC
