package Algorithm::Simplex;
use Moo;
use MooX::Types::MooseLike::Base qw( ArrayRef HashRef Num Int Str );
use namespace::clean;
use Carp;

our $VERSION = '0.44';

has tableau => (
    is       => 'rw',
    isa      => ArrayRef [ ArrayRef [Num] ],
    required => 1,
);

has display_tableau => (
    is  => 'lazy',
    isa => ArrayRef [ ArrayRef [Str] ],
);

has objective_function_value => (
    is  => 'lazy',
    isa => Str,
);

has number_of_rows => (
    is       => 'lazy',
    isa      => Int,
    init_arg => undef,
);

has number_of_columns => (
    is       => 'lazy',
    isa      => Int,
    init_arg => undef,
);

has number_of_pivots_made => (
    is      => 'rw',
    isa     => Int,
    default => sub { 0 },
);

has EPSILON => (
    is      => 'rw',
    isa     => Num,
    default => sub { 1e-13 },
);

has MAXIMUM_PIVOTS => (
    is      => 'rw',
    isa     => Int,
    default => sub { 200 },
);

has x_variables => (
    is  => 'lazy',
    isa => ArrayRef [ HashRef [Str] ],
);
has 'y_variables' => (
    is  => 'lazy',
    isa => ArrayRef [ HashRef [Str] ],
);
has u_variables => (
    is  => 'lazy',
    isa => ArrayRef [ HashRef [Str] ],
);
has v_variables => (
    is  => 'lazy',
    isa => ArrayRef [ HashRef [Str] ],
);

=head1 Name

Algorithm::Simplex - Simplex Algorithm Implementation using Tucker Tableaux

=head1 Synopsis

Given a linear program formulated as a Tucker tableau, a 2D matrix or 
ArrayRef[ArrayRef] in Perl, seek an optimal solution.

    use Algorithm::Simplex::Rational;
    my $matrix = [
        [ 5,  2,  30],
        [ 3,  4,  20],
        [10,  8,   0],
    ];
    my $tableau = Algorithm::Simplex::Rational->new( tableau => $matrix );
    $tableau->solve;
    my ($primal_solution, $dual_solution) = $tableau->current_solution;

=head1 Methods

=head2 _build_number_of_rows 

Set the number of rows.
This number represent the number of rows of the
coefficient matrix.  It is one less than the full tableau.

=cut

sub _build_number_of_rows {
    my $self = shift;

    return scalar @{ $self->tableau } - 1;
}

=head2 _build_number_of_columns 

Set the number of columns given the tableau matrix.
This number represent the number of columns of the
coefficient matrix.

=cut

sub _build_number_of_columns {
    my $self = shift;

    return scalar @{ $self->tableau->[0] } - 1;
}

=head2 _build_x_variables

Set x variable names for the given tableau, x1, x2 ... xn
These are the decision variables of the maximization problem.
The maximization problem is read horizontally in a Tucker tableau.

=cut

sub _build_x_variables {
    my $self = shift;

    my $x_vars;
    for my $j (0 .. $self->number_of_columns - 1) {
        my $x_index = $j + 1;
        $x_vars->[$j]->{'generic'} = 'x' . $x_index;
    }
    return $x_vars;
}

=head2 _build_y_variables

Set y variable names for the given tableau.
These are the slack variables of the maximization problem.

=cut

sub _build_y_variables {
    my $self = shift;

    my $y_vars;
    for my $i (0 .. $self->number_of_rows - 1) {
        my $y_index = $i + 1;
        $y_vars->[$i]->{'generic'} = 'y' . $y_index;
    }
    return $y_vars;
}

=head2 _build_u_variables

Set u variable names for the given tableau.
These are the slack variables of the minimization problem.

=cut

sub _build_u_variables {
    my $self = shift;

    my $u_vars;
    for my $j (0 .. $self->number_of_columns - 1) {
        my $u_index = $j + 1;
        $u_vars->[$j]->{'generic'} = 'u' . $u_index;
    }
    return $u_vars;
}

