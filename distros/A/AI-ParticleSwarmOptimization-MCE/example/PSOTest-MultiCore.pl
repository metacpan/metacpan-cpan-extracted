#!/usr/bin/perl

use strict;
use warnings;
use lib '../lib/'; 
#-----------------------------------------------------------------------
#use AI::ParticleSwarmOptimization;
use AI::ParticleSwarmOptimization::MCE;
#use AI::ParticleSwarmOptimization::Pmap;
use Data::Dumper; $::Data::Dumper::Sortkeys = 1;
#=======================================================================
sub calcFit {
    my @values = @_;
    my $offset = int (-@values / 2);
    my $sum;

	select( undef, undef, undef, 0.01 );	# Simulation of heavy processing...

    $sum += ($_ - $offset++) ** 2 for @values;
    return $sum;
}
#=======================================================================
++$|;
#-----------------------------------------------------------------------
#my $pso = AI::ParticleSwarmOptimization::Pmap->new(		# Multi-core	
my $pso = AI::ParticleSwarmOptimization::MCE->new(		# Multi-core	
#my $pso = AI::ParticleSwarmOptimization->new(			# Single-core
    -fitFunc    	=> \&calcFit,
    -dimensions 	=> 10,
    -iterations 	=> 10,
    -numParticles	=> 1000,
    
    # only for many-core version # the best if == $#cores of your system
    # selecting best value if undefined
    -workers		=> 4,							
);


my $beg = time;

$pso->init();

my $fitValue         = $pso->optimize ();
my ( $best )         = $pso->getBestParticles (1);
my ( $fit, @values ) = $pso->getParticleBestPos ($best);
my $iters            = $pso->getIterationCount();

printf "Fit %.4f at (%s) after %d iterations\n", $fit, join (', ', map {sprintf '%.4f', $_} @values), $iters;
warn "\nTime: ", time - $beg, "\n\n";
#=======================================================================
exit 0;

