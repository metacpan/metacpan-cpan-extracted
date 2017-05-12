#!/usr/bin/env perl
use strict;
use warnings;
use Crypt::Random::Seed;
use Math::Random::ISAAC;

# Get a strong random source.
my $source = Crypt::Random::Seed->new();
die "Cannot find a source" unless defined $source;

{
  # Win32 uses FIPS 186-2 with SHA1, so has a 160-bit internal state, meaning
  # they start with 5 32-bit values worth of entropy.
  # ISAAC uses 256 32-bit values for state, and zero-pads everything not
  # supplied.  Using 8 values (256 bits) for seeding should be more than enough.
  my $RNG = Math::Random::ISAAC->new( $source->random_values(8) );

  sub random_bytes {
    my $bytes = shift;
    $bytes = defined $bytes ? int($bytes) : 0;
    my $str = '';
    while ($bytes >= 4) {
      $str .= pack("L", $RNG->irand);
      $bytes -= 4;
    }
    if ($bytes > 0) {
      my $rval = $RNG->irand;
      $str .= pack("S", ($rval >> 8) & 0xFFFF) if $bytes >= 2;
      $str .= pack("C", $rval & 0xFF) if $bytes % 2;
    }
    return $str;
  }
}

# Create a big stream of output for testing.  Takes about 2 seconds.
print random_bytes(8192) for 1..1024;

__END__

./entest -vf brs.out

Test Results
Sample:      8388608 bytes
Entropy:     7.999976 bits
Chi-Square:  282.623535(11.296928%)
Mean:        127.488821
PI:          3.139942(-0.052543%)
Correlation: 0.000195
Sample looks good!



./a.out

========= Summary results of Rabbit =========

 Version:          TestU01 1.2.3
 File:             brs.out
 Number of bits:   67108864
 Number of statistics:  40
 Total CPU time:   00:00:31.53

 All tests were passed

