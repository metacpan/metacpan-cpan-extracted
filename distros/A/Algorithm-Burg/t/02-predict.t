#!perl
use strict;
use warnings qw(all);

use Test::More tests => 2;

use Algorithm::Burg;

my @whole_series = map {
      1.0 * cos($_ * 0.01) + 0.75 * cos($_ * 0.03)
    + 0.5 * cos($_ * 0.05) + 0.25 * cos($_ * 0.11)
} 0 .. 128;

my $burg = Algorithm::Burg->new(order => 64);
$burg->train([ @whole_series[0 .. 64] ]);

my @original = @whole_series[64 .. $#whole_series];
my @predicted = @{ $burg->predict(64) };

is($#original, $#predicted, 'cardinality');

# use Data::Dumper;
# diag Dumper(\@original, \@predicted);

my $error = 0.0;
my $epsilon = 3.0;
for my $i (0 .. $#original) {
    my $delta = $original[$i] - $predicted[$i];
    $error += $delta * $delta;
}

ok($error < $epsilon, "error < epsilon ($error)");
