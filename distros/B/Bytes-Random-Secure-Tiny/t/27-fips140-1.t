## no critic (RCS,VERSION,encapsulation,Module)

# Assure that the crypto-quality of the RNG meets FIPS PUB 140-1:
# Security Requirements for Cryptographic Modules.

# See: http://csrc.nist.gov/publications/fips/fips1401.htm

#     "Statistical random number generator tests. Cryptographic modules
#      that implement a random or pseudorandom number generator shall
#      incorporate the capability to perform statistical tests for
#      randomness. For Levels 1 and 2, the tests are not required. For
#      Level 3, the tests shall be callable upon demand. For level 4,
#      the tests shall be performed at power-up and shall also be
#      callable upon demand. The tests specified below are recommended.
#      However, alternative tests which provide equivalent or superior
#      randomness checking may be substituted."

# These tests were adapted from the algorithms described in the FIPS-140-1
# document (link provided above).  Dana Jacobsen performed the Perl adaptation
# for use with Crypt::Random::TESHA2.  Bytes::Random::Secure incorporates the
# tests without change, except for the randomness source.

# As this set of tests is run at install time, and thereafter upon demand, this
# should comply with the FIPS 140-1 Level 3 specification, with the exception
# that upon failure there will be a test-suite failure, rather than the module
# entering an "error state" as described in the FIPS 140-1 document.
# Test failure at install time would typically force the CPAN installers to
# abort installation, which is the "Perlish" solution.

use 5.006000;

use strict;
use warnings;
use Test::More;
use Bytes::Random::Secure::Tiny qw();
use Time::HiRes qw/gettimeofday/;

$Math::Random::ISAAC::Embedded::EMBEDDED_CSPRNG = 1;
$ENV{'BRST_DEBUG'} = 1;

my $random = Bytes::Random::Secure::Tiny->new(bits=>128);

plan tests => 2 + 2 + 2 + 24 + 2;

my @rbytes;
push @rbytes, $random->bytes(1) for 1..2500;

# FIPS-140 test
{
  is( scalar @rbytes, 2500, "2500 bytes were collected." );
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

done_testing();
