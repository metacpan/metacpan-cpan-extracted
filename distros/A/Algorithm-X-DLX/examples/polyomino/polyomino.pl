#!/usr/bin/perl

use strict;
use warnings;

use Polyomino;
use Algorithm::X::DLX;

# Dana Scott's pentomino problem has 65 unique solutions
# Our Algorithm X returns 520 solutions which are not yet pruned for rotations and transpositions
my $scotts_problem = Polyomino->new(
  [Shape::pentominoes()],
  [ 
    [1, 1, 1, 1, 1, 1, 1, 1], 
    [1, 1, 1, 1, 1, 1, 1, 1], 
    [1, 1, 1, 1, 1, 1, 1, 1], 
    [1, 1, 1, 0, 0, 1, 1, 1], 
    [1, 1, 1, 0, 0, 1, 1, 1], 
    [1, 1, 1, 1, 1, 1, 1, 1], 
    [1, 1, 1, 1, 1, 1, 1, 1], 
    [1, 1, 1, 1, 1, 1, 1, 1], 
  ]
);

my $solution_iterator = Algorithm::X::DLX->new($scotts_problem->problem())->get_solver();
my $c = 0;
while (my $used_rows = &$solution_iterator()) {
  $c++;
  my $solution = $scotts_problem->make_solution($used_rows);
  foreach my $line (@$solution) {
    print $line, "\n";
  }
  print "\n";
}

print "$c solution total\n";

