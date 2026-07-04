package Algorithm::Classifier::IsolationForest::App::Command::fit;

use strict;
use warnings;
use Algorithm::Classifier::IsolationForest ();
use Algorithm::Classifier::IsolationForest::App -command;
use File::Slurp  qw(read_file write_file);
use Scalar::Util qw(looks_like_number);

sub opt_spec {
	return (
		[ 'i=s',      'CSV to use.',                 { completion => 'files' } ],
		[ 'o=s',      'Output JSON file path/name.', { 'default'  => 'iforest_model.json', 'completion' => 'files' } ],
		[ 'p',        'Print the results instead of saving it.' ],
		[ 'w',        'Overwrite the file if it already exists.' ],
		[ 's=i',      'Seed int' ],
		[ 'extended', 'Use EIF instead of IF.' ],
		[ 'n=i',      'Number of isolation trees in the ensemble' ],
		[ 'm=i',      'Sub-sample size used to build each tree... max samples' ],
		[ 'd=i',      'per-tree height limit... if not defined is set to ceil(log2(psi))' ],
		[
			'e=f',
			'How many features take partin each split. 0 behaves like a single-feature (axis) cut; the maximum (n_features - 1) uses every varying feature. undef => maximum. Clamped to [0, n_features - 1] at fit time. May only be used with -e.'
		],
		[
			'c=f',
			'Contamination. Expected fraction of anomalies, in (0, 0.5]. When given, fit() learns a score threshold that flags this fraction of the training set, and predict() uses it by default. undef => no learned threshold (predict() falls back to 0.5).'
		],
		[
			't=s@',
			'Feature name tag. Pass once per feature (e.g. -t cpu -t mem -t disk); the count must match the number of CSV columns or the command will die.'
		],
	);
} ## end sub opt_spec

sub abstract { 'Fits the model using the specified data and save it' }

sub description {
	'Fits the model using the specified data and save it

The input format is expected to be CSV. All columns are used as features;
each row becomes one sample. Every row must have the same number of columns
and every value must be numeric.

Switches to new args are like below...

-n -> n_trees
-s -> seed
-m -> sample_size
-e -> extension_level
-c -> contamination

';
} ## end sub description

sub validate {
	my ( $self, $opt, $args ) = @_;

	if ( !defined( $opt->{'i'} ) ) {
		$self->usage_error('-i has not been specified');
	} elsif ( !-f $opt->{'i'} ) {
		$self->usage_error( '-i, "' . $opt->{'i'} . '", is not a file' );
	} elsif ( !-r $opt->{'i'} ) {
		$self->usage_error( '-i, "' . $opt->{'i'} . '", is not readable' );
	}

	if ( defined( $opt->{'s'} ) && $opt->{'s'} <= 0 ) {
		$self->usage_error( '-s, "' . $opt->{'s'} . '", is less than or equal to 0, should be a positive int' );
	}

	if ( !defined( $opt->{'extended'} ) && defined( $opt->{'e'} ) ) {
		$self->usage_error('-e may not be used without --extended');
	}

	if ( !$opt->{'p'} ) {
		if ( -e $opt->{'o'} && !$opt->{'w'} ) {
			$self->usage_error( '-o,"' . $opt->{'o'} . '", already exists and -w was not specified' );
		}
	}

	if ( defined( $opt->{'e'} ) && $opt->{'e'} < 0 ) {
		$self->usage_error( '-e, "' . $opt->{'e'} . '", is less than 0... should be a float greater or equal to 0' );
	}

	return 1;
} ## end sub validate

sub execute {
	my ( $self, $opt, $args ) = @_;

	my $mode = 'axis';
	if ( $opt->{'extended'} ) {
		$mode = 'extended';
	}

	my @data;
	my $expected_cols;

	my $line_int = 1;
	foreach my $line ( read_file( $opt->{'i'} ) ) {
		chomp($line);
		next if $line =~ /^\s*$/;

		my @fields = split( /,/, $line, -1 );

		if ( !defined($expected_cols) ) {
			$expected_cols = scalar @fields;
			die( 'Line ' . $line_int . ' of "' . $opt->{'i'} . '" has no columns' )
				if $expected_cols < 1;
		} elsif ( scalar @fields != $expected_cols ) {
			die(      'Line '
					. $line_int . ' of "'
					. $opt->{'i'}
					. '" has '
					. scalar(@fields)
					. ' columns but expected '
					. $expected_cols );
		}

		my $col_int = 1;
		for my $field (@fields) {
			die(      'Line '
					. $line_int . ' of "'
					. $opt->{'i'}
					. '" value for column '
					. $col_int . ',"'
					. $field
					. '", does not appear to be a number' )
				unless looks_like_number($field);
			$col_int++;
		} ## end for my $field (@fields)

		push @data, \@fields;

		$line_int++;
	} ## end foreach my $line ( read_file( $opt->{'i'} ) )

	if ( defined( $opt->{'t'} ) ) {
		my $n_tags     = scalar @{ $opt->{'t'} };
		my $n_features = defined($expected_cols) ? $expected_cols : 0;
		die( 'Number of feature tags (' . $n_tags . ') does not match number of CSV columns (' . $n_features . ')' )
			unless $n_tags == $n_features;
	}

	my $iforest = Algorithm::Classifier::IsolationForest->new(
		'mode'            => $mode,
		'n_trees'         => $opt->{'n'},
		'seed'            => $opt->{'s'},
		'sample_size'     => $opt->{'m'},
		'extension_level' => $opt->{'e'},
		'contamination'   => $opt->{'c'},
		'feature_names'   => $opt->{'t'},
	);

	$iforest->fit( \@data );

	my $model = $iforest->to_json;

	if ( $opt->{'p'} ) {
		print $model. "\n";
		exit 0;
	}

	write_file( $opt->{'o'}, { 'atomic' => 1 }, $model );
} ## end sub execute

return 1;
