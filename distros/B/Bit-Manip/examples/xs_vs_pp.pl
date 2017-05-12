use warnings;
use strict;

# performs a benchmark between this XS 
# version and the PP version

use Benchmark qw(timethese cmpthese);
use Bit::Manip;
use Bit::Manip::PP;

my $do = $ARGV[0];

timethese(1000000, {
        'c' => 'c',
        'p' => 'p',
    }
);

cmpthese(1000000, {
        'c' => 'c',
        'p' => 'p',
    }
);

sub c {
    Bit::Manip::bit_set(65535, 0, 8, 0xFF);
}
sub p {
    Bit::Manip::PP::bit_set(65535, 0, 8, 0xFF);
}

__END__

Benchmark: timing 1000000 iterations of c, p...
         c:  3 wallclock secs ( 3.35 usr +  0.00 sys =  3.35 CPU) @ 298507.46/s (n=1000000)
         p: 17 wallclock secs (16.58 usr +  0.00 sys = 16.58 CPU) @ 60313.63/s (n=1000000)
      Rate    p    c
p  60606/s   -- -80%
c 299401/s 394%   --
