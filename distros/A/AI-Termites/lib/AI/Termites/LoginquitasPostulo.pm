package AI::Termites::LoginquitasPostulo;

use strict;
use warnings;

use Math::Vector::Real;
use Math::Vector::Real::kdTree;

use parent 'AI::Termites';

sub before_termites_action {
    my $self = shift;
    my @ixs = grep !$self->{wood}[$_]{taken}, 0..$#{$self->{wood}};
    $self->{kdtree_ixs} = \@ixs;
    $self->{kdtree} = Math::Vector::Real::kdTree->new(map $_->{pos}, @{$self->{wood}}[@ixs]);
}

sub termite_take_wood_p {
    my ($self, $termite) = @_;
    my $pos = $termite->{pos};
    my $near = $self->{near};
    my $wood_ix = $self->{kdtree}->find_nearest_neighbor($pos, $near);
    if (defined $wood_ix) {
        my ($next_ix, $d) = $self->{kdtree}->find_nearest_neighbor($pos, $near, $wood_ix);
        if (not defined $next_ix or rand($near) < $d) {
            return $self->{kdtree_ixs}[$wood_ix];
        }
    }
    undef
}

sub termite_leave_wood_p {
    my ($self, $termite) = @_;
    my $pos = $termite->{pos};
    my $near = $self->{near};
    my ($wood_ix, $d) = $self->{kdtree}->find_nearest_neighbor($pos, $near);
    if (defined $wood_ix and rand($near) > $d) {
        return 1;
    }
    undef;
}

1;
