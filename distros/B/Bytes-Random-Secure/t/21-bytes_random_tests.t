## no critic (RCS,VERSION,encapsulation,Module)

use strict;
use warnings;

use Test::More;

eval "use Statistics::Basic;"; ## no critic (eval)
if ( $@ ) {
  plan( skip_all => "Statistics::Basic needed for random quality tests." );
}

use Bytes::Random::Secure;

# Default seed entropy of 16 longs is more than we need in testing.
my $random = Bytes::Random::Secure->new(
  Bits        => 64,
  Weak        => 1,
  NonBlocking => 1
); # Minimum allowed is sufficient here.


for( 1..40 ) {
  is(
    length( $random->bytes($_) ) => $_,
    "Got $_ random bytes"
  );
}


{
  my $amount = 1e6;
  my %dispersion;
  $dispersion{ord $random->bytes(1)}++ for 1..$amount;
  my @slots = 0..0xff;

  for my $slot (@slots) {
    ok exists $dispersion{$slot},
      "could produce bytes of numeric value $slot";
  }

  my $s = Statistics::Basic::stddev(
    map {defined $_ ? $_ : 0} @dispersion{@slots}
  )->query;
  ok 2 > log($s) / log(10),
    "$amount values are roughly evenly distributed "
    . "(standard deviation was $s, should be about 60)";
}


done_testing();
