#!/usr/bin/perl

=head1 NAME

Array-Transpose-example.pl - Simple example on the use of the transpose function

=cut

use strict;
use warnings;
use Array::Transpose qw{transpose};

my @input=([qw{a b c}],
           [1..3],
           [4,5,6],
           [qw{7 8 9}]);
my @output=transpose \@input;

print  "Input\n";
printf "Rows: %s, Columns: %s\n", scalar(@input), scalar(@{$input[0]});
printf "%s\n", join(" ", @$_) foreach @input;

print  "Output\n";
printf "Rows: %s, Columns: %s\n", scalar(@output), scalar(@{$output[0]});
printf "%s\n", join(" ", @$_) foreach @output;

=head1 OUTPUT

  Input
  Rows: 4, Columns: 3
  a b c
  1 2 3
  4 5 6
  7 8 9
  Output
  Rows: 3, Columns: 4
  a 1 4 7
  b 2 5 8
  c 3 6 9

=cut
