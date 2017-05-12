package Algorithm::SAT::Expression;
use 5.008001;
use strict;
use warnings;
require Algorithm::SAT::Backtracking;
use Carp qw(croak);
our $VERSION = "0.13";

# Boolean expression builder.  Note that the connector for clauses is `OR`;
# so, when calling the instance methods `xor`, `and`, and `or`, the clauses
# you're generating are `AND`ed with the existing clauses in the expression.
sub new {
    return bless {
        _literals       => {},
        _expr           => [],
        _implementation => "Algorithm::SAT::Backtracking"
        },
        shift;
}

sub with {
    my $self = shift;
    if ( eval "require $_[0];1;" ) {
        $self->{_implementation} = shift;
        $self->{_implementation}->import();
    }
    else {
        croak "The '$_[0]' could not be loaded";
    }
    return $self;
}

# ### or
# Add a clause consisting of the provided literals or'ed together.
sub or {
    my $self = shift;
    $self->_ensure(@_);
    push( @{ $self->{_expr} }, [@_] );
    return $self;
}

# ### xor
# Add clauses causing each of the provided arguments to be xored.2
sub xor {

    # This first clause is the 'or' portion. "One of them must be true."
    my $self     = shift;
    my @literals = @_;
    push( @{ $self->{_expr} }, \@_ );
    $self->_ensure(@literals);

    # Then, we generate clauses such that "only one of them is true".
    for ( my $i = 0; $i <= $#literals; $i++ ) {
        for ( my $j = $i + 1; $j <= $#literals; $j++ ) {
            push(
                @{ $self->{_expr} },
                [   $self->negate_literal( $literals[$i] ),
                    $self->negate_literal( $literals[$j] )
                ]
            );
        }
    }
    return $self;
}

# ### and
# Add each of the provided literals into their own clause in the expression.
sub and {
    my $self = shift;
    $self->_ensure(@_);
    push( @{ $self->{_expr} }, [$_] ) for @_;
    return $self;
}

# ### solve
# Solve this expression with the backtrack solver. Lazy-loads the solver.
sub solve {
    return $_[0]->{_implementation}
        ->new->solve( $_[0]->{_variables}, $_[0]->{_expr} );
}

# ### _ensure
# Private method that ensures that a particular literal is marked as being in
# the expression.
sub _ensure {
    my $self = shift;
    do {
        $self->{_literals}->{$_} = 1;
        push( @{ $self->{_variables} }, $_ );
        }
        for grep { !$self->{_literals}->{$_} }
        map { substr( $_, 0, 1 ) eq "-" ? substr( $_, 1 ) : $_ } @_;
}

sub negate_literal {
    my ( undef, $var ) = @_;

    return ( substr( $var, 0, 1 ) eq "-" )
        ? substr( $var, 1 )
        : '-' . $var;
}

1;
__END__

=encoding utf-8

=head1 NAME

Algorithm::SAT::Expression - A class that represent an expression for L<Algorithm::SAT::Backtracking>

=head1 SYNOPSIS


    # with the default implementation (Algorithm::SAT::Backtracking)

    use Algorithm::SAT::Expression;
    my $exp = Algorithm::SAT::Expression->new;
    $exp->or( 'blue',  'green',  '-yellow' );
    $exp->or( '-blue', '-green', 'yellow' );
    $exp->or( 'pink',  'purple', 'green', 'blue', '-yellow' );
    my $model = $exp->solve();
    # $model  now is { 'yellow' => 1, 'green' => 1 }

    # using a specific implementation

    use Algorithm::SAT::Expression;
    my $exp = Algorithm::SAT::Expression->new->with("Algorithm::SAT::Backtracking::DPLL");
    $exp->or( 'blue',  'green',  '-yellow' );
    $exp->or( '-blue', '-green', 'yellow' );
    $exp->or( 'pink',  'purple', 'green', 'blue', '-yellow' );
    my $model = $exp->solve();
    # $model  now is { 'yellow' => 1, 'green' => 1 }


=head1 DESCRIPTION

Algorithm::SAT::Expression is a class that helps to build an expression to solve with L<Algorithm::SAT::Backtracking>.

Have a look also at the tests file for an example of usage.

=head1 METHODS

=head2 and()

Takes the inputs and build an B<AND> expression for it

=head2 or()

Takes the inputs and build an B<OR> expression for it

=head2 xor()

Takes the inputs and build an B<XOR> expression for it

=head2 solve()

Uses L<Algorithm::SAT::Backtracking> to return a model that satisfies the expression.
The model it's a hash containing in the keys the literal and as the value if their presence represented by a 1 and the absence by a 0.

Note: if you use the Ordered implementation, the result is a L<Hash::Ordered>.

=head2 with()

Allow to change the SAT Algorithm used to solve the given expression

     my $exp_simple_backtracking = Algorithm::SAT::Expression->new->with("Algorithm::SAT::Backtracking::DPLL");

if you don't request a specific implementation, defaults to L<Algorithm::SAT::Backtracking>.


=head1 LICENSE

Copyright (C) mudler.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

mudler E<lt>mudler@dark-lab.netE<gt>

=head1 SEE ALSO

L<Algorithm::SAT::Backtracking>, L<Algorithm::SAT::Backtracking::DPLL>, L<Algorithm::SAT::Backtracking::Ordered>, L<Algorithm::SAT::Backtracking::Ordered::DPLL>

=cut

