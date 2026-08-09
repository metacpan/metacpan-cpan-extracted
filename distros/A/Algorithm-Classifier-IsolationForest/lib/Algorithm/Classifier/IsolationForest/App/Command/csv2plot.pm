package Algorithm::Classifier::IsolationForest::App::Command::csv2plot;

use strict;
use warnings;
use Algorithm::Classifier::IsolationForest ();
use Algorithm::Classifier::IsolationForest::App -command;
use File::Slurp qw(read_file write_file);
use File::Spec  ();
use File::Temp  qw(tempfile);

sub opt_spec {
	return (
		[ 'i=s', 'Input CSV for processing.',                { 'completion' => 'files' } ],
		[ 'o=s', 'PNG file to output to. Default: plot.png', { 'default'    => 'plot.png', 'completion' => 'files' } ],
		[ 'w',   'If the file specified via -o exists, over write it.' ],
		[
			'p=s',
			'Type of plot. Default: auto',
			{ 'default' => 'auto', completion => [ 'auto', '2heat', '3range', '3binary' ] }
		],
		[ 'print',        'Print what would be used with gnuplot instead of calling gnuplot' ],
		[ 'open',         'Call xdg-open to open the generated graph.' ],
		[ 'small-points', 'Use smaller points (ps 0.8) for dense 3range datasets.' ],
	);
} ## end sub opt_spec

sub abstract { 'Plot the CSV data used with iforest via gnuplot.' }

sub description {
	'Plot the CSV data used with iforest via gnuplot.

Plot types are as below.

auto: If there are two columns, 2heat. If there are 4 or more columns, 3range.
2heat: Use column 1 and 2 to generate a splatter plot over a heat map.
3range: Use columns 1 and 2 for x/y, and the second-to-last column for the
        score gradient. Suitable for predict -d output (any number of features).
3binary: Use columns 1 and 2 for x/y, and the last column for normal/abnormal.
         Suitable for predict -d output or gblob output.

3range and 3binary require data outputted from predict with the -d flag.
For N-dimensional data, columns 1 and 2 are always used for the x/y axes.
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

	if ( -e $opt->{'o'} && !$opt->{'w'} ) {
		$self->usage_error( '-o, "' . $opt->{'o'} . '", already exists and -w is not given' );
	} elsif ( -e $opt->{'o'} && !-f $opt->{'o'} ) {
		$self->usage_error( '-o, "' . $opt->{'o'} . '", already exists and -w given but file is not a file' );
	} elsif ( -e $opt->{'o'} && !-w $opt->{'o'} ) {
		$self->usage_error( '-o, "' . $opt->{'o'} . '", already exists and -w given but file is not writable' );
	}

	if (   ( $opt->{'p'} ne 'auto' )
		&& ( $opt->{'p'} ne '2heat' )
		&& ( $opt->{'p'} ne '3range' )
		&& ( $opt->{'p'} ne '3binary' ) )
	{
		$self->usage_error( '-p, "' . $opt->{'p'} . '", is not set to auto, 2heat, 3range, or 3binary' );
	}

	return 1;
} ## end sub validate

