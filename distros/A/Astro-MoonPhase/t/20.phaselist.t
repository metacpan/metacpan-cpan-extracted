#! /usr/bin/perl
#---------------------------------------------------------------------
# $Id$
#
# Test Astro::MoonPhase's phaselist function
#---------------------------------------------------------------------

use strict;
use FindBin '$Bin';
use Test::More tests => 389;

use Astro::MoonPhase;

use vars '@navyPhases';
require "$Bin/testphase.pl";

#---------------------------------------------------------------------
while (<DATA>) {
  # Read start & stop times for test:
  m/^([0-9A-F]+) +([0-9A-F]+)/i or next;

  my ($start, $stop) = map { hex $_ } ($1, $2);

  my $testName = asDate($start) . ' -- ' . asDate($stop);

  ##printf "%08x %08x = %s\n", $start, $stop, $testName; next;

  # Extract the official answer from the Navy's list:
  my @navy = grep { $_ >= $start and $_ < $stop } @navyPhases;
  my $navyStart;
  if (@navy) {
    ($navyStart) = grep { $navyPhases[$_] == $navy[0] } 0 .. $#navyPhases;
    $navyStart %= 4;
  } # end if we found phases

  # See what Astro::MoonPhase says:
  my ($testStart, @test) = phaselist($start, $stop);

  # Compare the results:
  is($testStart, $navyStart, "phase $testName");
  is(scalar @navy, scalar @test, "count $testName");

  foreach my $i (0 .. $#navy) {
    my $pass = abs($navy[$i] - $test[$i]) < 200; # Allow 3 min. 20 sec. fuzz
    ok($pass, "index $i $testName");
    unless ($pass) {
      diag("              Navy: " . asDate($navy[$i]));
      diag("  Astro::MoonPhase: " . asDate($test[$i]));
    }
  } # end foreach index in the phase list
} # end while DATA

__DATA__

00001000 01000000 = 1970-01-01 01:08:16 UTC -- 1970-07-14 04:20:16 UTC
12340000 1a000000 = 1979-09-05 16:42:40 UTC -- 1983-10-28 16:46:56 UTC
1fffffff 21000000 = 1987-01-05 18:48:31 UTC -- 1987-07-18 23:08:48 UTC
23457430 23f57430 = 1988-10-02 00:11:28 UTC -- 1989-02-12 12:10:24 UTC
24000000 25000000 = 1989-02-20 12:09:36 UTC -- 1989-09-02 16:29:52 UTC
34560000 34f00000 = 1997-10-28 15:08:48 UTC -- 1998-02-22 10:37:52 UTC
38000000 38f00000 = 1999-10-10 02:54:56 UTC -- 2000-04-09 03:58:56 UTC
3f000000 3f00d000 = 2003-06-30 09:16:48 UTC -- 2003-07-01 00:04:16 UTC
4c100000 4d196600 = 2010-06-09 20:56:32 UTC -- 2010-12-28 04:22:24 UTC
