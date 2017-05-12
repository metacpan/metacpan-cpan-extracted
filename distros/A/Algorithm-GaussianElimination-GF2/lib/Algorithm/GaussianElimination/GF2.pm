package Algorithm::GaussianElimination::GF2;

our $VERSION = '0.02';

use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = { eqs => [] };
    bless $self, $class;
}

sub _add_equation {
    my ($self, $eq) = @_;
    push @{$self->{eqs}}, $eq;
}

sub new_equation {
    my $self = shift;
    my $eq = Algorithm::GaussianElimination::GF2::Equation->_new(@_);
    $self->_add_equation($eq);
    $eq;
}

*add_equation = \&new_equation;

sub _first_1 {
    pos($_[0]) = 0;
    $_[0] =~ /[^\0]/g or return length($_[0]) * 8;
    my $end = pos($_[0]) * 8 - 1;
    for my $i (($end - 7) .. $end) {
        return $i if vec($_[0], $i, 1);
    }
}

sub dump {
    my $self = shift;
    my $eqs = $self->{eqs};
    my $len = 0;
    for (@$eqs) {
        $len = $_->[2] if $_->[2] > $len;
    }
    printf "GF(2) system of %d equations and %d variables\n", scalar(@$eqs), $len;
    for (@$eqs) {
        $_->[2] = $len;
        $_->dump;
    }
    print "\n";
}

sub solve {
    my $self = shift;
    my $eqs = $self->{eqs};
    my $len = 0;
    for my $eq (@$eqs) {
        $len = $eq->[2] if $eq->[2] > $len;
    }
    my @v;
    for my $eq (@$eqs) {
        push @v, $eq->[0];
        vec($v[-1], $len, 1) = $eq->[1];
    }

    for my $i (0..$#v) {
        my $v = $v[$i];
        my $ix = _first_1($v);
        if ($ix < $len) {
            for my $j (($i + 1)..$#v) {
                $v[$j] ^= $v if vec($v[$j], $ix, 1);
            }
        }
        elsif (vec($v, $len, 1)) {
            # inconsistent!
            return
        }
    }

    my @sol;
    $sol[$len] = 1;
    for my $v (reverse @v) {
        my $ix = _first_1($v);
        if ($ix < $len) {
            my $sol = 0;
            for my $i (($ix + 1) .. $len) {
                $sol ^= vec($v, $i, 1) if $sol[$i];
            }
            $sol[$ix] = $sol;
        }
    }

    my @free;
    for my $i (0 .. $len - 1) {
        unless (defined $sol[$i]) {
            push @free, $i;
            $sol[$i] = 0;
        }
    }
    pop @sol;

    return \@sol unless wantarray;

    my @base0;
    for my $free (@free) {
        my @sol0;
        $sol0[$_] = 0 for @free;
        $sol0[$free] = 1;
        for my $v (reverse @v) {
            my $ix = _first_1($v);
            if ($ix < $len) {
                my $sol = 0;
                for my $i (($ix + 1) .. ($len - 1)) {
                    $sol ^= vec($v, $i, 1) if $sol0[$i];
                }
                $sol0[$ix] = $sol;
            }
        }
        push @base0, \@sol0;
    }
    return \@sol, @base0;
}

package Algorithm::GaussianElimination::GF2::Equation;

sub _new {
    my $class = shift;
    my $self = ['', 0, 0];
    bless $self, $class;
    if (@_) {
        $self->[1] = (pop @_ ? 1 : 0);
        for my $ix (0..$#_) {
            vec($self->[0], $ix, 1) = $_[$ix]
        }
        $self->[2] = @_;
    }
    $self
}

sub a {
    my ($self, $ix, $v) = @_;
    if (defined $v) {
        $self->[2] = $ix + 1 if $self->[2] <= $ix;
        return vec($self->[0], $ix, 1) = $v;
    }
    return vec($self->[0], $ix, 1);
}

