# $Id: Knapsack.pm,v 1.11 2004/10/23 18:52:19 alex Exp $

package Algorithm::Knapsack;

use strict;
use vars qw($VERSION);

$VERSION = '0.02';

=head1 NAME

Algorithm::Knapsack - brute-force algorithm for the knapsack problem

=head1 SYNOPSIS

    use Algorithm::Knapsack;

    my $knapsack = Algorithm::Knapsack->new(
        capacity => $capacity,
        weights  => \@weights,
    );

    $knapsack->compute();

    foreach my $solution ($knapsack->solutions()) {
        foreach my $index (@{$solution}) {
            # do something with $weights[$index]
        }
    }

=head1 DESCRIPTION

The knapsack problem asks, given a set of items of various weights, find a
subset or subsets of items such that their total weight is no larger than
some given capacity but as large as possible.

This module solves a special case of the 0-1 knapsack problem when the
value of each item is equal to its weight. Capacity and weights are
restricted to positive integers.

=head1 METHODS

=over 7

=item B<new>

    my $knapsack = Algorithm::Knapsack->new(
        capacity => $capacity,
        weights  => \@weights,
    );

Creates a new Algorith::Knapsack object. Value of $capacity is a
positive integer and \@weights is a reference to an array of positive
integers, each of which is less than $capacity.

=cut

sub new {
    my $class = shift;
    my $self = {
        capacity    => 0,       # total capacity of this knapsack
        weights     => [],      # weights to be packed into the knapsack
        @_,
        solutions   => [],      # lol of indexes to weights
        emptiness   => 0,       # capacity minus sum of weights in a solution
    };
    bless $self, $class;
}

=item B<compute>

    $knapsack->compute();

Iterates over all possible combinations of weights to solve the knapsack
problem. Note that the time to solve the problem grows exponentially with
respect to the number of items (weights) to choose from.

=cut

sub compute {
    my $self = shift;
    $self->{emptiness} = $self->{capacity};
    $self->_knapsack($self->{capacity}, [0 .. $#{ $self->{weights} }], []);
}

sub _knapsack {
    my $self = shift;
    my $capacity = shift;
    my @indexes  = @{ shift() };
    my @knapsack = @{ shift() };

    while ($#indexes >= 0) {
        my $index = shift @indexes;
        next if $self->{weights}->[$index] > $capacity;

        if ($capacity - $self->{weights}->[$index] < $self->{emptiness}) {
            $self->{emptiness} = $capacity - $self->{weights}->[$index];
            $self->{solutions} = [];
        }
        if ($capacity - $self->{weights}->[$index] == $self->{emptiness}) {
            push(@{ $self->{solutions} }, [@knapsack, $index]);
        }

        $self->_knapsack($capacity - $self->{weights}->[$index],
                         \@indexes,
                         [@knapsack, $index]);
    }
}

=item B<solutions>

    my @solutions = $knapsack->solutions();

Returns a list of solutions. Each solution is a reference to an array of
indexes to @weights.

=cut

sub solutions {
    my $self = shift;
    return @{ $self->{solutions} };
}

1;

__END__

=back

=head1 EXAMPLES

The following program solves the knapsack problem for a list of weights
(14, 5, 2, 11, 3, 8) and capacity 30.

    use Algorithm::Knapsack;
    my @weights = (14, 5, 2, 11, 3, 8);
    my $knapsack = Algorithm::Knapsack->new(
        capacity => 30,
        weights  => \@weights,
    );
    $knapsack->compute();
    foreach my $solution ($knapsack->solutions()) {
        print join(',', map { $weights[$_] } @{$solution}), "\n";
    }

The output from the above program is:

    14,5,11
    14,5,3,8
    14,2,11,3

=head1 AUTHOR

Alexander Anderson E<lt>a.anderson@utoronto.caE<gt>

=head1 COPYRIGHT

 Copyright (c) 2004 Alexander Anderson. All rights reserved.
 This program is free software; you can redistribute it and/or
 modify it under the same terms as Perl itself.

=cut
