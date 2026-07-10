package Algorithm::Classifier::IsolationForest::App::Command::stream;

use strict;
use warnings;
use Algorithm::Classifier::IsolationForest         ();
use Algorithm::Classifier::IsolationForest::Online ();
use Algorithm::Classifier::IsolationForest::App -command;
use File::Slurp  qw(read_file write_file);
use Scalar::Util qw(looks_like_number);

sub opt_spec {
	return (
		[
			'm=s',
			'Online model JSON file path/name.  Created if it does not exist; resumed and updated if it does.',
			{ 'default' => 'oiforest_model.json', 'completion' => 'files' }
		],
		[ 'i=s', 'Input CSV to stream through the model, in row order.', { 'completion' => 'files' } ],
		[ 'o=s', 'Output the scores to this file instead of printing.',  { 'completion' => 'files' } ],
		[ 'w',   'If the file specified via -o exists, over write it.' ],
		[ 'd',   'Include the input data in the output.' ],
		[
			'learn-only',
			'Only learn the input (warm-up); no scores are emitted.  May not be combined with --score-only.'
		],
		[
			'score-only',
			'Only score the input against the model as-is; nothing is learned.  May not be combined with --learn-only.'
		],
		[ 'threshold=f', 'Alternative decision threshold to use for the label column. 0 < $val < 1' ],
		[
			'save!',
			'Save the updated model state back to -m after streaming (default on; --no-save to discard).',
			{ 'default' => 1 }
		],

		# creation knobs, used only when -m does not exist yet
		[ 'n=i',         'Number of isolation trees in the ensemble (new models only).' ],
		[ 'window=i',    'Sliding window size; 0 disables forgetting (new models only).' ],
		[ 'eta=i',       'max_leaf_samples: points a leaf accumulates before splitting (new models only).' ],
		[ 'growth=s',    "Leaf split-requirement growth, 'adaptive' or 'fixed' (new models only)." ],
		[ 'subsample=f', 'Per-tree stream subsampling probability, in (0, 1] (new models only).' ],
		[ 's=i',         'Seed int (new models only).' ],
		[
			'c=f',
			'Contamination. Expected fraction of anomalies, in (0, 0.5]; learns the decision threshold from the window (new models only).'
		],
		[
			't=s@',
			'Feature name tag. Pass once per feature (e.g. -t cpu -t mem -t disk); the count must match the number of CSV columns or the command will die (new models only).'
		],
		[
			'mungers=s',
			'JSON file of Algorithm::ToNumberMunger specs, keyed by feature tag (new models only; requires -t). '
				. 'Munged CSV columns may hold raw values; rows are munged before streaming and the spec is '
				. 'saved with the model, so resumed runs munge identically. Scalar mungers only for CSV input.',
			{ 'completion' => 'files' }
		],
		[
			'prototype=s',
			'JSON prototype file to create the model from (new models only): the variable schema and '
				. 'schema_version/schema_description come from it, and its params supply knob defaults that the '
				. 'creation switches override. May not be combined with -t or --mungers. See PROTOTYPES in the '
				. 'module POD.',
			{ 'completion' => 'files' }
		],
	);
} ## end sub opt_spec

sub abstract { 'Stream CSV rows through an Online Isolation Forest model, scoring and learning as it goes' }

sub description {
	'Streams the input rows, in order, through an Online Isolation Forest
model (Algorithm::Classifier::IsolationForest::Online).

The default operation is prequential: each row is scored against the
model as it stood before that row was learned, then learned, and the
model state (including its sliding window) is saved back to -m so the
next invocation resumes the stream where this one left off.  --learn-only
skips the scoring (warm-up) and --score-only skips the learning.

If -m does not exist yet a new model is created using the creation knobs
(-n, --window, --eta, --growth, --subsample, -s, -c, -t, --mungers,
--prototype); when it does exist those knobs are ignored.  With
--prototype the schema and schema_version/schema_description come from
the prototype file, its params supply knob defaults, and the other
creation switches override those params.

The input format matches `iforest fit`: CSV, all columns numeric
features, one sample per row.

Output format is one line per input row.

$score,$label

If -d is specified all input feature columns are prepended.

$feat1,...,$featN,$score,$label

Switches to new args for new models are like below...

-n        -> n_trees
--window  -> window_size
--eta     -> max_leaf_samples
--growth  -> growth
--subsample -> subsample
-s        -> seed
-c        -> contamination
-t        -> feature_names
';
} ## end sub description

