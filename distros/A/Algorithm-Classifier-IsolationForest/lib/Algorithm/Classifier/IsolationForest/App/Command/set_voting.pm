package Algorithm::Classifier::IsolationForest::App::Command::set_voting;

use strict;
use warnings;
use Algorithm::Classifier::IsolationForest ();
use Algorithm::Classifier::IsolationForest::App -command;
use File::Slurp  qw(read_file write_file);
use Scalar::Util qw(looks_like_number);

sub opt_spec {
	return (
		[
			'm=s',
			'Input model JSON file path/name.',
			{ 'default' => 'iforest_model.json', 'completion' => 'files' }
		],
		[
			'voting=s',
			"Target scoring-time aggregation: 'mean' (classic averaged score) or 'majority' (MVIForest per-tree vote)."
		],
		[
			'i=s',
			'CSV training data. Required only when the model was fit with contamination, so the decision threshold can be recalibrated for the new mode.',
			{ 'completion' => 'files' }
		],
		[ 'o=s', 'Write the updated model here instead of overwriting -m.', { 'completion' => 'files' } ],
		[ 'p',   'Print the updated model JSON instead of saving it.' ],
		[ 'w',   'Overwrite the -o file if it already exists.' ],
	);
} ## end sub opt_spec

sub abstract { 'Switch a saved model between mean and majority voting' }

sub description {
	'Switches the scoring-time aggregation of a saved model between "mean" and
"majority" and writes it back (in place over -m by default, or to -o / stdout).

The forest itself is voting-independent, so no tree is rebuilt. The one thing
that does not carry over is a contamination-learned decision threshold: it is a
quantile of whichever per-point quantity the mode thresholds against (the
averaged anomaly score under mean, the per-tree majority pivot under majority),
so switching relearns it for the target mode. That recalibration needs the
original training data, supplied as a CSV via -i. Models fit without
contamination carry no threshold and switch without -i.

Switches to new args are like below...

--voting -> voting
-i       -> training CSV (contamination models only)

';
} ## end sub description

sub validate {
	my ( $self, $opt, $args ) = @_;

	if ( !-f $opt->{'m'} ) {
		$self->usage_error( '-m, "' . $opt->{'m'} . '", is not a file or does not exist' );
	} elsif ( !-r $opt->{'m'} ) {
		$self->usage_error( '-m, "' . $opt->{'m'} . '", is not readable' );
	}

	if ( !defined( $opt->{'voting'} ) ) {
		$self->usage_error('--voting has not been specified');
	} elsif ( $opt->{'voting'} !~ /\A(?:mean|majority)\z/ ) {
		$self->usage_error( '--voting, "' . $opt->{'voting'} . '", must be either mean or majority' );
	}

	if ( defined( $opt->{'i'} ) ) {
		if ( !-f $opt->{'i'} ) {
			$self->usage_error( '-i, "' . $opt->{'i'} . '", is not a file or does not exist' );
		} elsif ( !-r $opt->{'i'} ) {
			$self->usage_error( '-i, "' . $opt->{'i'} . '", is not readable' );
		}
	}

	if ( defined( $opt->{'o'} ) && !$opt->{'w'} && -e $opt->{'o'} ) {
		$self->usage_error( '-o, "' . $opt->{'o'} . '", already exists and -w is not specified' );
	}

	return 1;
} ## end sub validate

sub execute {
	my ( $self, $opt, $args ) = @_;

	my $iforest = Algorithm::Classifier::IsolationForest->load( $opt->{'m'} );

	# A contamination-fitted model needs its training data to relearn the
	# threshold for the target mode; without it set_voting would croak, so
	# surface the requirement as a friendly usage error pointing at -i.  Only
	# an actual mode change triggers this -- a no-op switch never recalibrates.
	my $changing = $iforest->{voting} ne $opt->{'voting'};
	if ( $changing && defined( $iforest->{contamination} ) && !defined( $opt->{'i'} ) ) {
		$self->usage_error( 'model "'
				. $opt->{'m'}
				. '" was fit with contamination; -i CSV training data is required to recalibrate the threshold for --voting '
				. $opt->{'voting'} );
	}

	my @data;
	if ( defined( $opt->{'i'} ) ) {
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
	} ## end if ( defined( $opt->{'i'} ) )

	# set_voting ignores the data argument unless it actually recalibrates, so
	# passing an (undef) empty list for the no-recalibration cases is fine.
	$iforest->set_voting( $opt->{'voting'}, @data ? \@data : undef );

	my $model = $iforest->to_json;

	if ( $opt->{'p'} ) {
		print $model. "\n";
		exit 0;
	}

	# Default to writing back over the input model; -o redirects elsewhere.
	write_file( defined( $opt->{'o'} ) ? $opt->{'o'} : $opt->{'m'}, { 'atomic' => 1 }, $model );
} ## end sub execute

=head1 NAME

Algorithm::Classifier::IsolationForest::App::Command::set_voting - Switch a saved model between mean and majority voting

=head1 DESCRIPTION

Switches a saved model's scoring-time aggregation between C<mean> and
C<majority> and writes it back -- in place over C<-m> by default, or to
C<-o>.

The forest itself is aggregation-independent, so no tree is rebuilt.  The
one thing that does not carry over is a contamination-learned decision
threshold: it is a quantile of whichever per-point quantity the mode
thresholds against -- the averaged anomaly score under C<mean>, the
per-tree majority pivot under C<majority> -- so switching relearns it for
the target mode.  That recalibration needs the original training data,
supplied as a CSV via C<-i>.  A model fit without contamination carries no
threshold and switches without C<-i>.

Run it as C<iforest set_voting>; C<iforest help set_voting> lists every option.

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

Returns the long help text C<iforest help set_voting> prints under the option
list.

=head2 validate

Checks the parsed options before anything is read or written, so a
mistake costs nothing.

Checks that C<-m> names a readable model, that C<--voting> is C<mean> or
C<majority>, that C<-i> (when given) is readable, and that C<-o> does not
already exist unless C<-w> was given.

Takes the parsed options hashref and the arrayref of remaining
arguments.  Calls C<usage_error>, which prints the usage and exits, on
the first problem it finds, and returns 1 when everything checks out.

=head2 execute

Loads the model, switches its aggregation, recalibrating the threshold
from C<-i> when the model needs it, and writes the model back.

Takes the parsed options hashref and the arrayref of remaining
arguments, and returns 1.

=cut

return 1;
