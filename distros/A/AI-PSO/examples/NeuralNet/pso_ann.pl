#!/usr/bin/perl -w
use strict;

use AI::PSO;

my %test_params = (
    numParticles   => 4,
    numNeighbors   => 3,
    maxIterations  => 1000,
    dimensions     => 8,		# 8 since we have 8 network weights we want to optimize for a 3 input 2 hidden 1 output feed-forward neural net
    deltaMin       => -2.0,
    deltaMax       =>  4.0,
    meWeight       => 2.0,
    meMin          => 0.0,
    meMax          => 1.0,
    themWeight     => 2.0,
    themMin        => 0.0,
    themMax        => 1.0,
    exitFitness    => 0.99,
    verbose        => 1,
);

my $numInputs = 3;
my $numHidden = 2;
my $xferFunc = "Logistic";
my $annConfig = "pso.ann";
my $annInputs = "pso.dat";

my $expectedValue = 3.5;	# this is the value that we want to train the ANN to produce (just like the example in t/PTO.t)


sub test_fitness_function(@) {
    my (@arr) = (@_);
	&writeAnnConfig($annConfig, $numInputs, $numHidden, $xferFunc, @arr);
	my $netValue = &runANN($annConfig, $annInputs);
	print "network value = $netValue\n";

	# the closer the network value gets to our desired value
	# then we want to set the fitness closer to 1.
	#
	# This is a special case of the sigmoid, and looks an awful lot
	# like the hyperbolic tangent ;)
	#
	my $magnitudeFromBest = abs($expectedValue - $netValue);
	return 2 / (1 + exp($magnitudeFromBest));
}

pso_set_params(\%test_params);
pso_register_fitness_function('test_fitness_function');
pso_optimize();
#my @solution = pso_get_solution_array();




##### io #########

sub writeAnnConfig() {
	my ($configFile, $inputs, $hidden, $func, @weights) = (@_);

	open(ANN, ">$configFile");
	print ANN "$inputs $hidden\n";
	print ANN "$func\n";
	foreach my $weight (@weights) {
		print ANN "$weight ";
	}
	print ANN "\n";
	close(ANN);
}

sub runANN($$) {
	my ($configFile, $dataFile) = @_;
	my $networkValue = `ann_compute $configFile $dataFile`;
	chomp($networkValue);
	return $networkValue;
}
