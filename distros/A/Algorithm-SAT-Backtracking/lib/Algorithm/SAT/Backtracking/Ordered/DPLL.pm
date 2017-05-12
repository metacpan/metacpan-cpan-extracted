package Algorithm::SAT::Backtracking::Ordered::DPLL;
use Hash::Ordered;
use base "Algorithm::SAT::Backtracking::DPLL";
use Algorithm::SAT::Backtracking::DPLL
    "Algorithm::SAT::Backtracking::Ordered";
use strict;
use warnings;
our $VERSION = "0.13";

##Ordered implementation, of course has its costs
sub solve {
    my ( $self, $variables, $clauses, $model ) = @_;
    $model = Hash::Ordered->new if !defined $model;
    return $self->SUPER::solve( $variables, $clauses, $model );
}

sub _up {
    my ( $self, $variables, $clauses, $model ) = @_;
    $model = Hash::Ordered->new if !defined $model;

    #Finding single clauses that must be true, and updating the model
    ( @{$_} != 1 )
        ? ()
        : ( substr( $_->[0], 0, 1 ) eq "-" ) ? (
        do {
            my $literal = substr( $_->[0], 1 );
            $model->set( $literal => 0 );
            $self->_delete_from_index( $literal, $clauses );
            }

#remove the positive clause form OR's and add it to the model with a false value
        )
        : (
                $self->_add_literal( "-" . $_->[0], $clauses )
            and $model->set( $_->[0] => 1 )

        ) # if the literal is present, remove it from SINGLE ARRAYS in $clauses and add it to the model with a true value
        for ( @{$clauses} );
    return $model;
}

sub _add_literal {
    my ( $self, $literal, $clauses, $model ) = @_;
    $literal
        = ( substr( $literal, 0, 1 ) eq "-" )
        ? $literal
        : substr( $literal, 1 );
    return
            if $model
        and $model->exists($literal)
        and $model->set( $literal, 1 );    #avoid cycle if already set
         #remove the literal from the model (set to false)
    $model->set( $literal, 1 );
    $self->_delete_from_index( $literal, $clauses );
    return 1;
}

sub _choice {
    my ( $self, $variables, $model ) = @_;
    my $choice;
    foreach my $variable ( @{$variables} ) {
        $choice = $variable and last if ( !$model->exists($variable) );
    }
    return $choice;
}

1;

=encoding utf-8

=head1 NAME

Algorithm::SAT::Backtracking::Ordered::DPLL - A DPLL Backtracking SAT ordered implementation

=head1 SYNOPSIS


    # You can use it with Algorithm::SAT::Expression
    use Algorithm::SAT::Expression;

    my $expr = Algorithm::SAT::Expression->new->with("Algorithm::SAT::Backtracking::Ordered::DPLL");
    $expr->or( '-foo@2.1', 'bar@2.2' );
    $expr->or( '-foo@2.3', 'bar@2.2' );
    $expr->or( '-baz@2.3', 'bar@2.3' );
    $expr->or( '-baz@1.2', 'bar@2.2' );
    my $model = $exp->solve();

    # Or you can use it directly:
    use Algorithm::SAT::Backtracking::Ordered::DPLL;
    my $solver = Algorithm::SAT::Backtracking::Ordered::DPLL->new;
    my $variables = [ 'blue', 'green', 'yellow', 'pink', 'purple' ];
    my $clauses = [
        [ 'blue',  'green',  '-yellow' ],
        [ '-blue', '-green', 'yellow' ],
        [ 'pink', 'purple', 'green', 'blue', '-yellow' ]
    ];

    my $model = $solver->solve( $variables, $clauses );


=head1 DESCRIPTION


Algorithm::SAT::Backtracking::Ordered::DPLL is a pure Perl implementation of a DPLL SAT Backtracking solver, in this variant of L<Algorithm::SAT::Backtracking::DPLL> we keep the order of the model updates and return a L<Hash::Ordered> as result.

Look at L<Algorithm::SAT::Backtracking::DPLL> for a theory description.

Look also at the test file for an example of usage.

L<Algorithm::SAT::Expression> use this module to solve Boolean expressions.

=head1 METHODS

Inherits all the methods from L<Algorithm::SAT::Backtracking::DPLL> and override/implements the following:

=head2 SOLVE

    $expr->solve();

in this case returns a L<Hash::Ordered>.

=head1 LICENSE

Copyright (C) mudler.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

mudler E<lt>mudler@dark-lab.netE<gt>

=head1 SEE ALSO

L<Algorithm::SAT::Expression>, L<Algorithm::SAT::Backtracking>, L<Algorithm::SAT::Backtracking::Ordered>, L<Algorithm::SAT::Backtracking::DPLL>

=cut

