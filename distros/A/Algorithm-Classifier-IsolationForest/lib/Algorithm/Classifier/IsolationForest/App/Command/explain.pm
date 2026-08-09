package Algorithm::Classifier::IsolationForest::App::Command::explain;

use strict;
use warnings;
use Algorithm::Classifier::IsolationForest ();
use Algorithm::Classifier::IsolationForest::App -command;
use Algorithm::Classifier::IsolationForest::App::Command::pack ();
use File::Slurp                                                qw(read_file write_file);
use Scalar::Util                                               qw(looks_like_number);

sub opt_spec {
	return (
		[
			'm=s',
			'Input model JSON file path/name.',
			{ 'default' => 'iforest_model.json', 'completion' => 'files' }
		],
		[ 'i=s',      'Input CSV for processing.',                           { 'completion' => 'files' } ],
		[ 'o=s',      'Output to this file instead of printing.',            { 'completion' => 'files' } ],
		[ 'w',        'If the file specified via -o exists, over write it.', { 'completion' => 'files' } ],
		[ 'method=s', "Attribution method, 'ablation' or 'path'.",           { 'default'    => 'ablation' } ],
		[ 'n=i',      'Only output the top N features per row. 0 outputs every feature.', { 'default' => 0 } ],
		[
			't=f',
			'Only explain rows whose anomaly score is >= this. 0 < $val < 1. Rows are scored first and only the flagged ones pay the explanation cost.'
		],
	);
} ## end sub opt_spec

sub abstract { 'Explains which features drove each sample\'s anomaly score using the specified model' }

sub description {
	'Explains which features drove each sample\'s anomaly score, via
explain_samples using the specified model.

The input may be either a CSV (one row of features per line) or a
.iforest-packed binary produced by `iforest pack` (auto-detected via its
magic bytes).

Output is one line per (row, feature) pair, features ordered most
responsible first.  With the default ablation method:

$row,$score,$rank,$feature,$weight,$value,$delta,$baseline

and with --method path:

$row,$score,$rank,$feature,$weight,$value

$row is the 1-based input row number (so filtered output via -t still
references the input), $score the row\'s anomaly score, $rank 1 for the
most responsible feature counting up, $feature the feature name when the
model stores feature_names and the 0-based feature index otherwise,
$weight the feature\'s normalised share of the responsibility.  Under
ablation, $delta is the score drop when $value is replaced by $baseline
(the per-feature typical value: the training-data median for batch
models, the window median for online models).

Ablation scores n_features + 1 variants of every explained row, so on
large inputs pass -t to spend that only on the anomalous rows.  See
"explain_samples" in perldoc Algorithm::Classifier::IsolationForest for
the methods\' trade-offs.
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

	if ( !-f $opt->{'m'} ) {
		$self->usage_error( '-m, "' . $opt->{'m'} . '", is not a file or does not exist' );
	} elsif ( !-r $opt->{'m'} ) {
		$self->usage_error( '-m, "' . $opt->{'m'} . '", is not readable' );
	}

	if ( defined( $opt->{'o'} ) && !$opt->{'w'} && -e $opt->{'o'} ) {
		$self->usage_error( '-o, "' . $opt->{'o'} . '", already exists and -w is not specified' );
	}

	if ( $opt->{'method'} !~ /\A(?:path|ablation)\z/ ) {
		$self->usage_error( '--method, "' . $opt->{'method'} . '", must be either \'path\' or \'ablation\'' );
	}

	if ( $opt->{'n'} < 0 ) {
		$self->usage_error( '-n, "' . $opt->{'n'} . '", must be >= 0' );
	}

	if ( defined( $opt->{'t'} ) && ( $opt->{'t'} <= 0 || $opt->{'t'} >= 1 ) ) {
		$self->usage_error( '-t, "' . $opt->{'t'} . '", needs to be greater than 0 and less than 1' );
	}

	return 1;
} ## end sub validate