=head2 _build_v_variables

Set v variable names for the given tableau: v1, v2 ... vm
These are the decision variables for the minimization problem.
The minimization problem is read horizontally in a Tucker tableau.

=cut

sub _build_v_variables {
    my $self = shift;

    my $v_vars;
    for my $i (0 .. $self->number_of_rows - 1) {
        my $v_index = $i + 1;
        $v_vars->[$i]->{'generic'} = 'v' . $v_index;
    }
    return $v_vars;
}

sub _build_display_tableau {
    my $self = shift;
    return $self->tableau;
}

sub _build_objective_function_value {
    my $self = shift;
    return $self->display_tableau->[ $self->number_of_rows ]
      ->[ $self->number_of_columns ] * (-1);
}

=head2 get_bland_number_for

Given a column number (which represents a u variable) build the bland number 
from the generic variable name.

=cut

sub get_bland_number_for {
    my $self          = shift;
    my $variable_type = shift;
    my $variables     = $variable_type . '_variables';
    my $index         = shift;
    my $generic_name  = $self->$variables->[$index]->{'generic'};

    my ($var, $num);
    if ($generic_name =~ m{(.)(\d+)}mxs) {
        $var = $1;
        $num = $2;
    }
    else {
        croak "The generic variable names have format issues.\n";
    }
    my $start_num =
        $var eq 'x' ? 1
      : $var eq 'y' ? 2
      : $var eq 'v' ? 4
      : $var eq 'u' ? 3
      :               croak "Variable name: $var does not equal x, y, v or u";
    my $bland_number = $start_num . $num;
    return $bland_number;
}

=head2 determine_bland_pivot_column_number

Find the pivot column using Bland ordering technique to prevent cycles.

=cut

sub determine_bland_pivot_column_number {
    my ($self, @simplex_pivot_column_numbers) = @_;

    my @bland_number_for_simplex_pivot_column;
    foreach my $col_number (@simplex_pivot_column_numbers) {
        push @bland_number_for_simplex_pivot_column,
          $self->get_bland_number_for('x', $col_number);
    }

# Pass blands number to routine that returns index of location where minimum bland occurs.
# Use this index to return the bland column column number from @positive_profit_column_numbers
    my @bland_column_number_index =
      $self->min_index(\@bland_number_for_simplex_pivot_column);
    my $bland_column_number_index = $bland_column_number_index[0];

    return $simplex_pivot_column_numbers[$bland_column_number_index];
}

=head2 determine_bland_pivot_row_number

Find the pivot row using Bland ordering technique to prevent cycles.

=cut

sub determine_bland_pivot_row_number {
    my ($self, $positive_ratios, $positive_ratio_row_numbers) = @_;

    # Now that we have the ratios and their respective rows we can find the min
    # and then select the lowest bland min if there are ties.
    my @min_indices = $self->min_index($positive_ratios);
    my @min_ratio_row_numbers =
      map { $positive_ratio_row_numbers->[$_] } @min_indices;
    my @bland_number_for_min_ratio_rows;
    foreach my $row_number (@min_ratio_row_numbers) {
        push @bland_number_for_min_ratio_rows,
          $self->get_bland_number_for('y', $row_number);
    }

# Pass blands number to routine that returns index of location where minimum bland occurs.
# Use this index to return the bland row number.
    my @bland_min_ratio_row_index =
      $self->min_index(\@bland_number_for_min_ratio_rows);
    my $bland_min_ratio_row_index = $bland_min_ratio_row_index[0];
    return $min_ratio_row_numbers[$bland_min_ratio_row_index];
}

=head2 min_index

Determine the index of the element with minimal value.  
Used when finding bland pivots.

=cut

