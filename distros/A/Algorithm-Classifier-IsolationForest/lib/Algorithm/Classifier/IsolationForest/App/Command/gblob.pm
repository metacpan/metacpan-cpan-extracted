package Algorithm::Classifier::IsolationForest::App::Command::gblob;

use strict;
use warnings;
use Algorithm::Classifier::IsolationForest;
use Algorithm::Classifier::IsolationForest::App -command;
use File::Slurp qw(write_file);

use constant PI => 3.14159265358979;

sub opt_spec {
	return (
		[ 'o=s', 'Output file path/name.', { 'default' => 'blob.csv', 'completion' => 'files' } ],
		[ 's=i', 'Seed int' ],
		[ 'p',   'Print the output instead of writing it a file.' ],
		[ 'w',   'If the file already exists, overwrite it.' ],
		[ 'n=i', 'Number of normal points to generate.', { 'default' => '500' } ],
		[
			'a=i',
			'Number of abnormal points to generate. If less than 1, none will be generated.',
			{ 'default' => '20' }
		],
		[ 'd=i', 'Number of dimensions (features) per point.', { 'default' => '2' } ],
	);
} ## end sub opt_spec

sub abstract { 'Generates a gaussian blob of points.' }

sub description {
	'Generates a gaussian blob of points.

The output format is as below...

$feat1,...,$featN,$truth

$truth is a 0/1 with 1 meaning it is a abnormal value.

Normal points are drawn from N(0,1) in each dimension. Anomalous points are
placed on a hyperspherical shell at radius 5-8 from the origin.

Use -D to control the number of dimensions (default: 2).
';
} ## end sub description

sub validate {
	my ( $self, $opt, $args ) = @_;

	if ( defined( $opt->{'s'} ) && $opt->{'s'} <= 0 ) {
		$self->usage_error( '-s, "' . $opt->{'s'} . '", is less than or equal to 0, should be a positive int' );
	}

	if ( !$opt->{'p'} && -e $opt->{'o'} && !$opt->{'w'} ) {
		$self->usage_error(
			'-o "' . $opt->{'o'} . '", already exists. Specify -w to overwrite it or use a different value.' );
	}

	if ( $opt->{'n'} < 1 ) {
		$self->usage_error( '-n, "' . $opt->{'n'} . '", must be be 1 or greater' );
	}

	if ( $opt->{'d'} < 1 ) {
		$self->usage_error( '-D, "' . $opt->{'d'} . '", must be 1 or greater' );
	}

	return 1;
} ## end sub validate

# Box-Muller; see the POD below.  Self-contained on purpose: this command
# generates test data, so it has no business reaching into the module's
# internals for _randn.
sub gaussian {
	my ( $mu, $sigma ) = @_;
	my $u1 = rand() || 1e-12;
	my $u2 = rand();
	return $mu + $sigma * sqrt( -2 * log($u1) ) * cos( 2 * PI * $u2 );
}

sub execute {
	my ( $self, $opt, $args ) = @_;

	my $dims = $opt->{'d'};
	srand( $opt->{'s'} ) if defined $opt->{'s'};

	my $data = '';

	# Normal points: each feature is drawn from N(0,1)
	for ( 1 .. $opt->{'n'} ) {
		my @feats = map { gaussian( 0, 1 ) } 1 .. $dims;
		$data = $data . join( ',', @feats ) . ",0\n";
	}

	# Anomalous points: random direction in D-space scaled to radius 5-8.
	# Direction is a normalised vector of D Gaussian draws.
	if ( $opt->{'a'} >= 1 ) {
		for ( 1 .. $opt->{'a'} ) {
			my $radius = 5 + rand() * 3;
			my @raw    = map { gaussian( 0, 1 ) } 1 .. $dims;
			my $norm   = 0;
			$norm += $_ * $_ for @raw;
			$norm = sqrt($norm) || 1;
			my @feats = map { $_ / $norm * $radius } @raw;
			$data = $data . join( ',', @feats ) . ",1\n";
		}
	} ## end if ( $opt->{'a'} >= 1 )

	if ( $opt->{'p'} ) {
		print $data;
		exit 0;
	}

	write_file( $opt->{'o'}, $data );

} ## end sub execute

=head1 NAME

Algorithm::Classifier::IsolationForest::App::Command::gblob - Generates a gaussian blob of points.

=head1 DESCRIPTION

Generates a synthetic dataset: a Gaussian cluster of normal points plus a
handful of outliers placed away from it, as CSV.  Useful for exercising
the other commands without needing real data, and for the examples in the
documentation.

Seeding with C<-s> makes a blob reproducible.

Run it as C<iforest gblob>; C<iforest help gblob> lists every option.

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

Returns the long help text C<iforest help gblob> prints under the option
list.

=head2 validate

Checks the parsed options before anything is read or written, so a
mistake costs nothing.

Checks that C<-s>, C<-n> and C<-D> are sane numbers.

Takes the parsed options hashref and the arrayref of remaining
arguments.  Calls C<usage_error>, which prints the usage and exits, on
the first problem it finds, and returns 1 when everything checks out.

=head2 execute

Writes the generated CSV to C<-o>, or to STDOUT.

Takes the parsed options hashref and the arrayref of remaining
arguments, and returns 1.

=head2 gaussian

One draw from a normal distribution, via Box-Muller.

Takes the distribution's mean and standard deviation, and returns a
single value -- typically within four standard deviations of the mean.
It consumes two C<rand()> draws, so seeding once with C<-s> makes a whole
blob reproducible.

    my $v = gaussian( 0, 1 );

=cut

return 1;