sub validate {
	my ( $self, $opt, $args ) = @_;

	if ( !defined( $opt->{'i'} ) ) {
		$self->usage_error('-i has not been specified for a file to process');
	} elsif ( !-f $opt->{'i'} ) {
		$self->usage_error( '-i, "' . $opt->{'i'} . '", is not a file or does not exist' );
	} elsif ( !-r $opt->{'i'} ) {
		$self->usage_error( '-i, "' . $opt->{'i'} . '", is not readable' );
	}

	if ( -e $opt->{'m'} && !-r $opt->{'m'} ) {
		$self->usage_error( '-m, "' . $opt->{'m'} . '", exists but is not readable' );
	}

	if ( $opt->{'learn_only'} && $opt->{'score_only'} ) {
		$self->usage_error('--learn-only and --score-only may not be combined');
	}

	if ( defined( $opt->{'o'} ) && !$opt->{'w'} && -e $opt->{'o'} ) {
		$self->usage_error( '-o, "' . $opt->{'o'} . '", already exists and -w is not specified' );
	}

	if ( defined( $opt->{'threshold'} ) && ( $opt->{'threshold'} <= 0 || $opt->{'threshold'} >= 1 ) ) {
		$self->usage_error( '--threshold, "' . $opt->{'threshold'} . '", needs to be greater than 0 and less than 1' );
	}

	if ( defined( $opt->{'growth'} ) && $opt->{'growth'} !~ /\A(?:adaptive|fixed)\z/ ) {
		$self->usage_error( '--growth, "' . $opt->{'growth'} . '", must be either adaptive or fixed' );
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

	# --- resume an existing model first ------------------------------------
	# Loaded before the CSV is read because a munger-bearing model changes
	# how the CSV is validated (munged columns hold raw values).
	my $oif;
	if ( -f $opt->{'m'} ) {
		$oif = Algorithm::Classifier::IsolationForest->load( $opt->{'m'} );
		die( '-m, "' . $opt->{'m'} . '", is not an online model; stream only works on those' . "\n" )
			unless ref $oif eq 'Algorithm::Classifier::IsolationForest::Online';
	}

	# Prototype creation, new models only like the other creation knobs.
	# Done before the CSV is read for the same reason resuming is: a
	# munger-bearing prototype changes how the CSV is validated.  The
	# explicit creation switches override the prototype's params.
	my $from_proto = 0;
	if ( !$oif && defined( $opt->{'prototype'} ) ) {
		my $proto = eval {
			Algorithm::Classifier::IsolationForest->validate_prototype( scalar read_file( $opt->{'prototype'} ) );
		};
		die( '--prototype, "' . $opt->{'prototype'} . '", is not a valid prototype: ' . $@ ) if $@;
		die( '--prototype, "' . $opt->{'prototype'} . '", is for a batch model; use `iforest fit`' . "\n" )
			unless $proto->{class} eq 'online';

		my %overrides;
		$overrides{'n_trees'}          = $opt->{'n'}         if defined $opt->{'n'};
		$overrides{'window_size'}      = $opt->{'window'}    if defined $opt->{'window'};
		$overrides{'max_leaf_samples'} = $opt->{'eta'}       if defined $opt->{'eta'};
		$overrides{'growth'}           = $opt->{'growth'}    if defined $opt->{'growth'};
		$overrides{'subsample'}        = $opt->{'subsample'} if defined $opt->{'subsample'};
		$overrides{'seed'}             = $opt->{'s'}         if defined $opt->{'s'};
		$overrides{'contamination'}    = $opt->{'c'}         if defined $opt->{'c'};

		$oif = eval { Algorithm::Classifier::IsolationForest->new_from_prototype( $proto, %overrides ) };
		die( '--prototype, "' . $opt->{'prototype'} . '", failed to create a model: ' . $@ ) if $@;
		$from_proto = 1;
	} ## end if ( !$oif && defined( $opt->{'prototype'}...))

	# Munger spec for a NEW model (an existing model carries its own; the
	# creation knob is ignored then, like the rest of them).
	my $mungers;
	if ( !$oif && defined( $opt->{'mungers'} ) ) {
		require JSON::PP;
		$mungers = eval { JSON::PP->new->decode( scalar read_file( $opt->{'mungers'} ) ) };
		die( '--mungers, "' . $opt->{'mungers'} . '", did not parse as JSON: ' . $@ ) if $@;
		die( '--mungers, "' . $opt->{'mungers'} . '", must be a JSON object of tag => spec' )
			unless ref $mungers eq 'HASH';
	}

	my $has_mungers
		= $oif
		? ( ref $oif->{mungers} eq 'HASH' && %{ $oif->{mungers} } ? 1 : 0 )
		: ( $mungers                                              ? 1 : 0 );

	# --- read the CSV, exactly like `iforest fit` does -------------------
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

	# A prototype-created model already carries its tags; hold them to the
	# same CSV-width check the -t path gets.
	if ($from_proto) {
		my $n_tags     = scalar @{ $oif->feature_names };
		my $n_features = defined($expected_cols) ? $expected_cols : 0;
		die(      'Number of prototype feature_names ('
				. $n_tags
				. ') does not match number of CSV columns ('
				. $n_features
				. ')' )
			unless $n_tags == $n_features;
	} ## end if ($from_proto)

	# --- create the model when not resuming --------------------------------
	if ( !$oif ) {
		if ( defined( $opt->{'t'} ) ) {
			my $n_tags     = scalar @{ $opt->{'t'} };
			my $n_features = defined($expected_cols) ? $expected_cols : 0;
			die( 'Number of feature tags (' . $n_tags . ') does not match number of CSV columns (' . $n_features . ')' )
				unless $n_tags == $n_features;
		}
		$oif = Algorithm::Classifier::IsolationForest::Online->new(
			'n_trees'          => $opt->{'n'},
			'window_size'      => $opt->{'window'},
			'max_leaf_samples' => $opt->{'eta'},
			'growth'           => $opt->{'growth'},
			'subsample'        => $opt->{'subsample'},
			'seed'             => $opt->{'s'},
			'contamination'    => $opt->{'c'},
			'feature_names'    => $opt->{'t'},
			'mungers'          => $mungers,
		);
	} ## end if ( !$oif )

	# Munge the raw rows into numbers, then run the numeric validation
	# that was skipped at read time.  Munged into a separate structure so
	# -d still prints the raw input columns as given.
	my $stream_rows = \@data;
	if ($has_mungers) {
		my $munged = $oif->munge_rows( \@data );
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
		$stream_rows = $munged;
	} ## end if ($has_mungers)

	# --- stream ------------------------------------------------------------
	my $results_string = '';
	if ( $opt->{'learn_only'} ) {
		$oif->learn($stream_rows);
	} else {
		my $scores;
		if ( $opt->{'score_only'} ) {
			$scores = $oif->score_samples($stream_rows);
		} else {
			$scores = $oif->score_learn($stream_rows);
		}

		my $threshold
			= defined $opt->{'threshold'}      ? $opt->{'threshold'}
			: defined $oif->decision_threshold ? $oif->decision_threshold
			:                                    0.5;

		for my $i ( 0 .. $#$scores ) {
			my $label = $scores->[$i] >= $threshold ? 1 : 0;
			if ( $opt->{'d'} ) {
				$results_string .= join( ',', @{ $data[$i] } ) . ',' . $scores->[$i] . ',' . $label . "\n";
			} else {
				$results_string .= $scores->[$i] . ',' . $label . "\n";
			}
		}
	} ## end else [ if ( $opt->{'learn_only'} ) ]

	# Refresh the contamination threshold against the post-stream window so
	# the saved model's default cutoff tracks the stream.
	if ( !$opt->{'score_only'} && defined $oif->{contamination} && $oif->window_count ) {
		$oif->relearn_threshold;
	}

	if ( $opt->{'save'} && !$opt->{'score_only'} ) {
		$oif->save( $opt->{'m'} );
	}

	if ( length $results_string ) {
		if ( !defined( $opt->{'o'} ) ) {
			print $results_string;
		} else {
			write_file( $opt->{'o'}, { 'atomic' => 1 }, $results_string );
		}
	}

	return 1;
} ## end sub execute

return 1;
