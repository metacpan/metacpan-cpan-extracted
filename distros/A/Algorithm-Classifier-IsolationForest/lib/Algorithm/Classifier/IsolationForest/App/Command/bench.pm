package Algorithm::Classifier::IsolationForest::App::Command::bench;

use strict;
use warnings;
use Algorithm::Classifier::IsolationForest ();
use Algorithm::Classifier::IsolationForest::App -command;
use File::Slurp  qw(read_file);
use Scalar::Util qw(looks_like_number);
use Time::HiRes  qw(time);

sub opt_spec {
	return (
		[
			'm=s',
			'Input model JSON file path/name.',
			{ 'default' => 'iforest_model.json', 'completion' => 'files' }
		],
		[ 'i=s',      'Input CSV (rows of features to score).',          { 'completion' => 'files' } ],
		[ 'secs|s=f', 'Seconds per measurement (after a 0.3s warm-up).', { 'default'    => 2 } ],
		[ 't=f',      'Threshold to use for predict / score_predict_*.', { 'default'    => 0.5 } ],
	);
} ## end sub opt_spec

sub abstract { 'Measure scoring throughput of a saved model on a CSV dataset' }

sub description {
	'Loads a model and a CSV dataset, then times each of the
public scoring methods over the configured wall-clock budget.  Reports
ops-per-second for each.

When the Inline::C backend is active the bench also runs pack_data once
up front and times the *_packed variants so users can see how much
pre-packing saves on their workload.

Use this to answer:

  * is my Inline::C / OpenMP / SIMD build actually faster than the
    pure-Perl fallback?
  * how much does pack_data help on my data shape?
  * what is the per-call throughput I can expect at production-typical
    query-set sizes?
';
} ## end sub description

