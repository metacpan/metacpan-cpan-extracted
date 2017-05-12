#  -*- Mode: CPerl -*-
use strict;
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl AI-Calibrate.t'

#########################

use Test::More tests => 4;
BEGIN { use_ok('AI::Calibrate', ':all') };

sub trim($) {
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

#  These points are from Kun Liu
#  Format of each point is [Threshold, Class].
my $points = [
              [0.999,	1],
              [0.998,	1],
              [0.742,	0],
              [0.737,	1],
              [0.685,	1],
              [0.636,	1],
              [0.613,	1],
              [0.598,	1],
              [0.559,	1],
              [0.542,	1],
              [0.541,	1],
              [0.505,	1],
              [0.490,	0],
              [0.477,	1],
              [0.475,	1],
              [0.442,	0],
              [0.442,	0],
              [0.439,	1],
              [0.425,	1],
              [0.413,	0],
              [0.411,	0],
              [0.409,	0],
              [0.401,	1],
              [0.399,	0],
              [0.386,	0],
              [0.385,	0],
              [0.375,	1],
              [0.374,	0],
              [0.369,	0],
              [0.367,	1],
              [0.362,	1],
              [0.359,	1],
              [0.359,	0],
             ];

my $calibrated_expected =
  [[0.998, 1],
   [0.505, 0.9],
   [0.475, 0.666666666666667],
   [0.425, 0.5],
   [0.359, 0.384615384615384]
  ];

my $calibrated_got = calibrate( $points, 1 );

pass("ran_ok");

is_deeply($calibrated_got, $calibrated_expected, "calibration");



my $expected_mapping = "
1.000 > SCORE >= 0.998     prob = 1.000
0.998 > SCORE >= 0.505     prob = 0.900
0.505 > SCORE >= 0.475     prob = 0.667
0.475 > SCORE >= 0.425     prob = 0.500
0.425 > SCORE >= 0.359     prob = 0.385
0.359 > SCORE >= 0.000     prob = 0.000
";

my $output = '';
open TOOUTPUT, '>', \$output or die "Can't open TOOUTPUT: $!";
my $stdout = select(TOOUTPUT);
print_mapping($calibrated_got);
close(TOOUTPUT);
select $stdout;

is(trim($output), trim($expected_mapping), "printed mapping");
