use strict;
use warnings FATAL => 'all';
use Test::More;
use Algorithm::Simplex::Float;

# Basic Feasible Solution: BFS

# Test a formulation (initial matrix) that is NOT BFS.
my $not_bfs_matrix = [
    [ 1,      -0.411,  0.313,   0.429,   -3424.5 ],
    [ -1.851, 1,       -0.422,  -0.692,  -8911.9 ],
    [ 2.819,  -0.884,  1,       1.295,   -6763.1 ],
    [ 1.93,   -0.692,  0.648,   1,       -5403 ],
    [ 1,      0,       0,       0,       100 ],
    [ 0,      1,       0,       0,       1000 ],
    [ 0,      0,       1,       0,       500 ],
    [ 292,    11.3674, 242.707, 61.7215, 0 ],
];

my $tableau_object = Algorithm::Simplex::Float->new(tableau => $not_bfs_matrix);
is($tableau_object->is_basic_feasible_solution,
    0, 'NOT a basic FEASIBLE solution');

# Test a BFS.
my $is_bfs_matrix =
  [ [ 8, 3, 4, 40 ], [ 40, 10, 10, 200 ], [ 160, 60, 80, 0 ], ];

$tableau_object = Algorithm::Simplex::Float->new(tableau => $is_bfs_matrix);
is($tableau_object->is_basic_feasible_solution,
    1, 'IS a basic FEASIBLE solution');

done_testing();
