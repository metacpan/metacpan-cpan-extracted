use strict;
use warnings;
use Test::More tests => 18;
use PDL::Lite;
use Algorithm::Simplex::Float;
use Algorithm::Simplex::PDL;
use Algorithm::Simplex::Rational;

# Get shell tableau object for access to EPSILON and MAXIMUM_PIVOTS
my $tableau_shell = Algorithm::Simplex->new(tableau => [ [] ]);

my $tests = {
    'Baumol: Advertising' => {
        initial_tableau =>
          [ [ 8, 3, 4, 40 ], [ 40, 10, 10, 200 ], [ 160, 60, 80, 0 ], ],
        optimal_tableau => [
            [ 1 / 8, 3 / 8, 1 / 2, 5 ],
            [ -5,    -5,    -10,   0 ],
            [ -20,   0,     0,     -800 ],
        ],
    },
    'Bland: Anti-Cycling' => {
        initial_tableau => [
            [ 1 / 4, -8,  -1,     9,  0 ],
            [ 1 / 2, -12, -1 / 2, 3,  0 ],
            [ 0,     0,   1,      0,  1 ],
            [ 3 / 4, -20, 1 / 2,  -6, 0 ],
        ],
        optimal_tableau => [
            [ 0,       0,      1,      0,   1 ],
            [ 15 / 2,  -1 / 2, 3 / 4,  -2,  3 / 4 ],
            [ 6,       2,      1,      -24, 1 ],
            [ -21 / 2, -3 / 2, -5 / 4, -2,  -5 / 4 ],
        ],
    },
    'McRae: Lumber Mill' => {
        initial_tableau => [ [ 1, 3, 2, 10 ], [ 2, 1, 1, 8 ], [ 3, 2, 4, 0 ] ],
        optimal_tableau => [
            [ -1 / 3, 2 / 3,  5 / 3,   4 ],
            [ 2 / 3,  -1 / 3, -1 / 3,  2 ],
            [ -2 / 3, -5 / 3, -11 / 3, -22 ]
        ],
    },
    'McRae: Wheat Transshipment' => {
        initial_tableau => [
            [ 1,  0,  0,  -1,  0,   42 ],
            [ 1,  0,  0,  0,   -1,  36 ],
            [ 0,  1,  0,  -1,  0,   55 ],
            [ 0,  1,  0,  0,   -1,  47 ],
            [ 0,  0,  1,  -1,  0,   60 ],
            [ 0,  0,  1,  0,   -1,  51 ],
            [ 20, 36, 34, -50, -40, 0 ]
        ],
        optimal_tableau => [
            [ 1,   -1, 0,   -1, 0,   8 ],
            [ 0,   0,  0,   -1, 1,   42 ],
            [ 1,   -1, 0,   0,  -1,  2 ],
            [ 1,   0,  0,   -1, 0,   55 ],
            [ -1,  1,  -1,  0,  0,   1 ],
            [ 1,   -1, 1,   -1, 0,   59 ],
            [ -30, -6, -34, 0,  -20, -4506 ]
        ]
    },
    'Dantzig: Alloy Blending' => {
        initial_tableau => [
            [ 10, 10, 80, 41 ],
            [ 10, 30, 60, 43 ],
            [ 40, 50, 10, 58 ],
            [ 60, 30, 10, 60 ],
            [ 30, 30, 40, 76 ],
            [ 30, 40, 30, 75 ],
            [ 30, 20, 50, 73 ],
            [ 50, 40, 10, 69 ],
            [ 20, 30, 50, 73 ],
            [ 30, 30, 40, 0 ],
        ],
        optimal_tableau => [
            [ -3 / 5,     1,        -7 / 5,   14 / 5 ],
            [ 7 / 1000,   -3 / 200, 9 / 500,  81 / 250 ],
            [ -23 / 1000, 7 / 200,  -1 / 500, 141 / 250 ],
            [ 27 / 1000,  -3 / 200, -1 / 500, 83 / 125 ],
            [ -2 / 5,     0,        -3 / 5,   131 / 5 ],
            [ -1 / 10,    -1 / 2,   -2 / 5,   114 / 5 ],
            [ -7 / 10,    1 / 2,    -4 / 5,   128 / 5 ],
            [ -1 / 2,     -1 / 2,   0,        10 ],
            [ -1 / 5,     0,        -4 / 5,   133 / 5 ],
            [ -2 / 5,     0,        -3 / 5,   -249 / 5 ],
        ],
    },
    'Hillier and Lieberman: Wyndor Glass Company' => {
        initial_tableau =>
          [ [ 0, 1, 4 ], [ 2, 0, 12 ], [ 2, 3, 18 ], [ 5, 3, 0 ], ],
        optimal_tableau => [
            [ 1 / 3,  -1 / 3, 2 ],
            [ 1 / 2,  0,      6 ],
            [ -1 / 3, 1 / 3,  2 ],
            [ -3 / 2, -1,     -36 ],
        ],
    }
};
my ($model, $initial_tableau, $optimal_tableau, $optimal_tableau_piddle,
    $final_tableau_object, $final_matrix_as_float, $full_test_name);

