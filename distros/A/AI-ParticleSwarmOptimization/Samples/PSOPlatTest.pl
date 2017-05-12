#!/usr/bin/perl
use strict;
use warnings;
use lib '..\lib';    # For development testing
use AI::ParticleSwarmOptimization;
use Math::Random::MT qw();

++$|;
my $pso = AI::ParticleSwarmOptimization->new (
    -fitFunc           => \&calcFit,
    -dimensions        => 3,
    -iterations        => 500,
    -exitPlateau       => 1,
    -exitPlateauDP     => 3,
    -exitPlateauBurnin => 100,
    -exitPlateauWindow => 60,
);

$pso->init ();

my $fitValue = $pso->optimize ();
my ($best) = $pso->getBestParticles (1);
my ($fit, @values) = $pso->getParticleBestPos ($best);
my $iters = $pso->getIterationCount ();
print $pso->getSeed();

printf ",# Fit %.5f at (%s) after %d iterations\n",
    $fit, join (', ', map {sprintf '%.4f', $_} @values), $iters;


sub calcFit {
    my @values = @_;
    my $offset = int (-@values / 2);
    my $sum;

    $sum += ($_ - $offset++)**2 for @values;
    return $sum;
}
