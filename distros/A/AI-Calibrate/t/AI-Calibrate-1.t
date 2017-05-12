#  -*- Mode: CPerl -*-
use strict;
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl AI-Calibrate.t'

#########################

use Test::More tests => 34;
BEGIN { use_ok('AI::Calibrate', ':all') };

srand;

sub deeply_approx {
    # Like Test::More::is_deeply but uses approx() to compare elements.
    my( $got, $expected ) = @_;
    my $EPSILON = 1.0e-6;
    sub max {  $_[0] > $_[1] ? $_[0] : $_[1] }
    sub approx {
        my($x, $y) = @_;
        print("approx($x, $y)\n");
        if ($x == 0 and $y == 0) {
            return(1);
        } else {
            return(abs($x-$y) / max($x,$y) < $EPSILON);
        }
    }
    for my $i (0 .. $#{$got}) {
        my $g = $got->[$i];
        if (defined($expected->[$i])) {
            my $e = $expected->[$i];
            if (!approx($g->[0], $e->[0])) {
                return(0);
            }
            if (!approx($g->[1], $e->[1])) {
                return(0);
            }
        } else {
            return(0);
        }
    }
    return(1);
}

#  Given an array reference, shuffle the array.  This is the Fisher-Yates code
#  from The Perl Cookbook.
sub shuffle_array {
   my($array) = shift;
   my($i);
   for ($i = @$array ; --$i; ) {
      my $j = int rand ($i+1);
      next if $i == $j;
      @$array[$i,$j] = @$array[$j,$i]
   }
}

#  These points are from the ROCCH-PAV paper, Table 1
#  Format of each point is [Threshold, Class].
my $points = [
              [.9, 1],
              [.8, 1],
              [.7, 0],
              [.6, 1],
              [.55, 1],
              [.5, 1],
              [.45, 0],
              [.4, 1],
              [.35, 1],
              [.3, 0 ],
              [.27, 1],
              [.2, 0 ],
              [.18, 0],
              [.1, 1 ],
              [.02, 0]
             ];

my $calibrated_expected =
  [
   [0.8, 1],
   [0.5, 0.75],
   [0.35, 0.666666666666667],
   [0.27, 0.5],
   [0.1, 0.333333333333333]
  ];

my $calibrated_got = calibrate( $points, 1 );

pass("ran_ok");

ok(deeply_approx($calibrated_got, $calibrated_expected),
   "pre-sorted calibration");

#  Shuffle the arrays a bit and try calibrating again

for (1 .. 10) {
    shuffle_array($points);
    my $calibrated_got = calibrate($points, 0);
    ok(deeply_approx($calibrated_got, $calibrated_expected),
       "unsorted cal $_");
}

#  Tweak the thresholds

for (1 .. 10) {
    my $delta = rand;
    my @delta_points;
    for my $point (@$points) {
        my($thresh, $class) = @$point;
        push(@delta_points, [ $thresh+$delta, $class]);
    }
    my @delta_expected;
    for my $point (@$calibrated_expected) {
        my($thresh, $class) = @$point;
        push(@delta_expected, [ $thresh+$delta, $class]);
    }
    my $delta_got = calibrate(\@delta_points, 0);
    ok(deeply_approx($delta_got, \@delta_expected), "unsorted cal $_");
}

my @test_estimates =
  ( [100, 1],
    [.9,    1 ],
    [.8,   1],
    [.7,  3/4 ],
    [.5,  3/4 ],
    [.45, 2/3 ],
    [.35, 2/3 ],
    [.3,  1/2 ],
    [.2,  1/3 ],
    [.02,   0 ],
    [.00001, 0]
);


print "Using this mapping:\n";
print_mapping($calibrated_got);
print;

for my $pair (@test_estimates) {
    my($score, $prob_expected) = @$pair;
    my $prob_got = score_prob($calibrated_got, $score);
    is($prob_got, $prob_expected, "score_prob test @$pair");
}
