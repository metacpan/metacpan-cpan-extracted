package Algorithm::SAT::Backtracking::DPLL;
use Storable qw(dclone);
use Data::Dumper;
use strict;
use warnings;
our $VERSION = "0.13";

# this allow to switch the parent implementation (needed for the Ordered alternative)
sub import {
    my ( $class, $flag ) = @_;
    if ($flag) {
        eval "use base '$flag'";
    }
    else {
        eval "use base 'Algorithm::SAT::Backtracking'";
    }
}

sub solve {

    # ### solve
    #
    # * `variables` is the list of all variables
    # * `clauses` is an array of clauses.
    # * `model` is a set of variable assignments.
    my ( $self, $variables, $clauses, $model ) = @_;
    $model = {} if !defined $model;
    my $impurity = dclone($clauses);

    if ( !exists $self->{_impurity} ) {
        $self->{_impurity}->{$_}++ for ( map { @{$_} } @{$impurity} );
    }

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
    return 0 if !$self->_consistency_check( $clauses, $model );

    $model = $self->_up( $variables, $clauses, $model )
        ;    # find unit clauses and sets them

    return 0 if !$self->_consistency_check( $clauses, $model );

    # TODO: pure unit optimization
    # XXX: not working

#   $self->_pure($_)
#     ? ( $model->{$_} = 1 and $self->_remove_clause_if_contains( $_, $clauses ) )
#     : $self->_pure( "-" . $_ )
#     ? ( $model->{$_} = 0 and $self->_remove_clause_if_contains( $_, $clauses ) )
#    : ()
#     for @{$variables};
# return $model if ( @{$clauses} == 0 );    #we were lucky

    # XXX: end

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

sub _consistency_check {
    my ( $self, $clauses, $model ) = @_;
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
    return 1;

}

sub _pure {
    my ( $self, $literal ) = @_;

    #     Pure literal rule

    # if a variable only occurs positively in a formula, set it to true
    # if a variable only occurs negated in a formula, set it to false

    my $opposite
        = substr( $literal, 0, 1 ) eq "-"
        ? substr( $literal, 1 )
        : "-" . $literal;
    return 1
        if (
        (   exists $self->{_impurity}->{$literal}
            and $self->{_impurity}->{$literal} != 0
        )
        and (
            !exists $self->{_impurity}->{$opposite}
            or ( exists $self->{_impurity}->{$opposite}
                and $self->{_impurity}->{$opposite} == 0 )
        )
        );

    #   print STDERR "$literal is IMpure\n" and
    return 0;
}

sub _up {
    my ( $self, $variables, $clauses, $model ) = @_;
    $model = {} if !defined $model;

    #Finding single clauses that must be true, and updating the model
    ( @{$_} != 1 )
        ? ()
        : ( substr( $_->[0], 0, 1 ) eq "-" ) ? (
        $self->_remove_literal( substr( $_->[0], 1 ), $clauses, $model
            ) #remove the positive clause form OR's and add it to the model with a false value
        )
        : (     $self->_add_literal( "-" . $_->[0], $clauses )
            and $model->{ $_->[0] }
            = 1
        ) # if the literal is present, remove it from SINGLE ARRAYS in $clauses and add it to the model with a true value
        for ( @{$clauses} );
    return $model;
}

sub _remove_literal {
    my ( $self, $literal, $clauses, $model ) = @_;

    return
            if $model
        and exists $model->{$literal}
        and $model->{$literal} == 0;    #avoid cycle if already set
        #remove the literal from the model (set to false)
    $model->{$literal} = 0;

    #remove the literal from the model (set to false) and delete it from index

    $self->_delete_from_index( $literal, $clauses );

    return 1;
}

sub _add_literal {
    my ( $self, $literal, $clauses, $model ) = @_;

    $literal
        = ( substr( $literal, 0, 1 ) eq "-" )
        ? $literal
        : substr( $literal, 1 );
    return
            if $model
        and exists $model->{$literal}
        and $model->{$literal} == 1;    #avoid cycle if already set
     #remove the literal from the model (set to false) and delete it from index
    $model->{$literal} = 1;
    $self->_delete_from_index( $literal, $clauses );
    return 1;
}

sub _delete_from_index {
    my ( $self, $string, $list ) = @_;

    foreach my $c ( @{$list} ) {
        next if @{$c} <= 1;
        for ( my $index = scalar( @{$c} ); $index >= 0; --$index ) {
            do {
                splice( @{$c}, $index, 1 );
                $self->{_impurity}->{$string}--;
                }
                if $c->[$index]
                and $c->[$index] eq $string;    # remove certain elements
        }
    }
}

sub _remove_clause_if_contains {
    my ( $self, $literal, $list ) = @_;

    my $index = 0;
    while ( $index < scalar @{$list} ) {
        splice( @{$list}, $index, 1 )
            if grep { $_ eq $literal } @{ $list->[$index] };
        $index++;
    }

}

1;

=encoding utf-8

=head1 NAME

Algorithm::SAT::Backtracking::DPLL - A DPLL Backtracking SAT solver written in pure Perl

=head1 SYNOPSIS


    # You can use it with Algorithm::SAT::Expression
    use Algorithm::SAT::Expression;

    my $expr = Algorithm::SAT::Expression->new->with("Algorithm::SAT::Backtracking::DPLL");
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

Algorithm::SAT::Backtracking::DPLL is a pure Perl implementation of a SAT Backtracking solver.

Look at L<Algorithm::SAT::Backtracking> for a theory description.

The DPLL variant applies the "unit propagation" and the "pure literal" technique to be faster.

Look also at the tests file for an example of usage.

L<Algorithm::SAT::Expression> use this module to solve Boolean expressions.

=head1 METHODS

Inherits all the methods from L<Algorithm::SAT::Backtracking> and implements new private methods to use the unit propagation and pure literal rule techniques.

=head1 LICENSE

Copyright (C) mudler.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

mudler E<lt>mudler@dark-lab.netE<gt>

=head1 SEE ALSO

L<Algorithm::SAT::Expression>, L<Algorithm::SAT::Backtracking>, L<Algorithm::SAT::Backtracking::Ordered>, L<Algorithm::SAT::Backtracking::Ordered::DPLL>

=cut

