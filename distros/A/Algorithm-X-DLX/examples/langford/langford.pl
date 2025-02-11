#!/usr/bin/perl

use strict;
use warnings;

use Langford;
use Algorithm::X::DLX;

sub HELP_MESSAGE {
  my $script = $0;
  $script =~ s|^.*/||;
  print<<HELP

Usage: $script [-v] n [n]... 

Calculates solutions for Langford pairings.

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

  my $langford = Langford->new($n);
  my $dlx = Algorithm::X::DLX->new($langford->problem());
  my $options = Algorithm::X::Options();
  $options->{get_solutions} = $opt_print_solutions;

  my $result = $dlx->search($options);

  print "Solutions for n=$n: ", $result->{number_of_solutions}, "\n";
  if ($opt_print_solutions) {
    foreach my $used_rows (@{$result->{solutions}}) {
      my $solution = $langford->make_solution($used_rows);
      print join(" ", @$solution), "\n";
    }
  }
}

