#!/usr/bin/perl

use strict;
use warnings;

use lib '../lib';
use Algorithm::CurveFit;

my $formula = 'b*cos(x/10)+c*sin(x/10)';
my $variable = 'x';
my @xdata;
my @ydata;

unless (@ARGV) {
    die <<HERE;
Usage: $0 DATAFILE
Fits b*cos(x/10)+c*sin(x/10) to the data in DATAFILE.
HERE
}

open my $fh, '<', shift @ARGV or die $!;
while (<$fh>) {
	chomp;
	my @ary = split ' ';
	push @xdata, $ary[0];
	push @ydata, $ary[1];
}
my @parameters = (
    # Name    Guess   Accuracy
    ['b',     10,    0.0001],
    ['c',     2,     0.0005],
);
my $max_iter = 100; # maximum iterations
  
my $square_residual = Algorithm::CurveFit->curve_fit(
    formula            => $formula, # may be a Math::Symbolic tree instead
    params             => \@parameters,
    variable           => $variable,
    xdata              => \@xdata,
    ydata              => \@ydata,
    maximum_iterations => $max_iter,
);
  
use Data::Dumper;
print Dumper \@parameters;
print Dumper $square_residual;
