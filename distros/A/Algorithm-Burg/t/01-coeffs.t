#!perl
use strict;
use warnings qw(all);

use Test::More tests => 2;

use Algorithm::Burg;

my @coeff1 = (
    -3.98811610432318,
    5.97514927291027,
    -3.98593346271022,
    0.998905783802478
);

my $burg = Algorithm::Burg->new(order => scalar @coeff1);
my @coeff2 = @{
    $burg->train([
        map {
              1.0 * cos($_ * 0.01) + 0.75 * cos($_ * 0.03)
            + 0.5 * cos($_ * 0.05) + 0.25 * cos($_ * 0.11)
        } 0 .. 127
    ])
};

is($#coeff1, $#coeff2, 'order');

my $error = 0.0;
my $epsilon = 1e-9;
for my $i (0 .. $#coeff1) {
    my $delta = $coeff1[$i] - $coeff2[$i];
    $error += $delta * $delta;
}

ok($error < $epsilon, "error < epsilon ($error)");
