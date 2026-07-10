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
		[
			'voting=s',
			"Scoring-time aggregation: 'mean' (classic averaged score, the default) or 'majority' (MVIForest: each tree votes against the decision threshold and the label is the majority vote).",
		],
		[
			'mungers=s',
			'JSON file of Algorithm::ToNumberMunger specs, keyed by feature tag. Requires -t. '
				. 'Munged CSV columns may hold raw (non-numeric) values; they are munged before fitting '
				. 'and the spec is saved with the model. Scalar mungers only (no into/from lists) for CSV input.',
			{ 'completion' => 'files' }
		],
		[
			'prototype=s',
			'JSON prototype file to create the model from: the variable schema (feature names, '
				. 'descriptions, mungers, missing policy) plus schema_version/schema_description come from it, '
				. 'and its params supply knob defaults that explicit switches override. May not be combined '
				. 'with -t or --mungers (the schema is the prototype\'s). See PROTOTYPES in the module POD.',
			{ 'completion' => 'files' }
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
--voting -> voting

With --prototype the schema (feature names, descriptions, mungers,
missing policy) and schema_version/schema_description come from the
prototype file, its params supply knob defaults, and the switches above
override those params. See PROTOTYPES in the module POD for the format.

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

	if ( defined( $opt->{'voting'} ) && $opt->{'voting'} !~ /\A(?:mean|majority)\z/ ) {
		$self->usage_error( '--voting, "' . $opt->{'voting'} . '", must be either mean or majority' );
	}

	if ( defined( $opt->{'mungers'} ) ) {
		if ( !-f $opt->{'mungers'} ) {
			$self->usage_error( '--mungers, "' . $opt->{'mungers'} . '", is not a file or does not exist' );
		} elsif ( !-r $opt->{'mungers'} ) {
			$self->usage_error( '--mungers, "' . $opt->{'mungers'} . '", is not readable' );
		} elsif ( !defined( $opt->{'t'} ) ) {
			$self->usage_error('--mungers requires feature tags (-t) to compile against');
		}
	}

	if ( defined( $opt->{'prototype'} ) ) {
		if ( !-f $opt->{'prototype'} ) {
			$self->usage_error( '--prototype, "' . $opt->{'prototype'} . '", is not a file or does not exist' );
		} elsif ( !-r $opt->{'prototype'} ) {
			$self->usage_error( '--prototype, "' . $opt->{'prototype'} . '", is not readable' );
		}
		if ( defined( $opt->{'t'} ) || defined( $opt->{'mungers'} ) ) {
			$self->usage_error(
				'--prototype may not be combined with -t or --mungers; the schema comes only from the prototype');
		}
	} ## end if ( defined( $opt->{'prototype'} ) )

	return 1;
} ## end sub validate

