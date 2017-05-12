package Algorithm::Simplex::Rational;
use Moo;
extends 'Algorithm::Simplex';
with 'Algorithm::Simplex::Role::Solve';
use MooX::Types::MooseLike::Base qw( InstanceOf ArrayRef Str );
use Math::Cephes::Fraction qw(:fract);
use Math::BigRat;
use namespace::clean;

my $one     = fract(1, 1);
my $neg_one = fract(1, -1);

has '+tableau' => (
    isa => ArrayRef [ ArrayRef [ InstanceOf ['Math::Cephes::Fraction'] ] ],
    coerce => sub { &make_fractions($_[0]) },
);

has '+display_tableau' => (
    isa => ArrayRef [ ArrayRef [Str] ],
    coerce => sub { &display_fractions($_[0]) },
);

sub _build_objective_function_value {
    my $self = shift;
    return $self->tableau->[ $self->number_of_rows ]
      ->[ $self->number_of_columns ]->rmul($neg_one)->as_string;
}

=head1 Name

Algorithm::Simplex::Rational - Rational model of the Simplex Algorithm

=head1 Methods

=head2 pivot

Do the algebra of a Tucker/Bland Simplex pivot.  i.e. Traverse from one node 
to an adjacent node along the Simplex of feasible solutions.

=cut

sub pivot {

    my $self                = shift;
    my $pivot_row_number    = shift;
    my $pivot_column_number = shift;

    # Do tucker algebra on pivot row
    my $scale =
      $one->rdiv($self->tableau->[$pivot_row_number]->[$pivot_column_number]);
    for my $j (0 .. $self->number_of_columns) {
        $self->tableau->[$pivot_row_number]->[$j] =
          $self->tableau->[$pivot_row_number]->[$j]->rmul($scale);
    }
    $self->tableau->[$pivot_row_number]->[$pivot_column_number] = $scale;

    # Do tucker algebra elsewhere
    for my $i (0 .. $self->number_of_rows) {
        if ($i != $pivot_row_number) {

            my $neg_a_ic =
              $self->tableau->[$i]->[$pivot_column_number]->rmul($neg_one);
            for my $j (0 .. $self->number_of_columns) {
                $self->tableau->[$i]->[$j] =
                  $self->tableau->[$i]->[$j]->radd(
                    $neg_a_ic->rmul($self->tableau->[$pivot_row_number]->[$j]));
            }
            $self->tableau->[$i]->[$pivot_column_number] =
              $neg_a_ic->rmul($scale);
        }
    }

    return;
}
after 'pivot' => sub {
    my $self = shift;
    $self->number_of_pivots_made($self->number_of_pivots_made + 1);
    return;
};

=head2 determine_simplex_pivot_columns

Look at the basement row to see where positive entries exists. 
Columns with positive entries in the basement row are pivot column candidates.

Should run optimality test, is_optimal, first to insure 
at least one positive entry exists in the basement row which then 
means we can increase the objective value for the maximization problem.

=cut 

sub determine_simplex_pivot_columns {
    my $self = shift;

    my @simplex_pivot_column_numbers;
    for my $col_num (0 .. $self->number_of_columns - 1) {
        my $bottom_row_fraction =
          $self->tableau->[ $self->number_of_rows ]->[$col_num];
        my $bottom_row_numeric =
          $bottom_row_fraction->{n} / $bottom_row_fraction->{d};
        if ($bottom_row_numeric > 0) {
            push(@simplex_pivot_column_numbers, $col_num);
        }
    }
    return (@simplex_pivot_column_numbers);
}

=head2 determine_positive_ratios

Starting with the pivot column find the entry that yields the lowest
positive b to entry ratio that has lowest bland number in the event of ties.

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
        my $bottom_row_fraction =
          $self->tableau->[$row_num]->[$pivot_column_number];
        my $bottom_row_numeric =
          $bottom_row_fraction->{n} / $bottom_row_fraction->{d};

        if ($bottom_row_numeric > 0) {
            push(
                @positive_ratios,
                (
                    $self->tableau->[$row_num]->[ $self->number_of_columns ]
                      ->{n} *
                      $self->tableau->[$row_num]->[$pivot_column_number]->{d}
                  ) / (
                    $self->tableau->[$row_num]->[$pivot_column_number]->{n} *
                      $self->tableau->[$row_num]->[ $self->number_of_columns ]
                      ->{d}
                  )
            );

            # Track the rows that give ratios
            push @positive_ratio_row_numbers, $row_num;
        }
    }
    return (\@positive_ratios, \@positive_ratio_row_numbers);
}

=head2 is_optimal

Return 1 if the current solution is optimal, 0 otherwise.

Check basement row for having all non-positive entries which
would => optimal (while in phase 2).

=cut

sub is_optimal {
    my $self = shift;

    for my $j (0 .. $self->number_of_columns - 1) {
        my $basement_row_fraction =
          $self->tableau->[ $self->number_of_rows ]->[$j];
        my $basement_row_numeric =
          $basement_row_fraction->{n} / $basement_row_fraction->{d};
        if ($basement_row_numeric > 0) {
            return 0;
        }
    }
    return 1;
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
        my $rational = $self->tableau->[$i]->[ $self->number_of_columns ];
        $primal_solution{ $y[$i]->{generic} } = $rational->as_string;
    }

    # Dependent Dual Variables
    my %dual_solution;
    for my $j (0 .. $#u) {
        my $rational =
          $self->tableau->[ $self->number_of_rows ]->[$j]->rmul($neg_one);
        $dual_solution{ $u[$j]->{generic} } = $rational->as_string;
    }

    return (\%primal_solution, \%dual_solution);
}

=head2 Coercions

=head3 make_fractions

Make each rational entry a Math::Cephes::Fraction object
with the help of Math::BigRat

=cut

sub make_fractions {
    my $tableau = shift;

    for my $i (0 .. scalar @{$tableau} - 1) {
        for my $j (0 .. scalar @{ $tableau->[0] } - 1) {

            # Using Math::BigRat to make fraction from decimal
            my $x = Math::BigRat->new($tableau->[$i]->[$j]);
            $tableau->[$i]->[$j] = fract($x->numerator, $x->denominator);
        }
    }
    return $tableau;
}

=head3 display_fractions

Convert each fraction object entry into a string.

=cut

sub display_fractions {
    my $fraction_tableau = shift;

    my $display_tableau;
    for my $i (0 .. scalar @{$fraction_tableau} - 1) {
        for my $j (0 .. scalar @{ $fraction_tableau->[0] } - 1) {
            $display_tableau->[$i]->[$j] =
              $fraction_tableau->[$i]->[$j]->as_string;
        }
    }
    return $display_tableau;

}

1;
