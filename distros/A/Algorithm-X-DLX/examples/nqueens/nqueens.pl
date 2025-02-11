#!/usr/bin/perl

use strict;
use warnings;

use NQueens;

sub HELP_MESSAGE {
  my $script = $0;
  $script =~ s|^.*/||;
  print<<HELP

Usage: $script [-v] n [n]... 

Calculates solution count for each n (n queens on a nxn board).

Option -v :   also print the solutions

HELP
;
  exit(1);
}

unless (@ARGV) {
  HELP_MESSAGE();
}

my $opt_print_solutions = 0;

foreach my $arg (@ARGV) {
  if ($arg =~ /^-v$/) {
    $opt_print_solutions = 1;
    next;
  } elsif ($arg =~ /-h/) {
    HELP_MESSAGE();
  }
  my $n = int($arg);

  my $queens = NQueens->new($n);
  print "Solutions for n=$n: ", $queens->count_solutions(), "\n";

  if ($opt_print_solutions) {
    foreach my $solution (@{$queens->find_solutions()}) {
      foreach my $y (0 .. $n - 1) {
        foreach my $x (0 .. $n - 1) {
          print ($x == $solution->[$y] ? 'Q' : '.');
        }
        print "\n";
      }
      print "\n";
    }
  }
}

