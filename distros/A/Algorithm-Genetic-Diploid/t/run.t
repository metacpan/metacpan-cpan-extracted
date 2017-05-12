#!/usr/bin/perl
use strict;
use warnings;
use Test::More 'no_plan';
use Algorithm::Genetic::Diploid;

##########################################################################################
package MockExperiment;
use base 'Algorithm::Genetic::Diploid::Experiment';
Test::More::isa_ok( __PACKAGE__, 'Algorithm::Genetic::Diploid::Experiment' );

# whatever this number is, the algorithm will try to optimize towards it
sub optimum { 0 }

##########################################################################################
package MockGene;
use base 'Algorithm::Genetic::Diploid::Gene';
Test::More::isa_ok( __PACKAGE__, 'Algorithm::Genetic::Diploid::Gene' );

sub new { shift->SUPER::new( 'weight' => ( 1 + int rand 100 ) ) }

sub make_function {
	my $self = shift;
	
	# this function must return a value that the algorithm will try
	# to evolve towards MockExperiment::optimum. In this case the
	# difference between the "environment", which is a number that
	# is passed in, and the weight, which evolves.
	sub { my $env = shift; return abs( $env - $self->weight ) }
}

##########################################################################################
package MockFactory;
use base 'Algorithm::Genetic::Diploid::Factory';
Test::More::isa_ok( __PACKAGE__, 'Algorithm::Genetic::Diploid::Factory' );

# the factory needs to be configured thusly so that it instantiates the right
# subclass instances - in this case the mock objects
sub new { shift->SUPER::new( 'experiment' => 'MockExperiment', 'gene' => 'MockGene' ) }

##########################################################################################
package main;

# avoid divide-by-zero failures
my $value = 1 + int rand 100;

my $experiment = MockExperiment->new( 
	'factory' => MockFactory->new, 
	'env'     => $value, 
);
$experiment->initialize;
my ( $fittest, $fitness ) = $experiment->run;

map { ok( abs( $_->weight - $value ) < 1, "have approached $value" ) } 
map { $_->genes } 
map { $_->chromosomes } $fittest;