sub min_index {
    my ($self, $l) = @_;
    my $n = @{$l};
    if (!$n) {
        return ();
    }
    my $v_min = $l->[0];
    my @i_min = (0);

    for my $i (1 .. $n - 1) {
        if ($l->[$i] < $v_min) {
            $v_min = $l->[$i];
            @i_min = ($i);
        }
        elsif ($l->[$i] == $v_min) {
            push @i_min, $i;
        }
    }
    return @i_min;

}

=head2 exchange_pivot_variables

Exchange the variables when a pivot is done.  The method pivot() does the
algrebra while this method does the variable swapping, and thus tracking of 
what variables take on non-zero values.  This is needed to accurately report
an optimal solution.

=cut

sub exchange_pivot_variables {
    my $self                = shift;
    my $pivot_row_number    = shift;
    my $pivot_column_number = shift;

    # exchange variables based on $pivot_column_number and $pivot_row_number
    my $increasing_primal_variable = $self->x_variables->[$pivot_column_number];
    my $zeroeing_primal_variable   = $self->y_variables->[$pivot_row_number];
    $self->x_variables->[$pivot_column_number] = $zeroeing_primal_variable;
    $self->y_variables->[$pivot_row_number]    = $increasing_primal_variable;

    my $increasing_dual_variable = $self->v_variables->[$pivot_row_number];
    my $zeroeing_dual_variable   = $self->u_variables->[$pivot_column_number];
    $self->v_variables->[$pivot_row_number]    = $zeroeing_dual_variable;
    $self->u_variables->[$pivot_column_number] = $increasing_dual_variable;
    return;
}

=head2 get_row_and_column_numbers 

Get the dimensions of the tableau.

=cut

sub get_row_and_column_numbers {
    my $self = shift;
    return $self->number_of_rows, $self->number_of_columns;
}

=head2 determine_bland_pivot_row_and_column_numbers

Higher level function that uses others to return the (bland) pivot point.

=cut

sub determine_bland_pivot_row_and_column_numbers {
    my $self = shift;

    my @simplex_pivot_columns = $self->determine_simplex_pivot_columns;
    my $pivot_column_number =
      $self->determine_bland_pivot_column_number(@simplex_pivot_columns);
    my ($positive_ratios, $positive_ratio_row_numbers) =
      $self->determine_positive_ratios($pivot_column_number);
    my $pivot_row_number =
      $self->determine_bland_pivot_row_number($positive_ratios,
        $positive_ratio_row_numbers);

    return ($pivot_row_number, $pivot_column_number);
}

1;

__END__

=head1 Authors

Mateu X. Hunter C<hunter@missoula.org>

Strong design influence by George McRae at the University of Montana.

#moose for solid assistance in the refactor: particularly _build_* approach 
and PDL + Moose namespace management, 'inner'.

=head1 Copyright 

Copyright 2009, Mateu X. Hunter

=head1 License

You may distribute this code under the same terms as Perl itself.

=head1 Description

Base class for the Simplex model using Tucker tableaus.  

The implementation is currently limited to phase II,
i.e. one must start with a feasible solution.

This class defines some of the methods concretely, and others such as:

=over 3

=item *

pivot

=item *

is_optimal

=item *

determine_positive_ratios

=item *

determine_simplex_pivot_columns

=back

are implemented in one of the three model types:

=over 3

=item *

Float

=item *

Rational

=item *

PDL

=back

=head1 Variables

We have implicit variable names: x1, x2 ... , y1, y2, ... , 
u1, u2 ... , v1, v2 ...

Our variables are represented by:

    x, y, u, and v 

as found in Nering and Tuckers' book. 

x and y are for the primal LP while u and v belong to the dual LP.

These variable names are set using the lazy feature of Moo.

=head1 Limitations

The API is stabilizing, but still subject to change.

The algorithm requires that the initial tableau be a feasible solution.

=head1 Development

http://github.com/mateu/Algorithm-Simplex

=cut
