#!/usr/bin/perl
use Test::More 'no_plan';
use strict;
use FindBin qw($Bin);
use File::Temp 'tempdir';

# attempt to load the classes of interest
BEGIN {
	use_ok('AI::FANN::Evolving::Factory');
	use_ok('AI::FANN::Evolving::TrainData');
	use_ok('AI::FANN::Evolving');
	use_ok('Algorithm::Genetic::Diploid::Logger');
}

# create and configure logger
my $log = new_ok('Algorithm::Genetic::Diploid::Logger');
$log->level( 'level' => 4 );
$log->formatter(sub{
	my %args = @_;
	if ( $args{'msg'} =~ /fittest at generation (\d+): (.+)/ ) {
		my ( $gen, $fitness ) = ( $1, $2 );
		ok( $fitness, "generation $gen/2, fitness: $fitness" );
	}
	return '';
});

# set quieter and quicker to give up
AI::FANN::Evolving->defaults( 'epoch_printfreq' => 0, 'epochs' => 200 );

# instantiate factory
my $fac = new_ok('AI::FANN::Evolving::Factory');

# prepare data
my $data = AI::FANN::Evolving::TrainData->new( 
	'file'      => "$Bin/../examples/Cochlopetalum.tsv",
	'ignore'    => [ 'image' ],
	'dependent' => [ 'C1', 'C2', 'C3', 'C4', 'C5' ],	
);
my ( $test, $train ) = $data->partition_data( 0.5 );

# create the experiment
my $exp = $fac->create_experiment( 
	'workdir'          => tempdir( 'CLEANUP' => 1 ),
	'traindata'        => $train->to_fann,
	'factory'          => $fac,
	'env'              => $test->to_fann,
	'mutation_rate'    => 0.1,
	'ngens'            => 2,
);
isa_ok( $exp, 'Algorithm::Genetic::Diploid::Experiment' );

# initialize the experiment
ok( $exp->initialize( 'individual_count' => 2 ), "initialized" );

# run!
my ( $fittest, $fitness ) = $exp->run();
isa_ok( $fittest, 'Algorithm::Genetic::Diploid::Individual' );