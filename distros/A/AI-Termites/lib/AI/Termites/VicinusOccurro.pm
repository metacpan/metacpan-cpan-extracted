package AI::Termites::VicinusOccurro;

use strict;
use warnings;

use Math::Vector::Real;
use Math::Vector::Real::kdTree;
use Math::nSphere qw(nsphere_volumen);

use parent 'AI::Termites';

my $nlog2 = -log 2;

sub before_termites_action {
    my $self = shift;
    my @ixs = grep !$self->{wood}[$_]{taken}, 0..$#{$self->{wood}};
    $self->{kdtree_ixs} = \@ixs;
    $self->{kdtree} = Math::Vector::Real::kdTree->new(map $_->{pos}, @{$self->{wood}}[@ixs]);
    # print "dim: $self->{dim}, near: $self->{near}, density: $self->{wood_density}\n";
    $self->{alpha} = $nlog2/(nsphere_volumen($self->{dim} - 1, $self->{near}) * $self->{wood_density});



}

sub termite_take_wood_p {
    my ($self, $termite) = @_;
    my $pos = $termite->{pos};
    my $near = $self->{near};
    my $wood_ix = $self->{kdtree}->find_nearest_neighbor($pos, $near);
    if (defined $wood_ix) {
        my $count = $self->{kdtree}->find_in_ball($pos, $near, $wood_ix);
        if (exp($self->{alpha} * $count) > rand) {
            return $self->{kdtree_ixs}[$wood_ix];
        }
    }
    undef
}

sub termite_leave_wood_p {
    my ($self, $termite) = @_;
    my $pos = $termite->{pos};
    my $near = $self->{near};
    my $count = $self->{kdtree}->find_in_ball($pos, $near);
    if (exp($self->{alpha} * $count) < rand) {
        return 1;
    }
    undef;
}

1;
