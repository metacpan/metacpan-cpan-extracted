#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Std;
use Algorithm::X::DLX;

our $VERSION = '0.01';

$Getopt::Std::STANDARD_HELP_VERSION = 1;

getopts('pvst', \my %opts)
  or HELP_MESSAGE();

my $opt_verbose         = $opts{v};
my $opt_print_solutions = $opts{p} || $opts{v};
my $opt_sparse          = $opts{s};
my $opt_print_tree      = $opts{t};

chomp(my $line = <STDIN>);
my ($width, $secondary_columns) = split ' ', $line;

my @input_rows;
while (defined($line = <STDIN>)) {
  chomp($line);

  my @row;
  if ($opt_sparse) {
    @row = sort { $a <=> $b } split ' ', $line;

  } else {
    @row = split ' ', $line;
  }
  push @input_rows, \@row if @row;
}

my $problem = $opt_sparse ? Algorithm::X::ExactCoverProblem->new($width, \@input_rows, $secondary_columns)
                          : Algorithm::X::ExactCoverProblem->dense(\@input_rows, $secondary_columns);

my $dlx = Algorithm::X::DLX->new($problem);

my $result = $dlx->search();

for my $row_indices (@{$result->{solutions}}) {
  if ($opt_print_solutions) {
    if ($opt_verbose) {
      for my $i (@$row_indices) {
        print_range(\@{$input_rows[$i]});
      }
      print "\n";

    } else {
      print_range($row_indices);
    }
  }
}
print "solutions: ", $result->{number_of_solutions}, "\n";

if ($opt_print_tree) {
  print "\n";
  for (my $i = 0; $i < @{$result->{profile}}; $i++) {
      print "Nodes at depth $i: ", $result->{profile}[$i], "\n";
  }
}

sub print_range {
  my $xs = shift;
  for my $x (@$xs) {
      print $x, " ";
  }
  print "\n";
}

sub HELP_MESSAGE {
  my $script = $0;
  $script =~ s|^.*/||;
  print<<HELP

Usage: $script -[options] <input>

Option flags are:
 -p print solutions as a line with selected row indices
 -v print solutions by outputting the rows themselves
 -t print nodes inspected for each recursion level
 -s input is a sparse matrix

The first line of input states the problem matrix width (all columns), optionally 
followed by a space and the number of secondary columns therein, at the right.
All following lines are the matrix rows (space separated).

HELP
;
  exit(1);
}

