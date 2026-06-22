package Algorithm::Classifier::IsolationForest::App::Command::predict;

use strict;
use warnings;
use Algorithm::Classifier::IsolationForest ();
use Algorithm::Classifier::IsolationForest::App -command;
use File::Slurp qw(read_file write_file);
use Scalar::Util qw(looks_like_number);

sub opt_spec {
	return (
		[ 'm=s', 'Input model JSON file path/name.', { 'default'  => 'iforest_model.json', 'completion' => 'files' } ],
		[ 'i=s', 'Input CSV for processing.', { 'completion' => 'files' } ],
		[ 'o=s', 'Output to this file instead of printing.', { 'completion' => 'files' } ],
		[ 'w', 'If the file specified via -o exists, over write it.', { 'completion' => 'files' } ],
		[ 't=f', 'Alternative threshold value to use. 0 < $val < 1' ],
		[ 'd', 'Include the input data in the output.' ],
	);
} ## end sub opt_spec

sub abstract { 'Processes the data using the score_predict_samples using the specified model' }

sub description { 'Processes the data using the score_predict_samples using the specified model.

Output format is as below per line.

$score,$predict

If -d is specified it is as below.

$x,$y,$score,$predict
' }

sub validate {
	my ( $self, $opt, $args ) = @_;

	if ( !defined($opt->{'i'}) ) {
		$self->usage_error( '-i has not been specified for a file to process' );
	}elsif ( !-f $opt->{'i'} ) {
		$self->usage_error( '-i, "' . $opt->{'i'} . '", is not a file or does not exist' );
	} elsif ( !-r $opt->{'i'} ) {
		$self->usage_error( '-i, "' . $opt->{'i'} . '", is not readable' );
	}
	
	if ( !-f $opt->{'m'} ) {
		$self->usage_error( '-m, "' . $opt->{'m'} . '", is not a file or does not exist' );
	} elsif ( !-r $opt->{'m'} ) {
		$self->usage_error( '-m, "' . $opt->{'m'} . '", is not readable' );
	}

	if (defined($opt->{'o'}) && ! $opt->{'w'} && -e $opt->{'o'} ){
		$self->usage_error( '-o, "' . $opt->{'o'} . '", already exists and -w is not specified' );		
	}

	if (defined($opt->{'t'}) && $opt->{'t'} <= 0){
		$self->usage_error( '-t, "' . $opt->{'t'} . '", needs to be greater than 0 and less than 1' );		
	}elsif (defined($opt->{'t'}) && $opt->{'t'} >= 1){
		$self->usage_error( '-t, "' . $opt->{'t'} . '", needs to be greater than 0 and less than 1' );		
	}
	
	return 1;
} ## end sub validate_args

sub execute {
	my ( $self, $opt, $args ) = @_;

	my @data;
	
	my $line_int = 1;
	foreach my $line (read_file($opt->{'i'})) {
		chomp($line);

	    my ($x, $y) = split(/\,/, $line);

		if (!defined($x)){
			die('Line '.$line_int.' of "'.$opt->{'i'}.'" lacks a value for x');
		}elsif(!looks_like_number($x)){
			die('Line '.$line_int.' of "'.$opt->{'i'}.'" value for x,"'.$x.'", does not appear to be a number');			
		}elsif(!defined($y)){
			die('Line '.$line_int.' of "'.$opt->{'i'}.'" lacks a value for y');
		}elsif(!looks_like_number($y)){
			die('Line '.$line_int.' of "'.$opt->{'i'}.'" value for y,"'.$y.'", does not appear to be a number');			
		}

		push @data, [ $x, $y ];
		
		$line_int++;
	}

	my $iforest = Algorithm::Classifier::IsolationForest->load($opt->{'m'});

	my $results = $iforest->score_predict_samples(\@data, $opt->{'t'});

	my $results_string='';
	
	my $data_int = 0;
	while(defined($data[$data_int])){
		if ($opt->{'d'}){
			$results_string = $results_string .$data[$data_int][0].','.$data[$data_int][1].','. $results->[$data_int][0].','.$results->[$data_int][1]."\n";
		}else{
			$results_string = $results_string . $results->[$data_int][0].','.$results->[$data_int][1]."\n";
		}

		$data_int++;
	}

	if (!defined($opt->{'o'})){
		print $results_string;
		exit 0;
	}

	write_file( $opt->{'o'}, {'atomic' => 1}, $results_string);
} ## end sub execute

return 1;
