package Algorithm::SAT::Backtracking;
use strict;
use warnings;
use Storable qw(dclone);

# This is an extremely simple implementation of the 'backtracking' algorithm for
# solving boolean satisfiability problems. It contains no optimizations.

# The input consists of a boolean expression in Conjunctive Normal Form.
# This means it looks something like this:
#
# `(blue OR green) AND (green OR NOT yellow)`
#
# We encode this as an array of strings with a `-` in front for negation:
#
# `[['blue', 'green'], ['green', '-yellow']]`

our $VERSION = "0.13";

sub new {
    return bless {}, shift;
}

sub solve {

    # ### solve
    #
    # * `variables` is the list of all variables
    # * `clauses` is an array of clauses.
    # * `model` is a set of variable assignments.
    my ( $self, $variables, $clauses, $model ) = @_;
    $model = {} if !defined $model;

    # If every clause is satisfiable, return the model which worked.

    return $model
        if (
        (   grep {
                ( defined $self->satisfiable( $_, $model )
                        and $self->satisfiable( $_, $model ) == 1 )
                    ? 0
                    : 1
            } @{$clauses}
        ) == 0
        );

    # If any clause is **exactly** false, return `false`; this model will not
    # work.
    return 0
        if (
        (   grep {
                ( defined $self->satisfiable( $_, $model )
                        and $self->satisfiable( $_, $model ) == 0 )
                    ? 1
                    : 0
            } @{$clauses}
        ) > 0
        );

    # Choose a new value to test by simply looping over the possible variables
    # and checking to see if the variable has been given a value yet.

    my $choice = $self->_choice( $variables, $model );

    # If there are no more variables to try, return false.

    return 0 if ( !$choice );

    # Recurse into two cases. The variable we chose will need to be either
    # true or false for the expression to be satisfied.
    return $self->solve( $variables, $clauses,
        $self->update( $model, $choice, 1 ) )    #true
        || $self->solve( $variables, $clauses,
        $self->update( $model, $choice, 0 ) );    #false
}

sub _choice {
    my ( undef, $variables, $model ) = @_;

    my $choice;
    foreach my $variable ( @{$variables} ) {
        $choice = $variable and last if ( !exists $model->{$variable} );
    }
    return $choice;
}

# ### update
# Copies the model, then sets `choice` = `value` in the model, and returns it.
sub update {
    my ( $self, $copy, $choice, $value ) = @_;
    $copy = dclone($copy);

    $copy->{$choice} = $value;
    return $copy;
}

# ### resolve
# Resolve some variable to its actual value, or undefined.
sub resolve {
    my ( undef, $var, $model ) = @_;

    if ( substr( $var, 0, 1 ) eq "-" ) {
        my $value = $model->{ substr( $var, 1 ) };
        return !defined $value ? undef : $value == 0 ? 1 : 0;
    }
    else {
        return $model->{$var};
    }
}

# ### satisfiable
# Determines whether a clause is satisfiable given a certain model.
sub satisfiable {
    my ( $self, $clauses, $model ) = @_;

    my @clause = @{$clauses};

    # If every variable is false, then the clause is false.
    return 0
        if (
        (   grep {
                ( defined $self->resolve( $_, $model )
                        and $self->resolve( $_, $model ) == 0 )
                    ? 0
                    : 1
            } @{$clauses}
        ) == 0
        );

    #If any variable is true, then the clause is true.
    return 1
        if (
        (   grep {
                ( defined $self->resolve( $_, $model )
                        and $self->resolve( $_, $model ) == 1 )
                    ? 1
                    : 0
            } @{$clauses}
        ) > 0
        );

    # Otherwise, we don't know what the clause is.
    return undef;
}

1;
__END__

=encoding utf-8

=head1 NAME

Algorithm::SAT::Backtracking - A simple Backtracking SAT solver written in pure Perl

