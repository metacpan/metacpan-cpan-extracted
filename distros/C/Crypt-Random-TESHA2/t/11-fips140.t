#!/usr/bin/env perl
use strict;
use warnings;
use Crypt::Random::TESHA2 qw/random_bytes/;
use Time::HiRes qw/gettimeofday/;

use Test::More;

my @rbytes;

# Measure approximate speed
my $bps;
{
  push @rbytes, random_bytes(1);
  my $t1 = gettimeofday();
  push @rbytes, random_bytes(1) for 1..100;
  my $t2 = gettimeofday();
  $bps = int(  (100 * 8) / ($t2-$t1)  );
}
diag "Speed: $bps bits per second";

if ($bps < 500 && !$ENV{RELEASE_TESTING}) {
  # FIPS-140 would require > 30 seconds to run.
  plan tests => 1;
  diag "Not gathering statistics due to slow speed";
  ok(1);
  exit(0);
}

plan tests => 2 + 2 + 2 + 24 + 2;

push @rbytes, random_bytes(1) for 1..2399;

# FIPS-140 test
{
  is( scalar @rbytes, 2500, "1 + 100 + 2399 = 2500" );
  my $str = join("", map { unpack("B8", $_) } @rbytes);
  is( length($str), 20000, "binary string is length 20000" );

  # Monobit
  my $nzeros = $str =~ tr/0//;
  my $nones = $str =~ tr/1//;
  cmp_ok($nones, '>',  9654, "Monobit: Number of ones is > 9654");
  cmp_ok($nones, '<', 10346, "Monobit: Number of ones is < 10346");

  # Long Run
  ok($str !~ /0{34}/, "Longrun: No string of 34+ zeros");
  ok($str !~ /1{34}/, "Longrun: No string of 34+ ones");

  # Runs
  my @l0;
  my @l1;
  $l0[$_] = 0 for 1 .. 34;
  $l1[$_] = 0 for 1 .. 34;
  {
    my $s = $str;
    while (length($s) > 0) {
      if ($s =~ s/^(0+)//) { $l0[length($1)]++; }
      if ($s =~ s/^(1+)//) { $l1[length($1)]++; }
    }
  }
  # Fold all runs of >= 6 into 6.
  $l0[6] += $l0[$_] for 7 .. 34;
  $l1[6] += $l1[$_] for 7 .. 34;
  # Test thresholds
  cmp_ok($l0[1], '>=', 2267, "Runs: zero length 1 ($l0[1]) >= 2267");
  cmp_ok($l1[1], '>=', 2267, "Runs:  one length 1 ($l1[1]) >= 2267");
  cmp_ok($l0[1], '<=', 2733, "Runs: zero length 1 ($l0[1]) <= 2733");
  cmp_ok($l1[1], '<=', 2733, "Runs:  one length 1 ($l1[1]) <= 2733");
  cmp_ok($l0[2], '>=', 1079, "Runs: zero length 2 ($l0[2]) >= 1079");
  cmp_ok($l1[2], '>=', 1079, "Runs:  one length 2 ($l1[2]) >= 1079");
  cmp_ok($l0[2], '<=', 1421, "Runs: zero length 2 ($l0[2]) <= 1421");
  cmp_ok($l1[2], '<=', 1421, "Runs:  one length 2 ($l1[2]) <= 1421");
  cmp_ok($l0[3], '>=',  502, "Runs: zero length 3 ($l0[3]) >=  502");
  cmp_ok($l1[3], '>=',  502, "Runs:  one length 3 ($l1[3]) >=  502");
  cmp_ok($l0[3], '<=',  748, "Runs: zero length 3 ($l0[3]) <=  748");
  cmp_ok($l1[3], '<=',  748, "Runs:  one length 3 ($l1[3]) <=  748");
  cmp_ok($l0[4], '>=',  223, "Runs: zero length 4 ($l0[4]) >=  223");
  cmp_ok($l1[4], '>=',  223, "Runs:  one length 4 ($l1[4]) >=  223");
  cmp_ok($l0[4], '<=',  402, "Runs: zero length 4 ($l0[4]) <=  402");
  cmp_ok($l1[4], '<=',  402, "Runs:  one length 4 ($l1[4]) <=  402");
  cmp_ok($l0[5], '>=',   90, "Runs: zero length 5 ($l0[5]) >=   90");
  cmp_ok($l1[5], '>=',   90, "Runs:  one length 5 ($l1[5]) >=   90");
  cmp_ok($l0[5], '<=',  223, "Runs: zero length 5 ($l0[5]) <=  223");
  cmp_ok($l1[5], '<=',  223, "Runs:  one length 5 ($l1[5]) <=  223");
  cmp_ok($l0[6], '>=',   90, "Runs: zero length 6+($l0[5]) >=   90");
  cmp_ok($l1[6], '>=',   90, "Runs:  one length 6+($l1[5]) >=   90");
  cmp_ok($l0[6], '<=',  223, "Runs: zero length 6+($l0[5]) <=  223");
  cmp_ok($l1[6], '<=',  223, "Runs:  one length 6+($l1[5]) <=  223");

  # Poker
  {
    my @segment;
    $segment[$_] = 0 for 0 .. 15;
    my $s = $str;
    while ($s =~ s/^(....)//) {
      $segment[oct("0b$1")]++;
    }
    my $X = 0;
    $X += $segment[$_]*$segment[$_] for 0..15;
    $X = (16 / 5000) * $X - 5000;
    cmp_ok($X, '>',  1.03, "Poker: X >  1.03");
    cmp_ok($X, '<', 57.4 , "Poker: X < 57.4");
  }
}
