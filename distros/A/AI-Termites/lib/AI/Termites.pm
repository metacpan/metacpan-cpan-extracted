package AI::Termites;

use 5.010;

our $VERSION = '0.02';

use strict;
use warnings;

use Math::Vector::Real;
use Math::Vector::Real::Random;

use List::Util;
use Carp;

sub new {
    my ($class, %opts) = @_;
    my ($dim, $box);
    $box = delete $opts{box};
    if (defined $box) {
	$box = V(@$box);
	$dim = @$box;
    }
    else {
	$dim = delete $opts{dim} // 3;
	my $size = delete $opts{world_size} // 1000;
	$box = Math::Vector::Real->cube($dim, $size);
    }

    my $box_vol = 1;
    $box_vol *= $_ for @$box;

    my $n_termites = delete $opts{n_termites} // 50;
    my $n_wood = delete $opts{n_wood} // 200;
    my $iterations = delete $opts{iterations} // 0;
    my $termite_speed = delete $opts{termite_speed} // abs($box)/10;
    my $near = delete $opts{near} // abs($box)/50;
    %opts and croak "unknown parameter(s) ". join(", ", keys %opts);

    my @wood;
    my @termites;

    my $self = { wood => \@wood,
		 termites => \@termites,
		 iteration => 0,
		 speed => $termite_speed,
		 box => $box,
                 box_vol => $box_vol,
                 wood_density => $n_wood/$box_vol,
                 near => $near,
                 inear2 => 1/($near * $near),
                 near_dim => $near ** $dim,
                 taken => 0,
		 dim => $dim };

    bless $self, $class;

    push @wood, $self->new_wood for (1..$n_wood);
    push @termites, $self->new_termite for (1..$n_termites);
    $self->iterate for (1..$iterations);
    $self;
}

sub dim { shift->{dim} }

sub box { shift->{box} }

sub new_wood {
    my $self = shift;
    my $wood = { pos => $self->{box}->random_in_box,
		 taken => 0 };
}

sub new_termite {
    my $self = shift;
    my $termite = { pos => $self->{box}->random_in_box };
}

sub iterate {
    my $self = shift;

    $self->before_termites_move;

    for my $term (@{$self->{termites}}) {
	$self->termite_move($term);
    }
    $self->before_termites_action;
    for my $term (@{$self->{termites}}) {
	$self->termite_action($term);
    }
    $self->after_termites_action;
}

sub termite_move {
    my ($self, $termite) = @_;
    $termite->{pos} = $self->{box}->wrap( $termite->{pos} +
					  Math::Vector::Real->random_normal($self->{dim},
									    $self->{speed}));
}

sub before_termites_move {}
sub before_termites_action {}
sub after_termites_action {}

sub termite_action {
    my ($self, $termite) = @_;
    if (defined $termite->{wood_ix}) {
        if ($self->termite_leave_wood_p($termite)) {
            $self->termite_leave_wood($termite);
        }
    }
    else {
        my $wood_ix = $self->termite_take_wood_p($termite);
        defined $wood_ix and $self->termite_take_wood($termite, $wood_ix);
    }
}

sub termite_take_wood {
    my ($self, $termite, $wood_ix) = @_;
    my $wood = $self->{wood}[$wood_ix];
    return if $wood->{taken};
    $wood->{taken} = 1;
    $self->{taken}++;
    # print "taken: $self->{taken}\n";
    defined $termite->{wood_ix} and die "termite is already carrying some wood";
    $termite->{wood_ix} = $wood_ix;
}

sub termite_leave_wood {
    my ($self, $termite) = @_;
    my $wood_ix = delete $termite->{wood_ix} //
	croak "termite can not leave wood because it is carrying nothing";
    $self->{taken}--;
    my $wood = $self->{wood}[$wood_ix];
    $wood->{taken} = 0;
    $wood->{pos}->set($termite->{pos});
}


1;
__END__

=head1 NAME

AI::Termites - Artificial termites simulation

=head1 SYNOPSIS

  use AI::Termites;

  my $termites = AI::Termites::VicinusOcurro->new(dim        => 2,
                                                  n_wood     => 1000,
                                                  n_termites => 100);

  $termites->iterate for 0..10000;

=head1 DESCRIPTION

This module simulates a termites world based on the ideas described on
the book "Adventures in Modeling" by Vanessa Stevens Colella, Eric
Klopfer and Mitchel Resnick
(L<http://education.mit.edu/starlogo/adventures/>).

In this version, termites can move in a n-dimensional boxed space, and
are not limited to integer coordinates.

Also, the way they decide when to pick or leave wood are customizable,
allowing to investigate how changing the rules affects the emergent
behaviors.

The module implements several termite subspecies (subclasses):

=over 4

=item LoginquitasPostulo

This termites subspecie measures the distance to the nearest piece of
wood.

=item NemusNidor

This termite smells the wood.

=item PeractioBaro

This termite is pretty simple and all that can see is if there is or
not some piece of wood in the vecinity.

=item VicinusOcurro

This termite counts the pieces of wood that there are on its vecinity.

=back

If you want to use this module, you are expected to look at its source
code!!!


=head1 SEE ALSO

The sample program includes in the distribution as
C<samples/termites.pl> can run the simulation and generate nice PNGs.

An online Artificial Termites simulation can be found here:
L<http://www.permutationcity.co.uk/alife/termites.html>.

The origin of this module lies on the following PerlMonks post:
L<http://perlmonks.org/?node_id=908684>.

=head1 AUTHOR



=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Salvador FandiE<ntilde>o,
E<lt>sfandino@yahoo.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
