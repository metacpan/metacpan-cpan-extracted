package Algorithm::Simplex::Role::Solve;
use Moo::Role;

=head1 Name

Algorithm::Simplex::Role::Solve - solve() method implemented as Moose role.

=cut

=head1 Synposis

    use Algorithm::Simplex::Rational;
    use Data::Dumper;
    my $matrix = [
        [ 5,  2,  30],
        [ 3,  4,  20],
        [10,  8,   0],
    ];
    my $tableau = Algorithm::Simplex::Rational->new( tableau => $matrix );
    $tableau->solve;
    print Dumper $tableau_object->display_tableau;
     
=cut    

requires(
    'tableau', 'determine_bland_pivot_row_and_column_numbers',
    'pivot',   'exchange_pivot_variables'
);

=head1 Methods

=head2 solve

Walk the simplex of feasible solutions by moving to an adjacent vertex
one step at a time.  Each vertex of the feasible region corresponds to
a tableau.

This solve() method assumes we are starting with a feasible solution.
This is referred to a phase 2 of the Simplex algorithm, where phase 1
is obtaining a feasible solution so phase 2 can be applied.

Returns 1 if an optimal solution is found, 0 otherwise.

=cut

sub solve {
    my $tableau_object = shift;

    my $counter = 1;
    until ($tableau_object->is_optimal) {
        my ($pivot_row_number, $pivot_column_number) =
          $tableau_object->determine_bland_pivot_row_and_column_numbers;
        $tableau_object->pivot($pivot_row_number, $pivot_column_number);
        $tableau_object->exchange_pivot_variables($pivot_row_number,
            $pivot_column_number);
        $counter++;

        # Too many pivots?
        if ($counter > $tableau_object->MAXIMUM_PIVOTS) {
            warn "HALT: Exceeded the maximum number of pivots allowed: "
              . $tableau_object->MAXIMUM_PIVOTS . "\n";
            return 0;
        }
    }

    return 1;
}

1;