sub execute {
	my ( $self, $opt, $args ) = @_;

	my @raw_csv      = read_file( $opt->{'i'} );
	my @first_fields = split( /,/, $raw_csv[0] );
	my $ncols        = scalar @first_fields;

	if ( $opt->{'p'} eq 'auto' && $ncols >= 4 ) {
		$opt->{'p'} = '3range';
	} elsif ( $opt->{'p'} eq 'auto' && $ncols >= 2 ) {
		$opt->{'p'} = '2heat';
	} elsif ( $opt->{'p'} eq 'auto' ) {
		die('-p is set to auto and the specified CSV does not have enough columns');
	} elsif ( $opt->{'p'} eq '2heat' && $ncols < 2 ) {
		die('2heat specified but there is no column for y');
	} elsif ( $opt->{'p'} eq '3range' && $ncols < 3 ) {
		die('3range specified but there is no column for score');
	} elsif ( $opt->{'p'} eq '3binary' && $ncols < 3 ) {
		die('3binary specified but there is no column for truth');
	}

	# For predict -d output: score is the second-to-last column, prediction is last.
	my $score_col = $ncols - 1;
	my $pred_col  = $ncols;

	$opt->{'i'} = File::Spec->rel2abs( $opt->{'i'} );
	$opt->{'o'} = File::Spec->rel2abs( $opt->{'o'} );

	my ( $tempfh, $tempfile ) = tempfile( 'UNLINK' => 1 );

	my $ps = $opt->{'small_points'} ? '0.8' : '1.5';

	my $gnu_plot_stuff = 'set terminal pngcairo size 1200,900 font "Sans,11"
set output "' . $opt->{'o'} . '"

set datafile separator ","
set key autotitle columnhead

set grid lc "gray70" lw 0.5 dt 2

';

	if ( $opt->{'p'} eq '3range' ) {
		$gnu_plot_stuff = $gnu_plot_stuff . '
set palette defined (0 "#4575b4", 0.5 "#ffffbf", 1 "#d73027")
set cblabel "outlier score"
plot "' . $opt->{'i'} . '" using 1:2:' . $score_col . ' with points pt 7 ps ' . $ps . ' palette title ""
';
	} elsif ( $opt->{'p'} eq '3binary' ) {
		$gnu_plot_stuff
			= $gnu_plot_stuff
			. 'plot "'
			. $opt->{'i'}
			. '" using 1:($'
			. $pred_col
			. '==0 ? $2 : 1/0) with points pt 7  ps 1.2 lc rgb "#4575b4" title "normal", \
     "'
			. $opt->{'i'}
			. '" using 1:($'
			. $pred_col
			. '==1 ? $2 : 1/0) with points pt 13 ps 2.0 lc rgb "#d73027" title "abnormal"
';
	} elsif ( $opt->{'p'} eq '2heat' ) {
		$gnu_plot_stuff = $gnu_plot_stuff . '
unset key
set view map
set palette cubehelix negative

set dgrid 25,25 gauss  kdensity 3, 3

splot "' . $opt->{'i'} . '" using 1:2:(1) with pm3d, \
      "" using 1:2:(1) with points lc "black" pt 7 ps 0.6 nogrid
';
	} ## end elsif ( $opt->{'p'} eq '2heat' )

	if ( $opt->{'print'} ) {
		print $gnu_plot_stuff;
		exit 0;
	}

	write_file( $tempfile, $gnu_plot_stuff );

	system( 'gnuplot', $tempfile );
	if ( $? != 0 ) {
		die( '"gnuplot ' . $tempfile . '" exited non-zero' );
	}

	if ( $opt->{'open'} ) {
		system( 'xdg-open', $opt->{'o'} );
	}

} ## end sub execute

=head1 NAME

Algorithm::Classifier::IsolationForest::App::Command::csv2plot - Plot the CSV data used with iforest via gnuplot

=head1 DESCRIPTION

Renders a CSV through gnuplot.  The plot types are

  - auto :: 2heat for two columns, 3range for four or more
  - 2heat :: columns 1 and 2 as a scatter plot over a heat map
  - 3range :: columns 1 and 2 for x/y, the second-to-last column for the
    score gradient
  - 3binary :: columns 1 and 2 for x/y, the last column for the
    normal/abnormal split

C<3range> and C<3binary> expect the output of C<iforest predict -d>.  For
data with more than two features, columns 1 and 2 are always the axes.

Run it as C<iforest csv2plot>; C<iforest help csv2plot> lists every option.

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

Returns the long help text C<iforest help csv2plot> prints under the option
list.

=head2 validate

Checks the parsed options before anything is read or written, so a
mistake costs nothing.

Checks that C<-i> is a readable file, that C<-o> does not already exist
unless C<-w> was given, and that C<-p> names one of the plot types above.

Takes the parsed options hashref and the arrayref of remaining
arguments.  Calls C<usage_error>, which prints the usage and exits, on
the first problem it finds, and returns 1 when everything checks out.

=head2 execute

Writes the gnuplot input and runs it, leaving the image at C<-o>.

Takes the parsed options hashref and the arrayref of remaining
arguments, and returns 1.

=cut

return 1;