sub execute {
	my ( $self, $opt, $args ) = @_;

	my $mode = 'axis';
	if ( $opt->{'extended'} ) {
		$mode = 'extended';
	}

	# Munger spec, decoded up front so a bad file dies before the CSV is
	# read.  With mungers active the per-field numeric check is skipped
	# during the read (munged columns legitimately hold raw strings) and
	# re-run after munging instead.
	my $mungers;
	if ( defined( $opt->{'mungers'} ) ) {
		require JSON::PP;
		$mungers = eval { JSON::PP->new->decode( scalar read_file( $opt->{'mungers'} ) ) };
		die( '--mungers, "' . $opt->{'mungers'} . '", did not parse as JSON: ' . $@ ) if $@;
		die( '--mungers, "' . $opt->{'mungers'} . '", must be a JSON object of tag => spec' )
			unless ref $mungers eq 'HASH';
	}

	# A prototype supplies the schema and knob defaults, so the model is
	# created before the CSV is read (a munger-bearing prototype changes
	# how the CSV is validated).  Explicit tuning switches override the
	# prototype's params; the schema may not be overridden at all.
	my $iforest;
	if ( defined( $opt->{'prototype'} ) ) {
		my $proto = eval {
			Algorithm::Classifier::IsolationForest->validate_prototype( scalar read_file( $opt->{'prototype'} ) );
		};
		die( '--prototype, "' . $opt->{'prototype'} . '", is not a valid prototype: ' . $@ ) if $@;
		die( '--prototype, "' . $opt->{'prototype'} . '", is for an online model; use `iforest stream`' . "\n" )
			unless $proto->{class} eq 'batch';

		my %overrides;
		$overrides{'n_trees'}         = $opt->{'n'}      if defined $opt->{'n'};
		$overrides{'seed'}            = $opt->{'s'}      if defined $opt->{'s'};
		$overrides{'sample_size'}     = $opt->{'m'}      if defined $opt->{'m'};
		$overrides{'max_depth'}       = $opt->{'d'}      if defined $opt->{'d'};
		$overrides{'mode'}            = 'extended'       if $opt->{'extended'};
		$overrides{'extension_level'} = $opt->{'e'}      if defined $opt->{'e'};
		$overrides{'contamination'}   = $opt->{'c'}      if defined $opt->{'c'};
		$overrides{'voting'}          = $opt->{'voting'} if defined $opt->{'voting'};

		$iforest = eval { Algorithm::Classifier::IsolationForest->new_from_prototype( $proto, %overrides ) };
		die( '--prototype, "' . $opt->{'prototype'} . '", failed to create a model: ' . $@ ) if $@;
	} ## end if ( defined( $opt->{'prototype'} ) )

	my $has_mungers
		= $mungers                                                                      ? 1
		: ( $iforest && ref $iforest->{mungers} eq 'HASH' && %{ $iforest->{mungers} } ) ? 1
		:                                                                                 0;

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

		if ( !$has_mungers ) {
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
		} ## end if ( !$has_mungers )

		push @data, \@fields;

		$line_int++;
	} ## end foreach my $line ( read_file( $opt->{'i'} ) )

	# The tag count must match the CSV width whether the tags came from -t
	# or from a prototype's schema.
	my $check_tags = defined( $opt->{'t'} ) ? $opt->{'t'} : ( $iforest ? $iforest->feature_names : undef );
	if ( defined($check_tags) ) {
		my $n_tags     = scalar @$check_tags;
		my $n_features = defined($expected_cols) ? $expected_cols : 0;
		die( 'Number of feature tags (' . $n_tags . ') does not match number of CSV columns (' . $n_features . ')' )
			unless $n_tags == $n_features;
	}

	if ( !$iforest ) {
		$iforest = Algorithm::Classifier::IsolationForest->new(
			'mode'            => $mode,
			'n_trees'         => $opt->{'n'},
			'seed'            => $opt->{'s'},
			'sample_size'     => $opt->{'m'},
			'max_depth'       => $opt->{'d'},
			'extension_level' => $opt->{'e'},
			'contamination'   => $opt->{'c'},
			'feature_names'   => $opt->{'t'},
			'voting'          => $opt->{'voting'},
			'mungers'         => $mungers,
		);
	} ## end if ( !$iforest )

	# Munge the raw rows into numbers, then run the numeric validation
	# that was skipped at read time -- an unmunged column holding a
	# string is still an error, just reported post-munge.
	if ($has_mungers) {
		my $munged = $iforest->munge_rows( \@data );
		for my $i ( 0 .. $#$munged ) {
			for my $col ( 0 .. $#{ $munged->[$i] } ) {
				die(      'Line '
						. ( $i + 1 ) . ' of "'
						. $opt->{'i'}
						. '" value for column '
						. ( $col + 1 ) . ',"'
						. ( defined $munged->[$i][$col] ? $munged->[$i][$col] : 'undef' )
						. '", is not a number after munging' )
					unless looks_like_number( $munged->[$i][$col] );
			} ## end for my $col ( 0 .. $#{ $munged->[$i] } )
		} ## end for my $i ( 0 .. $#$munged )
		@data = @$munged;
	} ## end if ($has_mungers)

	$iforest->fit( \@data );

	my $model = $iforest->to_json;

	if ( $opt->{'p'} ) {
		print $model. "\n";
		exit 0;
	}

	write_file( $opt->{'o'}, { 'atomic' => 1 }, $model );
} ## end sub execute

return 1;
