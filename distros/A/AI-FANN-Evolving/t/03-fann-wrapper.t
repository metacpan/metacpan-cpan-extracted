#!/usr/bin/perl
use strict;
use warnings;
use Test::More 'no_plan';

BEGIN {
	use_ok('AI::FANN::Evolving');
	use_ok('AI::FANN::Evolving::TrainData');
}

##########################################################################################
# create a trivial data object:
my $data = AI::FANN::Evolving::TrainData->new(
	'header' => {
		'ID'    => 0, # simple integer id for the records
		's1'    => 1, # state 1
		's2'    => 2, # state 2
		'CLASS' => 3, # dependent 'xor' state
	},
	
	# this is the xor example from:
	# http://search.cpan.org/~salva/AI-FANN-0.10/lib/AI/FANN.pm
	'table' => [
		[ 1, -1, -1, -1 ],
		[ 2, -1, +1, +1 ],
		[ 3, +1, -1, +1 ],
		[ 4, +1, +1, -1 ],	
	],
);
ok( $data->size == 4, "instantiate data correctly" );

##########################################################################################
# train the FANN object on trivial data
my $ann = AI::FANN::Evolving->new( 'data' => $data, 'epoch_printfreq' => 0 );
$ann->train($data->to_fann);

# run the network
# this is the xor example from:
# http://search.cpan.org/~salva/AI-FANN-0.10/lib/AI/FANN.pm
my @result = ( -1, +1, +1, -1 );
my @input  = ( [ -1, -1 ], [ -1, +1 ], [ +1, -1 ], [ +1, +1 ] );
for my $i ( 0 .. $#input ) {
	my $output = $ann->run($input[$i]);
	ok( ! ( $result[$i] < 0 xor $output->[0] < 0 ), "observed and expected signs match" );
}