sub execute {
	my ( $self, $opt, $args ) = @_;

	my $iforest = Algorithm::Classifier::IsolationForest->load( $opt->{'m'} );

	# A model carrying Algorithm::ToNumberMunger specs takes raw values in
	# its munged CSV columns: skip the per-field numeric check at read
	# time and munge the rows before explaining (re-checking numerics
	# after), exactly as `iforest predict` does.
	my $has_mungers = ref $iforest->{mungers} eq 'HASH' && %{ $iforest->{mungers} } ? 1 : 0;

	my $rows;    # the numeric rows handed to score_samples/explain_samples

	if ( Algorithm::Classifier::IsolationForest::App::Command::pack::is_packed_file( $opt->{'i'} ) ) {
		my ( $n_pts, $n_feats, $bytes )
			= Algorithm::Classifier::IsolationForest::App::Command::pack::read_packed_file( $opt->{'i'} );
		die "packed input has $n_feats features but model expects " . $iforest->{n_features} . "\n"
			if $n_feats != $iforest->{n_features};

		# Unlike predict, always unpack to per-row arrayrefs: explanations
		# are per-feature (their values go in the output), online models
		# take plain rows, and ablation rebuilds substituted variants from
		# the rows anyway -- a packed fast path would buy nothing here.
		my @doubles = unpack( 'd*', $bytes );
		my @data;
		for my $i ( 0 .. $n_pts - 1 ) {
			push @data, [ @doubles[ $i * $n_feats .. ( $i + 1 ) * $n_feats - 1 ] ];
		}
		$rows = \@data;
	} else {
		# CSV path
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
			$rows = $munged;
		} else {
			$rows = \@data;
		}
	} ## end else [ if ( Algorithm::Classifier::IsolationForest::App::Command::pack::is_packed_file...)]

	# With -t, score everything first (cheap) and only explain the rows
	# that clear the cutoff -- under ablation each explained row costs
	# n_features + 1 scored variants, so this is the difference between
	# explaining a handful of anomalies and re-scoring the file N times.
	my @explain_idx;
	if ( defined $opt->{'t'} ) {
		my $scores = $iforest->score_samples($rows);
		@explain_idx = grep { $scores->[$_] >= $opt->{'t'} } 0 .. $#$scores;
	} else {
		@explain_idx = 0 .. $#$rows;
	}

	my $results_string = '';
	if (@explain_idx) {
		my $subset       = [ @{$rows}[@explain_idx] ];
		my $explanations = $iforest->explain_samples( $subset, method => $opt->{'method'} );

		for my $k ( 0 .. $#explain_idx ) {
			my $row_num  = $explain_idx[$k] + 1;
			my $e        = $explanations->[$k];
			my $features = $e->{features};
			my $limit
				= ( $opt->{'n'} && $opt->{'n'} < scalar @$features )
				? $opt->{'n'}
				: scalar @$features;
			for my $rank ( 1 .. $limit ) {
				my $f    = $features->[ $rank - 1 ];
				my @cols = (
					$row_num, $e->{score}, $rank, ( defined $f->{name} ? $f->{name} : $f->{index} ),
					$f->{weight}, ( defined $f->{value} ? $f->{value} : '' ),
				);
				push @cols, $f->{delta}, $f->{baseline} if $e->{method} eq 'ablation';
				$results_string .= join( ',', @cols ) . "\n";
			}
		} ## end for my $k ( 0 .. $#explain_idx )
	} ## end if (@explain_idx)

	if ( !defined( $opt->{'o'} ) ) {
		print $results_string;
		exit 0;
	}

	write_file( $opt->{'o'}, { 'atomic' => 1 }, $results_string );
} ## end sub execute

=head1 NAME

Algorithm::Classifier::IsolationForest::App::Command::explain - Explains which features drove each sample's anomaly score using the specified model

=head1 DESCRIPTION

Runs C<explain_samples> over the input and prints one line per (row,
feature) pair, most responsible feature first.  Input may be a CSV or a
C<.iforest-packed> binary from C<iforest pack>, detected by its magic
bytes.

Under the default ablation method the line format is

  $row,$score,$rank,$feature,$weight,$value,$delta,$baseline

and under C<--method path>

  $row,$score,$rank,$feature,$weight,$value

C<$row> is the 1-based input row number, so output filtered by C<-t>
still points back at the input.  Ablation scores C<n_features + 1>
variants of every explained row, which is why C<-t> is worth reaching for
on a large input: it spends that only on the rows that cleared the cutoff.

Run it as C<iforest explain>; C<iforest help explain> lists every option.

=head1 METHODS

L<App::Cmd> calls these while dispatching the subcommand.  Nothing else
should.

=head2 opt_spec

Returns this command's option specifications, as the list of arrayrefs
L<Getopt::Long::Descriptive> expects.

=head2 abstract

Returns the one-line summary C<iforest commands> prints beside the
command name.

=head2 description

Returns the long help text C<iforest help explain> prints under the option
list.

=head2 validate

Checks the parsed options before anything is read or written, so a
mistake costs nothing.

Checks that C<-i> and C<-m> name readable files, that C<-o> may be
written, that C<--method> is C<ablation> or C<path>, that C<-n> is not
negative, and that C<-t> lies in (0, 1).

Takes the parsed options hashref and the arrayref of remaining
arguments.  Calls C<usage_error>, which prints the usage and exits, on
the first problem it finds, and returns 1 when everything checks out.

=head2 execute

Loads the model, reads the input, optionally filters by C<-t>, and prints
the per-feature lines to STDOUT or to C<-o>.

Takes the parsed options hashref and the arrayref of remaining
arguments, and returns 1.

=cut

return 1;