=head1 SYNOPSIS


    # You can use it with Algorithm::SAT::Expression
    use Algorithm::SAT::Expression;

    my $expr = Algorithm::SAT::Expression->new->with("Algorithm::SAT::Backtracking"); #Uses Algorithm::SAT::Backtracking by default, so with() it's not necessary in this case
    $expr->or( '-foo@2.1', 'bar@2.2' );
    $expr->or( '-foo@2.3', 'bar@2.2' );
    $expr->or( '-baz@2.3', 'bar@2.3' );
    $expr->or( '-baz@1.2', 'bar@2.2' );
    my $model = $exp->solve();

    # Or you can use it directly:
    use Algorithm::SAT::Backtracking;
    my $solver = Algorithm::SAT::Backtracking->new;
    my $variables = [ 'blue', 'green', 'yellow', 'pink', 'purple' ];
    my $clauses = [
        [ 'blue',  'green',  '-yellow' ],
        [ '-blue', '-green', 'yellow' ],
        [ 'pink', 'purple', 'green', 'blue', '-yellow' ]
    ];

    my $model = $solver->solve( $variables, $clauses );

=head1 DESCRIPTION

Algorithm::SAT::Backtracking is a pure Perl implementation of a simple SAT Backtracking solver.

In computer science, the Boolean Satisfiability Problem (sometimes called Propositional Satisfiability Problem and abbreviated as I<SATISFIABILITY> or I<SAT>) is the problem of determining if there exists an interpretation that satisfies a given Boolean formula. In other words, it asks whether the variables of a given Boolean formula can be consistently replaced by the values B<TRUE> or B<FALSE> in such a way that the formula evaluates to B<TRUE>. If this is the case, the formula is called satisfiable. On the other hand, if no such assignment exists, the function expressed by the formula is identically B<FALSE> for all possible variable assignments and the formula is unsatisfiable.

For example, the formula "a AND NOT b" is satisfiable because one can find the values a = B<TRUE> and b = B<FALSE>, which make (a AND NOT b) = TRUE. In contrast, "a AND NOT a" is unsatisfiable. More: L<https://en.wikipedia.org/wiki/Boolean_satisfiability_problem> .

Have a look also at the tests file for an example of usage.

L<Algorithm::SAT::Expression> use this module to solve Boolean expressions.

=head1 METHODS

=head2 solve()

The input consists of a boolean expression in Conjunctive Normal Form.
This means it looks something like this:

 `(blue OR green) AND (green OR NOT yellow)`

 We encode this as an array of strings with a `-` in front for negation:

    `[['blue', 'green'], ['green', '-yellow']]`

Hence, each row means an B<AND>, while a list groups two or more B<OR> clauses.

Returns 0 if the expression can't be solved with the given clauses, the model otherwise in form of a hash .

Have a look at L<Algorithm::SAT::Expression> to see how to use it in a less painful way.

=head2 resolve()

Uses the model to resolve some variable to its actual value, or undefined if not present.

    my $model = { blue => 1, red => 0 };
    my $a=$solver->resolve( "blue", $model );
    #$a = 1

=head2 satisfiable()

Determines whether a clause is satisfiable given a certain model.

    my $model
        = { pink => 1, purple => 0, green => 0, yellow => 1, red => 0 };
    my $a=$solver->satisfiable( [ 'purple', '-pink' ], $model );
    #$a = 0

=head2 update()

Copies the model, then sets `choice` = `value` in the model, and returns it.

    my $model
        = { pink => 1, red => 0, purple => 0, green => 0, yellow => 1 };
    my $new_model = $solver->update( $model, 'foobar', 1 );
    # now $new_model->{foobar} is 1

=head1 LICENSE

Copyright (C) mudler.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

mudler E<lt>mudler@dark-lab.netE<gt>

=head1 SEE ALSO

L<Algorithm::SAT::Expression>, L<Algorithm::SAT::Backtracking::DPLL>, L<Algorithm::SAT::Backtracking::Ordered>, L<Algorithm::SAT::Backtracking::Ordered::DPLL>

=cut