for my $test (keys %{$tests}) {

    $initial_tableau = $tests->{$test}->{initial_tableau};
    $optimal_tableau = $tests->{$test}->{optimal_tableau};

    $model                = 'float';
    $full_test_name       = $test . ' - ' . ucfirst $model;
    $final_tableau_object = solve_LP($model, $initial_tableau);
    ok(
        are_matrices_equal_within_EPSILON(
            $final_tableau_object->tableau,
            $optimal_tableau
        ),
        $full_test_name
    );

    $model                  = 'piddle';
    $full_test_name         = $test . ' - ' . ucfirst $model;
    $final_tableau_object   = solve_LP($model, $initial_tableau);
    $optimal_tableau_piddle = pdl $optimal_tableau;
    ok(
        piddles_are_equal(
            $optimal_tableau_piddle, $final_tableau_object->tableau
        ),
        $full_test_name
    );

    $model                = 'rational';
    $full_test_name       = $test . ' - ' . ucfirst $model;
    $final_tableau_object = solve_LP($model, $initial_tableau);
    $final_matrix_as_float =
      float_matrix_from_fraction_tableau($final_tableau_object);
    ok(
        are_matrices_equal_within_EPSILON(
            $final_matrix_as_float, $optimal_tableau
        ),
        $full_test_name
    );
}

=head1 Subroutines

=head2 solve_LP

Solver subroutine for a given model and initial tableau.

=cut

sub solve_LP {
    my $model   = shift;
    my $tableau = shift;

    # Extra step for piddles.
    #    $tableau = pdl $tableau if ( $model eq 'piddle' );

    my $tableau_object =
        $model eq 'float' ? Algorithm::Simplex::Float->new(tableau => $tableau)
      : $model eq 'piddle' ? Algorithm::Simplex::PDL->new(tableau => $tableau)
      : $model eq 'rational'
      ? Algorithm::Simplex::Rational->new(tableau => $tableau)
      : die "The model type: $model could not be found.";

    # Extra step for rationals (fracts)
    #    $tableau_object
    #      ->convert_natural_number_tableau_to_fractional_object_tableau
    #      if ( $model eq 'rational' );

    my $counter = 1;
    until ($tableau_object->is_optimal) {
        my ($pivot_row_number, $pivot_column_number) =
          $tableau_object->determine_bland_pivot_row_and_column_numbers;
        $tableau_object->pivot($pivot_row_number, $pivot_column_number);
        $tableau_object->exchange_pivot_variables($pivot_row_number,
            $pivot_column_number);
        $counter++;

        # Too many pivots?
        if ($counter > $tableau_shell->MAXIMUM_PIVOTS) {
            warn "HALT: Exceeded the maximum number of pivots allowed: "
              . $tableau_shell->MAXIMUM_PIVOTS . "\n";
            return 0;
        }
    }
    return $tableau_object;
}

sub piddles_are_equal {
    my $pdl_1 = shift;
    my $pdl_2 = shift;

    my $result_pdl = abs($pdl_1 - $pdl_2);
    if (all $result_pdl < $tableau_shell->EPSILON) {
        return 1;
    }
    else {
        return 0;
    }
}

sub are_matrices_equal_within_EPSILON {
    my $M_1 = shift;
    my $M_2 = shift;

    my $nbr_of_rows = scalar @{$M_1};
    my $nbr_of_cols = scalar @{ $M_1->[0] };
    for my $i (0 .. $nbr_of_rows - 1) {
        for my $j (0 .. $nbr_of_cols - 1) {
            if (
                abs($M_1->[$i]->[$j] - $M_2->[$i]->[$j]) >
                $tableau_shell->EPSILON)
            {
                warn "DIFF: " . abs($M_1->[$i]->[$j] - $M_2->[$i]->[$j]) . "\n";
                return 0;
            }
        }
    }
    return 1;
}

sub float_matrix_from_fraction_tableau {
    my $fraction_tableau = shift;

    my $float_matrix;
    for my $i (0 .. $fraction_tableau->number_of_rows) {
        for my $j (0 .. $fraction_tableau->number_of_columns) {
            my $fraction_object = $fraction_tableau->tableau->[$i]->[$j];
            my $float           = $fraction_object->{n} / $fraction_object->{d};
            $float_matrix->[$i]->[$j] = $float;
        }
    }
    return $float_matrix;

}
