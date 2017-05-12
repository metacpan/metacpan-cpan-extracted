package Algorithm::Simplex::Float;
use Moo;
extends 'Algorithm::Simplex';
with 'Algorithm::Simplex::Role::Solve';
use namespace::clean;

my $one          = 1;
my $neg_one      = -1;
my $EMPTY_STRING = q();

=head1 Name

Algorithm::Simplex::Float - Float model of the Simplex Algorithm

=head1 Methods

=head2 pivot

Do the algebra of a Tucker/Bland pivot.  i.e. Traverse from one node to an 
adjacent node along the Simplex of feasible solutions.

=cut

sub pivot {

    my $self                = shift;
    my $pivot_row_number    = shift;
    my $pivot_column_number = shift;

    # Do tucker algebra on pivot row
    my $scale =
      $one / ($self->tableau->[$pivot_row_number]->[$pivot_column_number]);
    for my $j (0 .. $self->number_of_columns) {
        $self->tableau->[$pivot_row_number]->[$j] =
          $self->tableau->[$pivot_row_number]->[$j] * ($scale);
    }
    $self->tableau->[$pivot_row_number]->[$pivot_column_number] = $scale;

    # Do tucker algebra elsewhere
    for my $i (0 .. $self->number_of_rows) {
        if ($i != $pivot_row_number) {

            my $neg_a_ic =
              $self->tableau->[$i]->[$pivot_column_number] * ($neg_one);
            for my $j (0 .. $self->number_of_columns) {
                $self->tableau->[$i]->[$j] =
                  $self->tableau->[$i]->[$j] +
                  ($neg_a_ic * ($self->tableau->[$pivot_row_number]->[$j]));
            }
            $self->tableau->[$i]->[$pivot_column_number] = $neg_a_ic * ($scale);
        }
    }

    return;
}

# Count pivots made
after 'pivot' => sub {
    my $self = shift;

    # TODO: Confirm whether clear is needed or not. Appears not in testing.
    # $self->clear_display_tableau;
    $self->number_of_pivots_made($self->number_of_pivots_made + 1);
    return;
};

=head2 is_optimal

Check the basement row to see if any positive entries exist.  Existence of
a positive entry means the solution is sub-optimal and optimal otherwise.
This is how we decide when to stop the algorithm.

Use EPSILON instead of zero because we're dealing with floats (imperfect numbers).

=cut

sub is_optimal {
    my $self = shift;

    for my $j (0 .. $self->number_of_columns - 1) {
        if ($self->tableau->[ $self->number_of_rows ]->[$j] > $self->EPSILON) {
            return 0;
        }
    }
    return 1;
}

=head2 determine_simplex_pivot_columns

Find the columns that are candiates for pivoting in.  This is based on 
their basement row value being greater than zero.

=cut

sub determine_simplex_pivot_columns {
    my $self = shift;

    my @simplex_pivot_column_numbers;

# Assumes the existence of at least one pivot (use optimality check to insure this)
# According to Nering and Tucker (1993) page 26
# "selected a column with a positive entry in the basement row."
# NOTE: My intuition indicates a pivot could still take place but no gains would be made
# when the cost is zero.  This would not lead us to optimality, but if we were
# already in an optimal state if may (should) lead to another optimal state.
# This would only apply then in the optimal case, i.e. all entries non-positive.
    for my $col_num (0 .. $self->number_of_columns - 1) {
        if ($self->tableau->[ $self->number_of_rows ]->[$col_num] >
            $self->EPSILON)
        {
            push(@simplex_pivot_column_numbers, $col_num);
        }
    }
    return (@simplex_pivot_column_numbers);
}

=head2 determine_positive_ratios

Once a a pivot column has been chosen then we choose a pivot row based on 
the smallest postive ration.  This function is a helper to achieve that.

=cut

sub determine_positive_ratios {
    my $self                = shift;
    my $pivot_column_number = shift;

# Build Ratios and Choose row(s) that yields min for the bland simplex column as a candidate pivot point.
# To be a Simplex pivot we must not consider negative entries
    my @positive_ratios;
    my @positive_ratio_row_numbers;

    #print "Column: $possible_pivot_column\n";
    for my $row_num (0 .. $self->number_of_rows - 1) {
        if ($self->tableau->[$row_num]->[$pivot_column_number] > $self->EPSILON)
        {
            push(@positive_ratios,
                $self->tableau->[$row_num]->[ $self->number_of_columns ] /
                  $self->tableau->[$row_num]->[$pivot_column_number]);

            # Track the rows that give ratios
            push @positive_ratio_row_numbers, $row_num;
        }
    }

    return (\@positive_ratios, \@positive_ratio_row_numbers);
}

=head2 current_solution

Return both the primal (max) and dual (min) solutions for the tableau.

=cut

sub current_solution {
    my $self = shift;

    # Report the Current Solution as primal dependents and dual dependents.
    my @y = @{ $self->y_variables };
    my @u = @{ $self->u_variables };

    # Dependent Primal Variables
    my %primal_solution;
    for my $i (0 .. $#y) {
        $primal_solution{ $y[$i]->{generic} } =
          $self->tableau->[$i]->[ $self->number_of_columns ];
    }

    # Dependent Dual Variables
    my %dual_solution;
    for my $j (0 .. $#u) {
        $dual_solution{ $u[$j]->{generic} } =
          $self->tableau->[ $self->number_of_rows ]->[$j] * -1;
    }

    return (\%primal_solution, \%dual_solution);
}

=head2  is_basic_feasible_solution

Check if we have any negative values in the right hand column.

=cut

sub is_basic_feasible_solution {
    my $self = shift;

    for my $i (0 .. $self->number_of_rows - 1) {
        if ($self->tableau->[$i]->[ $self->number_of_columns ] <
            -($self->EPSILON))
        {
            return 0;
        }
    }
    return 1;
}

1;
