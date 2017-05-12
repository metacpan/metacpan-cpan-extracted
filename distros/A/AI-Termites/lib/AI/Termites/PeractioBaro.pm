package AI::Termites::PeractioBaro;

use 5.010;
use strict;
use warnings;

use Math::Vector::Real;
use Math::Vector::Real::kdTree;

use parent 'AI::Termites';

sub before_termites_action {
    my $self = shift;
    my @ixs = grep !$self->{wood}[$_]{taken}, 0..$#{$self->{wood}};
    # say '@ixs: ', scalar @ixs;
    $self->{kdtree_ixs} = \@ixs;
    $self->{kdtree} = Math::Vector::Real::kdTree->new(map $_->{pos}, @{$self->{wood}}[@ixs]);
}

sub termite_take_wood_p {
    my ($self, $termite) = @_;
    my $pos = $termite->{pos};
    my $near = $self->{near};
    my $wood_ix = $self->{kdtree}->find_nearest_neighbor($pos, $near);
    if (defined $wood_ix) {
        # say "one near $pos, $near";
        my $second = $self->{kdtree}->find_nearest_neighbor($pos, $near, $wood_ix);
        return $self->{kdtree_ixs}[$wood_ix] unless defined $second;
        # say "two near $wood_ix - $second";
    }
    undef
}

sub termite_leave_wood_p {
    my ($self, $termite) = @_;
    my $pos = $termite->{pos};
    my $near = $self->{near};
    return defined $self->{kdtree}->find_nearest_neighbor($pos, $near);
    undef;
}

1;
