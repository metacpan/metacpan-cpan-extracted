package Algorithm::SAT::Backtracking::Ordered;
use base 'Algorithm::SAT::Backtracking';
use strict;
use warnings;
use Hash::Ordered;
##Ordered implementation, of course has its costs
our $VERSION = "0.13";

sub _choice {
    my ( undef, $variables, $model ) = @_;

    my $choice;
    foreach my $variable ( @{$variables} ) {
        $choice = $variable and last if ( !$model->exists($variable) );
    }
    return $choice;
}

sub solve {
    my ( $self, $variables, $clauses, $model ) = @_;

    $model = Hash::Ordered->new if !defined $model;
    return $self->SUPER::solve( $variables, $clauses, $model );
}

# ### update
# Copies the model, then sets `choice` = `value` in the model, and returns it, keeping the order of keys.
sub update {
    my ( $self, $copy, $choice, $value ) = @_;
    $copy = $copy->clone;

    $copy->set( $choice => $value );
    return $copy;
}

# ### resolve
# Resolve some variable to its actual value, or undefined.
sub resolve {
    my ( undef, $var, $model ) = @_;

    if ( substr( $var, 0, 1 ) eq "-" ) {
        my $value = $model->get( substr( $var, 1 ) );
        return !defined $value ? undef : $value == 0 ? 1 : 0;
    }
    else {
        return $model->get($var);
    }
}

1;

=encoding utf-8

=head1 NAME

Algorithm::SAT::Backtracking::Ordered - A simple Backtracking SAT ordered implementation

=head1 SYNOPSIS


    # You can use it with Algorithm::SAT::Expression
    use Algorithm::SAT::Expression;

    my $expr = Algorithm::SAT::Expression->new->with("Algorithm::SAT::Backtracking::Ordered");
    $expr->or( '-foo@2.1', 'bar@2.2' );
    $expr->or( '-foo@2.3', 'bar@2.2' );
    $expr->or( '-baz@2.3', 'bar@2.3' );
    $expr->or( '-baz@1.2', 'bar@2.2' );
    my $model = $exp->solve();

    # Or you can use it directly:
    use Algorithm::SAT::Backtracking::Ordered;
    my $solver = Algorithm::SAT::Backtracking::Ordered->new;
    my $variables = [ 'blue', 'green', 'yellow', 'pink', 'purple' ];
    my $clauses = [
        [ 'blue',  'green',  '-yellow' ],
        [ '-blue', '-green', 'yellow' ],
        [ 'pink', 'purple', 'green', 'blue', '-yellow' ]
    ];

    my $model = $solver->solve( $variables, $clauses );


=head1 DESCRIPTION


Algorithm::SAT::Backtracking::Ordered is a pure Perl implementation of a simple SAT Backtracking solver, in this variant of L<Algorithm::SAT::Backtracking> we keep the order of the model updates and return a L<Hash::Ordered> as result.

Look at L<Algorithm::SAT::Backtracking> for a theory description.

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

L<Algorithm::SAT::Expression>, L<Algorithm::SAT::Backtracking::DPLL>, L<Algorithm::SAT::Backtracking>, L<Algorithm::SAT::Backtracking::Ordered::DPLL>

=cut