sub as {
    my $self = shift;
    map { vec($self->[0], $_, 1) } 0..($self->[2] - 1);
}

sub b {
    my ($self, $v) = @_;
    if (defined $v) {
        return $self->[1] = ($v ? 1 : 0);
    }
    return $self->[1];
}

sub len { shift->[2] }

sub dump {
    my $self = shift;
    my $last = $self->[2] - 1;
    my @a = map vec($self->[0], $_, 1), 0.. $last;
    print "@a | $self->[1]\n";
}

sub test_solution {
    my $self = shift;
    my $v = $self->[0];
    my $len = $self->[2];
    my $b = 0;
    for my $ix (0..$#_) {
        $b ^= vec($v, $ix, 1) if $_[$ix];
    }
    return ($b == $self->[1]);
}

sub clone {
    my $self = shift;
    my @self = @$self;
    bless \@self, ref $self;
}

1;
__END__

=head1 NAME

Algorithm::GaussianElimination::GF2 - Solve linear systems of equations on GF(2)

=head1 SYNOPSIS

  use Algorithm::GaussianElimination::GF2;

  my $age = Algorithm::GaussianElimination::GF2->new;
  $age->new_equation(1, 0, 0, 1 => 1);
  $age->new_equation(0, 0, 1, 1 => 0);
  my ($sol, @base0) = $age->solve;

  # or you can also create the equations setting elements at given
  # positions:

  my $age = Algorithm::GaussianElimination::GF2->new;
  my $eq1 = $age->new_equation;
  $eq1->a(0, 1);
  $eq1->a(3, 1);
  $eq1->b(1);
  my $eq2 = $age->new_equation;
  $eq2->a(2, 1);
  $eq2->a(3, 1);
  $eq2->b(0);
  my ($sol, @base0) = $age->solve;


=head1 DESCRIPTION

This module implements a variation of the Gaussian Elimination
algorithm that allows to solve systems of linear equations over GF(2).

=head2 Algorithm::GaussianElimination::GF2 methods

Those are the interesting methods:

=over 4

=item $age = Algorithm::GaussianElimination::GF2->new;

=item $eq = $age->new_equation(@a, $b)

=item $eq = $age->new_equation()

Creates and adds a new equation to the algorithm.

The returned value is a reference to the equation object that can be
used to change the equation coeficients before calling the C<solve>
method.

=item ($sol, @base0) = $age->solve

=item $sol = $age->solve

This method solves the system of equations.

When the system is inconsistent it returns an empty list.

When the system is consistent and uniquely determined it returns the
solution as an array reference.

When the system is consistent and underdetermined it returns one
solution as an array reference and a base of the vector space formed
by the solutions of the homogeneous system. In scalar context, only
the solution vector is returned.

=back

=head2 Algorithm::GaussianElimination::GF2::Equation methods

Those are the methods available to manipulate the equation objects:

=over 4

=item $a = $eq->a($ix)

=item $eq->a($ix, $a)

Retrieves or sets the value of the equation coeficient at the given
index.

=item $b = $eq->b

=item $eq->b($b)

Retrieves or sets the value of the constant term of the equation.

=item $eq->len

Returns the internal length of the coeficients vector.

Note that this value is just a hint as the internal representation
grows transparently when new coeficients are set or inside the
C<solve> method.

=back

=head1 SEE ALSO

The Wikipedia page about systems of linear equations:
L<http://en.wikipedia.org/wiki/System_of_linear_equations>.

The Wikipedia page about the Galois Field of two elements GF(2):
L<http://en.wikipedia.org/wiki/GF%282%29>.

The Wikipedia page about the Gaussian Elimination algorithm:
L<http://en.wikipedia.org/wiki/Gaussian_elimination>.

The inception of this module lays on this PerlMonks post:
L<http://perlmonks.org/?node_id=940327>.

L<Math::FastGF2> implements a much richer and faster set of operations
for GF(2).

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, 2012 by Salvador FandiE<ntilde>o (sfandino@yahoo.com)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
