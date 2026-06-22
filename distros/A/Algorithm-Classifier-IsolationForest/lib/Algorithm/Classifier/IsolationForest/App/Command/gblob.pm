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
	);
} ## end sub opt_spec

sub abstract { 'Generates a gaussian blob of points.' }

sub description {
	'Generates a gaussian blob of points.

The output format is as below...

$X,$Y,$truth

$truth is a 0/1 with 1 meaning it is a abnormal value
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

	my $data = '';

	for ( 1 .. $opt->{'n'} ) {
		$data = $data . gaussian( 0, 1 ) . ',' . gaussian( 0, 1 ) . ",0\n";
	}
	if ( $opt->{'a'} >= 1 ) {
		for ( 1 .. $opt->{'a'} ) {
			my $angle  = rand() * 2 * PI;
			my $radius = 5 + rand() * 3;
			my $X      = $radius * cos($angle);
			my $Y      = $radius * sin($angle);
			$data = $data . $X . ',' . $Y . ",1\n";
		}
	}

	if ( $opt->{'p'} ) {
		print $data;
		exit 0;
	}

	write_file( $opt->{'o'}, $data );

} ## end sub execute

return 1;
