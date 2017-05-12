package AI::Termites::NemusNidor;

use 5.010;
use strict;
use warnings;

use Math::Vector::Real;
use Math::Vector::Real::kdTree;
use Math::Vector::Real::MultiNormalMixture;

use parent 'AI::Termites';

sub before_termites_action {
    my $self = shift;
    my @ixs = grep !$self->{wood}[$_]{taken}, 0..$#{$self->{wood}};
    $self->{kdtree_ixs} = \@ixs;
    $self->{kdtree} = Math::Vector::Real::kdTree->new(map $_->{pos}, @{$self->{wood}}[@ixs]);
    my $sigma = $self->{near}**(-2) * log(2);
    # print "sigma: $sigma\n";
    my $mnm = Math::Vector::Real::MultiNormalMixture->new(mu => [map $_->{pos}, @{$self->{wood}}[@ixs]],
                                                          sigma => $sigma);
    $self->{mnm} = $mnm;
    $self->{mnm_max} = $mnm->max_density_estimation;
}

sub termite_take_wood_p {
    my ($self, $termite) = @_;
    my $pos = $termite->{pos};
    my $near = $self->{near};
    my $wood_ix = $self->{kdtree}->find_nearest_neighbor($pos, $near);
    if (defined $wood_ix) {
        my @near = $self->{kdtree}->find_in_ball($pos, $near * 3, $wood_ix);
        my $density = $self->{mnm}->density_portion($pos, @near);
        my $max = $self->{mnm_max};
        $self->{mnm_max} = $max = $density if $density > $max;
        # printf "take  -> max: %6g, density: %6g. ratio: %02.7f\n", $max, $density, $density/$max * 100;
        return $self->{kdtree_ixs}[$wood_ix] if $density < rand($max);
    }
    undef
}

sub termite_leave_wood_p {
    my ($self, $termite) = @_;
    my $pos = $termite->{pos};
    my $near = $self->{near};
    my @near = $self->{kdtree}->find_in_ball($pos, $near * 3);
    my $density = $self->{mnm}->density_portion($pos, @near);
    my $max = $self->{mnm_max};
    $self->{mnm_max} = $max = $density if $density > $max;
    # printf "leave -> max: %6g, density: %6g. ratio: %02.7f\n", $max, $density, $density/$max * 100;
    return 1 if $density > rand($max);
    undef;
}

1;
