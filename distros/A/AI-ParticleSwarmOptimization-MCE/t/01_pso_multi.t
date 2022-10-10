#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use lib '../lib';    # For development testing
use AI::ParticleSwarmOptimization::MCE;

=head1 NAME

AI::ParticleSwarmOptimization::MCE test suite

=head1 DESCRIPTION

Test AI::ParticleSwarmOptimization::MCE

=cut

plan (tests => 1);

# Calculation tests.
my $pso = AI::ParticleSwarmOptimization::MCE->new (
    -fitFunc        => \&calcFit,
    -dimensions     => 10,
    -iterations     => 10,
    -numParticles   => 1000,

    # only for many-core version # the best if == $#cores of your system
    # selecting best value if undefined
    -workers        => 4,
);

$pso->init();

my $fitValue         = $pso->optimize ();
my ( $best )         = $pso->getBestParticles (1);
my ( $fit, @values ) = $pso->getParticleBestPos ($best);
my $iters            = $pso->getIterationCount();


ok ( $fit > 100, 'Computations');


sub calcFit {
    my @values = @_;
    my $offset = int (-@values / 2);
    my $sum;

    $sum += ($_ - $offset++)**2 for @values;
    return $sum;
}