sub validate {
	my ( $self, $opt, $args ) = @_;

	if ( !defined $opt->{'i'} ) {
		$self->usage_error('-i has not been specified');
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

	if ( $opt->{'secs'} <= 0 ) {
		$self->usage_error('--secs must be > 0');
	}

	if ( $opt->{'t'} <= 0 || $opt->{'t'} >= 1 ) {
		$self->usage_error('-t must satisfy 0 < t < 1');
	}

	return 1;
} ## end sub validate

# Standard bench helper: warm up briefly, then time exactly $secs of
# back-to-back calls.  The warm-up matters here: the first scoring call
# on a model pays for lazy packing and cache misses that would otherwise
# be charged to the measurement.
#
# Args:
#   $code :: the coderef to time.  Called with no arguments, its return
#            value discarded, so anything it needs must be closed over.
#   $secs :: the measurement budget in seconds, on top of a fixed 0.3s
#            warm-up.
#
# Returns: the throughput in calls per second, a float.
#
# Example:
#   my $rate = _bench( sub { $model->score_samples($data) }, 2 );
#   printf "%.1f ops/s\n", $rate;
sub _bench {
	my ( $code, $secs ) = @_;
	my $t0 = time();
	$code->() while time() - $t0 < 0.3;
	$t0 = time();
	my $n = 0;
	$code->(), $n++ while time() - $t0 < $secs;
	return $n / ( time() - $t0 );
}

# Slurp a CSV of feature rows into memory.  The bench scores the same
# rows over and over, so it wants everything in RAM up front and every
# cell validated before timing starts -- a parse error surfacing mid-run
# would corrupt the measurement.
#
# Args:
#   $path :: path to the CSV, which must be readable.  Blank lines are
#            skipped; there is no header handling, so a header line is a
#            parse error.
#
# Returns: the two-element list ($data, $n_feats) -- an arrayref of
# feature-value arrayrefs, and the column count taken from the first data
# row.  Dies naming the line on a ragged row or a non-numeric cell.
#
# Example:
#   my ( $data, $cols ) = _read_csv('scores.csv');
#   die "width mismatch\n" if $cols != $model->{n_features};
sub _read_csv {
	my ($path) = @_;
	my @data;
	my $expected;
	my $line = 0;
	for my $row ( read_file($path) ) {
		$line++;
		chomp $row;
		next if $row =~ /^\s*$/;
		my @f = split /,/, $row, -1;
		$expected //= scalar @f;
		die "line $line of '$path' has $row but expected $expected columns\n"
			if scalar @f != $expected;
		for my $v (@f) {
			die "line $line of '$path' value '$v' is not numeric\n"
				unless looks_like_number($v);
		}
		push @data, \@f;
	} ## end for my $row ( read_file($path) )
	return ( \@data, $expected );
} ## end sub _read_csv

sub execute {
	my ( $self, $opt, $args ) = @_;

	my $model = Algorithm::Classifier::IsolationForest->load( $opt->{'m'} );

	my ( $data, $cols ) = _read_csv( $opt->{'i'} );
	die "input CSV has $cols feature columns but model expects " . $model->{n_features} . "\n"
		if $cols != $model->{n_features};

	my $n_pts  = scalar @$data;
	my $secs   = $opt->{'secs'};
	my $thresh = $opt->{'t'};
	my $has_c  = $Algorithm::Classifier::IsolationForest::HAS_C ? 1 : 0;

	printf "Model:    %s  (n_trees=%d, mode=%s, n_features=%d)\n",
		$opt->{'m'},    scalar @{ $model->{trees} },
		$model->{mode}, $model->{n_features};
	printf "Input:    %s  (%d rows)\n", $opt->{'i'}, $n_pts;
	printf "Budget:   %.1fs per measurement (0.3s warm-up)\n", $secs;
	printf "Backend:  HAS_C=%d HAS_OPENMP=%d HAS_SIMD=%d\n\n",
		$has_c,
		$Algorithm::Classifier::IsolationForest::HAS_OPENMP ? 1 : 0,
		$Algorithm::Classifier::IsolationForest::HAS_SIMD   ? 1 : 0;

	# Pre-pack once (when C is available) so the *_packed rows measure
	# scoring in isolation, without the per-call pack_input_xs cost.
	my $packed = $has_c ? $model->pack_data($data) : undef;

	my @bench = (
		[ 'score_samples'         => sub { $model->score_samples($data) } ],
		[ 'predict'               => sub { $model->predict( $data, $thresh ) } ],
		[ 'score_predict_samples' => sub { $model->score_predict_samples( $data, $thresh ) } ],
		[ 'score_predict_split'   => sub { my @r = $model->score_predict_split( $data, $thresh ); } ],
		[ 'path_lengths'          => sub { $model->path_lengths($data) } ],
	);

	if ( defined $packed ) {
		push @bench,
			(
				[ 'score_samples (packed)'       => sub { $model->score_samples($packed) } ],
				[ 'predict (packed)'             => sub { $model->predict( $packed, $thresh ) } ],
				[ 'score_predict_split (packed)' => sub { my @r = $model->score_predict_split( $packed, $thresh ); } ],
			);
	}

	printf "  %-30s  %14s  %14s\n", 'method', 'ops/s',  'ms/call';
	printf "  %-30s  %14s  %14s\n", '-' x 30, '-' x 14, '-' x 14;
	for my $row (@bench) {
		my ( $label, $code ) = @$row;
		my $rate = _bench( $code, $secs );
		printf "  %-30s  %14.1f  %14.2f\n", $label, $rate, $rate > 0 ? 1000 / $rate : 0;
	}
	return 1;
} ## end sub execute

=head1 NAME

Algorithm::Classifier::IsolationForest::App::Command::bench - Measure scoring throughput of a saved model on a CSV dataset

=head1 DESCRIPTION

Loads a model and a CSV dataset, then times each of the public scoring
methods over a wall-clock budget and reports calls per second and
milliseconds per call.

When the Inline::C backend is active it also packs the dataset once up
front and times the packed variants, so the saving C<pack_data> gives on
your own data shape is visible rather than assumed.

Run it as C<iforest bench>; C<iforest help bench> lists every option.

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

Returns the long help text C<iforest help bench> prints under the option
list.

=head2 validate

Checks the parsed options before anything is read or written, so a
mistake costs nothing.

Checks that C<-i> and C<-m> name readable files, that C<--secs> is
positive, and that C<-t> satisfies 0 < t < 1.

Takes the parsed options hashref and the arrayref of remaining
arguments.  Calls C<usage_error>, which prints the usage and exits, on
the first problem it finds, and returns 1 when everything checks out.

=head2 execute

Reads the model and the CSV, refuses a dataset whose column count
disagrees with the model, and prints the timing table.

Takes the parsed options hashref and the arrayref of remaining
arguments, and returns 1.

=cut

return 1;
