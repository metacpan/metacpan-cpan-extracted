#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use lib '../lib';    # For development testing
use AI::ParticleSwarmOptimization;

=head1 NAME

AI::ParticleSwarmOptimization test suite

=head1 DESCRIPTION

Test AI::ParticleSwarmOptimization

=cut

plan (tests => 27);

ok (my $pso = AI::ParticleSwarmOptimization->new (), 'Constructor');
mustDie ('$pso->setParams (-fitFunc => 1)', 'Bad -fitFunc');
ok ($pso->setParams (-fitFunc => \&fitFunc,), 'Good -fitFunc (setParams)');
ok ($pso = AI::ParticleSwarmOptimization->new (-fitFunc => \&fitFunc,),
    'Good -fitFunc (new)');
ok ($pso->setParams (-fitFunc => [\&fitFunc, 1]), 'Good -fitFunc (array)');

mustDie ('$pso->setParams (-dimensions => 0)',  '-dimensions 0');
mustDie ('$pso->setParams (-dimensions => -1)', '-dimensions -1');
ok ($pso->setParams (-dimensions => 1), '-dimensions good');

for my $param (qw/numParticles/) {
    mustDie ("$pso->setParams (-$param => 0); $pso->init ()",  "-$param zero");
    mustDie ("$pso->setParams (-$param => -1); $pso->init ()", "-$param neg");
    ok (($pso->setParams (-$param => 1), $pso->init ()), "-$param good");
}

for my $param (
    qw/inertia iterations meWeight numNeighbors stallSpeed themWeight/)
{
    mustDie ("$pso->setParams (-$param => -1); $pso->init ()", "-$param neg");
    ok (($pso->setParams (-$param => 1), $pso->init ()), "-$param good");
}

mustDie (
    '$pso->setParams (-posMax => 0); $pso->setParams (-posMin => 0); $pso->init ()',
    '-posMax == -posMin'
);
mustDie (
    '$pso->setParams (-posMax => -1); $pso->setParams (-posMin => 0); $pso->init ()',
    '-posMax < -posMin'
);
ok (
    '$pso->setParams (-posMax => -1); $pso->setParams (-posMin => -2); $pso->init ()',
    '-posMax > -posMin'
   );

# Calculation tests.
$pso = AI::ParticleSwarmOptimization->new (
    -randSeed          => 2626813951,# Fit 0.00006 at (-1.0051, -0.0005, 1.0058) after 258 iterations
    -fitFunc           => \&calcFit,
    -dimensions        => 3,
    -iterations        => 500,
    -exitPlateau       => 1,
    -exitPlateauDP     => 3,
    -exitPlateauBurnin => 100,
    -exitPlateauWindow => 60,
);
my $fitValue = $pso->optimize ();
my $iters = $pso->getIterationCount ();

ok ($iters > 100 && $iters < 350, 'Low plateau ok');

sub fitFunc {
}


sub calcFit {
    my @values = @_;
    my $offset = int (-@values / 2);
    my $sum;

    $sum += ($_ - $offset++)**2 for @values;
    return $sum;
}


sub mustDie {
    my ($test, $name) = @_;

    eval $test;
    ok (defined $@, $name);
}
