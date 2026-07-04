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

return 1;
