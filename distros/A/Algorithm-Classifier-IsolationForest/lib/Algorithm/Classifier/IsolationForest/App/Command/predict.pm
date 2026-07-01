package Algorithm::Classifier::IsolationForest::App::Command::predict;

use strict;
use warnings;
use Algorithm::Classifier::IsolationForest ();
use Algorithm::Classifier::IsolationForest::App -command;
use Algorithm::Classifier::IsolationForest::App::Command::pack ();
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

The input may be either a CSV (one row of features per line) or a
.iforest-packed binary produced by `iforest pack` (auto-detected via
its magic bytes; cuts the CSV parse + pack_input_xs cost on repeated
runs against the same dataset).

The input CSV may have any number of feature columns; every row must have the
same column count and every value must be numeric.

Output format is as below per line.

$score,$predict

If -d is specified all input feature columns are prepended.  When the
input is a .iforest-packed file the columns come from unpacking the
stored doubles.

$feat1,...,$featN,$score,$predict
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

	my $iforest = Algorithm::Classifier::IsolationForest->load($opt->{'m'});

	my @data;     # arrayref-of-arrayrefs OR re-derived on demand from $packed
	my $score_input;    # what we hand to score_predict_samples

	if ( Algorithm::Classifier::IsolationForest::App::Command::pack::is_packed_file( $opt->{'i'} ) ) {
		my ( $n_pts, $n_feats, $bytes )
			= Algorithm::Classifier::IsolationForest::App::Command::pack::read_packed_file( $opt->{'i'} );
		die "packed input has $n_feats features but model expects "
			. $iforest->{n_features} . "\n"
			if $n_feats != $iforest->{n_features};

		# Build a PackedData wrapper directly from the on-disk bytes --
		# no CSV parse, no pack_input_xs.
		$score_input = bless {
			packed  => $bytes,
			n_pts   => $n_pts,
			n_feats => $n_feats,
		}, 'Algorithm::Classifier::IsolationForest::PackedData';

		# Only unpack to per-row arrayrefs when -d asks for it, since
		# that work undoes the whole point of using a packed file.
		if ( $opt->{'d'} ) {
			my @doubles = unpack( 'd*', $bytes );
			for my $i ( 0 .. $n_pts - 1 ) {
				push @data,
					[ @doubles[ $i * $n_feats .. ( $i + 1 ) * $n_feats - 1 ] ];
			}
		}
	}
	else {
		# CSV path
		my $expected_cols;
		my $line_int = 1;
		foreach my $line (read_file($opt->{'i'})) {
			chomp($line);
			next if $line =~ /^\s*$/;

			my @fields = split(/,/, $line, -1);

			if ( !defined($expected_cols) ) {
				$expected_cols = scalar @fields;
				die( 'Line ' . $line_int . ' of "' . $opt->{'i'} . '" has no columns' )
					if $expected_cols < 1;
			} elsif ( scalar @fields != $expected_cols ) {
				die(    'Line '
					  . $line_int . ' of "'
					  . $opt->{'i'}
					  . '" has '
					  . scalar(@fields)
					  . ' columns but expected '
					  . $expected_cols );
			}

			my $col_int = 1;
			for my $field (@fields) {
				die(    'Line '
					  . $line_int . ' of "'
					  . $opt->{'i'}
					  . '" value for column '
					  . $col_int . ',"'
					  . $field
					  . '", does not appear to be a number' )
					unless looks_like_number($field);
				$col_int++;
			}

			push @data, \@fields;

			$line_int++;
		}
		$score_input = \@data;
	}

	my $results = $iforest->score_predict_samples($score_input, $opt->{'t'});

	my $results_string='';
	
	# Drive the loop off $results rather than @data so the packed-input
	# path (which only populates @data when -d is set) still produces
	# one output row per scored point.
	for my $i ( 0 .. $#$results ) {
		if ( $opt->{'d'} ) {
			$results_string .=
				  join( ',', @{ $data[$i] } ) . ','
				. $results->[$i][0] . ','
				. $results->[$i][1] . "\n";
		}
		else {
			$results_string .=
				  $results->[$i][0] . ','
				. $results->[$i][1] . "\n";
		}
	}

	if (!defined($opt->{'o'})){
		print $results_string;
		exit 0;
	}

	write_file( $opt->{'o'}, {'atomic' => 1}, $results_string);
} ## end sub execute

return 1;
