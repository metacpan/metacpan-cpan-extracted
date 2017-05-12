#!/usr/bin/perl -w

my $nada = "";
my $Id = "";
my $RCSId = "RCS$Id: pppplot.pl,v 1.4 2003/09/25 20:23:28 arlin Exp $nada";
my $shortName = $RCSId; 
$shortName =~ s/^RCS: |,.*$//g;
my $whatItDoes = "generates posterior probability of presence plots (SPAN)";
my $contact = "Arlin Stoltzfus (arlin\@carb.nist.gov)"; 
my $version = $RCSId;

# to do: check for R sources,

use strict; 

# for debugging purposes only 
my $debug = 0;
if ( $debug ) { 
    open( DEBUG, ">tmp-$shortName" ) || die "Could not open logfile 'tmp-$shortName'\n";
    printf( DEBUG "Debugging version: $version\n" );
}
# SETTINGS

# to set offset & spread for jiggering node labels, see "SpreadOut" subroutine

my $RCommand = "R --save";  # how to invoke R
my $pageH = 11 - 1;         # height of page - margin
my $pageW = 8.5 - 1;        # width of page - margin
my $maxPlotsPerPage = 12; # max plots to squeeze on one page
my $makePostscript = 1;   
my $deleteLabels = 1;  # remove clutter by labelling only when y >= $deleteLabels
my $tmpFileExtension = ".$$"; 
my $showMajorTitle = 0; # show titles (set to 0 to make figs for publication)
my $showLabels = 0; # show x and y axis labels (set to 0 to make figs for publication)
# 1. get list of filenames from input file on stdin

my $infile = shift( @ARGV);
open( INFILE, "$infile" ) || die "Could not open input file $infile with names of data files to process!";

my $i = undef; 
my @tmp = ();
my @filenames = ();
my @titles = ();
while ($_ = <INFILE>) { 
    chomp; 
    unless (/^\s*$/) { push( @tmp, $_ ) } 
};
@filenames = sort by_embedded_numbers @tmp;
@titles = @filenames; 
for ( $i = 0; $i <= $#titles; $i++ ) { 
    $titles[$i] =~ s/_/ /g; # convert underscores to spaces
    $titles[$i] =~ s/^.*\///g; # remove prepended directories in pathname
    $titles[$i] =~  s/\.(dat|txt|tab)$//; # remove filename extension  
    if ( $debug ) { printf( DEBUG "$titles[$i] (data from $filenames[$i])\n" ); }
}

# 2. set up for plotting loop
#           determine number of rows, columns, and pages to use
#           open pipe to R 
#           set up common functions and parameters in R

my ( $numRows, $numCols );
my $numPages = 1;
my $numPlots = $#filenames + 1;
if ( $numPlots > $maxPlotsPerPage ) { 
    $numPages = $numPlots/$maxPlotsPerPage;
    if ( $numPages - int($numPages) > 0 ) { $numPages = int( $numPages ) + 1; };
    $numPlots = $maxPlotsPerPage;
}
# distribute rows & cols proportionately according to dimensions of paper
$numRows = int( sqrt( $numPlots * $pageH/$pageW ) + 0.5 );
$numCols = int( $numPlots/$numRows + 0.5 );
while ( $numCols * $numRows < $numPlots ) { $numRows++; }

if ( $debug ) { printf( DEBUG "\nSetting up for $numPages pages with $numPlots plots each in $numRows X $numCols array\n" ); }

open( R, "|$RCommand") or  die "Cannot run R (currently set to '$RCommand')";
printf( R "oldpar <- par\n" );
printf( R "pppplot <- function( data, title, threshold ) {
    attach(data)
    dummyx <- seq(0, round(max(c(x1,x2,x3)), digits=1), length = 6)
    dummyy <- seq(-0.1, round(1.05*max(c(y1,y2,y3)), digits=1), length = 6)\n" );

if ( $showLabels ) { 
    printf( R "plot( dummyx, dummyy, type=\"n\", xlab=\"Distance from root\", ylab=\"Prob(presence)\", main=title)\n" );
}
else { 
    printf( R "plot( dummyx, dummyy, type=\"n\", xlab=\"\", ylab=\"\", main=title)\n" );
}
printf( R "segments( x1, y1, x2, y2 )
    nodes <- rownames(data)
# to plot ALL node labels (ugly), use this:   text( x3, y3, nodes )
    text( x3[y1>=threshold], y3[y1>=threshold], nodes[y1>=threshold] )
}\n");

	
# 3. process pages until done
#     3.A. set device 
#     3.B. process plots until done. 
#           3.B.1. read in data for plot
#           3.B.2. jigger labels 
#           3.B.3. send data to R 
	
my $plot = 0; 
my $page = 0;
my $file = undef;
my $plotDataFile = undef;
my $figTitle = $infile;
$figTitle =~ s/_/ /g;
$figTitle =~ s/^.*\///; 

for ( $page = 0; $page < $numPages; $page++ ) { 
    if ( $debug ) { printf( DEBUG "Starting page %d\n", $page + 1 ); }
    if ( $makePostscript > 0 ) {
	printf( R "postscript( file=\"$infile-%d.ps\", width=%f, height=%f, horizontal=FALSE )\n", $page + 1, $pageW, $pageH );
    }
    # for some reason I have to set graphics parameters AFTER invoking postscript, 
    # otherwise the result is one figure per page
    if ( $showMajorTitle ) {
	printf( R "par(mfrow=c($numRows,$numCols), omi=c(0,0,0.75,0), mai=c(0.3,0.3,0.3,0.15), mgp=c(1,0.25,0))\n");
    }
    else { 
	printf( R "par(mfrow=c($numRows,$numCols), omi=c(0,0,0,0), mai=c(0.3,0.3,0.3,0.15), mgp=c(1,0.25,0))\n");
    }
    for ( $plot = 0; $plot < $numPlots && $#filenames >= 0 ; $plot++ ) { 
	if ( $debug ) { printf( DEBUG "   plot %d: ", $plot + 1 ); }
	# prepare data 
	$file = shift( @filenames );
	$plotDataFile = $file . "$tmpFileExtension";
	PrepareData( $file, $plotDataFile );
	printf( R "data <- read.table('%s')\n", $plotDataFile );
	printf( R "pppplot( data, \"%s\", %f )\n", shift( @titles ), $deleteLabels ); 
    }
    if ( $showMajorTitle ) {
	printf( R "mtext(\"$figTitle%s\", 3, outer=TRUE, cex=1.5, line=3)\n", ( $numPages > 1 ? sprintf( ", part %d", $page + 1) : "" ) );
	printf( R "mtext(\"$version\", 3, outer=TRUE, line=1)\n" );
    }
    if ( $makePostscript > 0 ) {
	printf( R "dev.off()\n" );
    }
}
printf( R "par <- oldpar\n" );
printf( R "quit()\n" );
close ( R );

printf( STDERR "Created some temporary files (*$tmpFileExtension) that you may want to delete.\n" );

if ( $debug ) { printf( DEBUG "Done\n" ); close ( DEBUG ); }
exit;

sub PrepareData { 
my $infile = $_[0];
my $outfile = $_[1]; 
if ( $debug ) { printf( DEBUG "(PrepareData: $infile --> $outfile) "); }
open( INFILE, "$infile" ) || die "could not open input file $infile with raw data\n" ; 
open( OUTFILE, ">$outfile" ) || die "could not open outfile $outfile\n" ; 

my $offset = 0.065; # set to about 2/3 height (in Y units) of label font
my $spread = 0.045; # set to about  width (in X units) of label font

my %data = ();

my @lines = ();
my @ones = ();
my @zeros = ();
my $label = undef;
my $discard = undef;
my $pathsteps = 0;
my ( $i, $x1, $y1, $x2, $y2, $x3, $y3 );

printf( OUTFILE "\tx1\ty1\tx2\ty2\tx3\ty3\n" );

# FIRST we collect the info for node labels, the x1, y1, x2, y2 branch segments; 
# and we propose the coordinates (x3, y3) to place the label

while ( $_ = <INFILE> ){ 
  chomp;
  s/^\s+|\s+$//g;
  if ( /^$/ ) {  
#      printf( "output %d steps\n", $pathsteps -1 );
    for ($i = 0; $i < $pathsteps - 1; $i++) {

      ( $label, $x1, $y1 ) =  split( /\s+/, $lines[$i] );
      # cut off "otu_", convert non-otu node identifier to a char
      if ( ! ( $label =~ s/^otu_// ) ) { 
	$label = sprintf( "%c", int($label) + 65 );
	# $label =~ tr/0123456789/ABCDEFGHIJ/; 
      }
      ( $discard, $x2, $y2 ) = split( /\s+/, $lines[$i+1] );

      if ( $y1 == 0 ) { $y3 = $y1 - $offset; }
      else { $y3 = $y1 + $offset; }
      $x3 = $x1 - $offset; 

#      printf( "$label\t$x1\t$y1\t$x2\t$y2\t%f\t%f\n", $x3, $y3 );
      $data{ "$label" } = [ $x1, $y1, $x2, $y2,  $x3, $y3 ];
    }
    @lines = ();
    $pathsteps = 0;
  }
  else { 
    push( @lines, $_ ); 
    $pathsteps++;
  }
}
close( INFILE );

# SECOND, we need to sort these before proceeding further, and meanwhile 
# we will grab the x values for points whose labels may need to be jiggered

sub by_x1_value {
    $data{"$a"}[0] <=> $data{"$b"}[0];
}
my @sortindex = sort by_x1_value keys( %data );
my $lab;

foreach $lab ( @sortindex ) {
#  printf( "$lab: %.4f %.4f\n", $data{ "$lab" }[0], $data{ "$lab" }[1] );
  if ( $data{ "$lab" }[1] == 0 ) { push( @zeros, $data{ "$lab" }[0] ); }  
  if ( $data{ "$lab" }[1] == 1 ) { push( @ones, $data{ "$lab" }[0] ); }
} 

# THIRD, we call a subroutine to generate a set of jiggered coordinates for 
#  the labels-- this breaks up clumps and makes the plot more readable

@ones = SpreadOut( $spread, @ones );
@zeros = SpreadOut( $spread, @zeros );

# FOURTH, we put the jiggered x coordinates for the labels back into the data 
# array, jigger the y coordinates for the labels, then print the output

my $odd0 = 1;
my $odd1 = 1;

foreach $lab ( @sortindex ) {
  if ( $data{ "$lab" }[1] == 0 ) {  
    $data{ "$lab" }[4] = shift( @zeros ); 
    if ( $odd0 ) { $data{ "$lab" }[5] -= $offset; }
    $odd0 = ( $odd0 ) ? 0 : 1; 
  }  
  if ( $data{ "$lab" }[1] == 1 ) {  
    $data{ "$lab" }[4] = shift( @ones ); 
    if ( $odd1 ) { $data{ "$lab" }[5] += $offset; }
    $odd1 = ( $odd1 ) ? 0 : 1; 
  }
  printf( OUTFILE "$lab %.6f %.6f ", $data{ "$lab" }[0], $data{ "$lab" }[1] );
  printf( OUTFILE "%.6f %.6f ", $data{ "$lab" }[2], $data{ "$lab" }[3] );
  printf( OUTFILE "%.6f %.6f\n", $data{ "$lab" }[4], $data{ "$lab" }[5] );
}
close( OUTFILE );
}


sub SpreadOut {

# $minD is the current minimum distance, mini is the index for the $minD interval;
# $spread is the minimum distance we will allow between labels; $nudge is $spread/2.
#
# The way this works is that we find the smallest interval, and push the labels 
# out to widen the interval: first we nudge the label on the left further to 
# the left, proceeding leftward to any additional labels that need to be nudged 
# to make room; then we to the right side and do the same.  Then we can go back 
# to the top of the loop and find the smallest interval again.  
# 
# When the smallest interval is >= $spread, then we are done.  

    my $i;
    my $D = undef;
    my $spread = shift( @_ ); 
    my @locs = @_;
    my $done = 0;
    my $round = 1;
    my $nudge = $spread/2;

  while ( ! $done ) {
    my $mini = undef;
    my $minD = 2 * $spread; 
#    print "\n", $round++, ": ";
    for ( $i = 0; $i < $#locs; $i++ ) { 
      $D = abs( $locs[$i] - $locs[$i+1] );
      if ( $D < $minD ) { 
	$minD = $D;
	$mini = $i;
      }
    }
    if ( defined $mini ) { 
#      printf( "Minimum distance is $minD (at $mini, %f - %f)\n", $locs[$mini], $locs[$mini + 1] );
    }
    if ( $minD >= $spread ) {
      $done = 1;
    }
    # jigger the locations to spread them out
    else {
#      printf " nudge ";
      $i = $mini;
      $locs[$i] -= $nudge;
      while( ( $i > 0 ) && ( abs( $locs[$i] - $locs[--$i] ) < ( $spread + $nudge ) ) ) {
#	printf " dn";
	$locs[$i] -= $nudge;
      }
      $i = $mini + 1;
      $locs[$i] += $nudge;
      while( ( $i < $#locs ) && ( abs( $locs[$i] - $locs[++$i] ) < ( $spread + $nudge ) ) ) {
#	printf " up";
	$locs[$i] += $nudge;
      }
    }
  }
  return( @locs );
}

# these two functions are for sorting a list of names by indices that are 
# embedded in the names, e.g., f('file3') = 3, f('intron_235-1.txt') = 235.1

sub by_embedded_numbers {
    my $anum = &numberify( $a );
    my $bnum = &numberify( $b );
    return( $anum <=> $bnum );
}

sub numberify { 
    $_ = shift;
    s/^[^\d]+//;  # cut off initial non-numbers 
    s/[^\d]+(\d)/.$1/; # append a second number to the first with a '.'
    s/[^\d]+.*$//;  # cut off anything else
    return( $_ ? $_ : 0 );  # return $_ or 0 if empty
} 

# POD usage

=head1 NAME

pppplot.pl - generates posterior probability of presence plots (SPAN)

=head1 SYNOPSIS

pppplot.pl <filelist>

where <filelist> is a file with the names (one name per line) of 
data files generated by B<prob-changes.pl>.  The PostScript output 
file will be named "filelist.ps" if the plots all fit on one page, or 
"filelist-<n>.ps" if they are distributed on multiple pages.  
  
=head1 DESCRIPTION

B<pppplot.pl> generates a phylogenetic probability of presence (ppp) 
plot.  In the context of SPAN this typically is used to display the 
history or one or more intron characters on a phylogenetic tree.  
If the input file lists multiple data files, pppplot.pl determines 
how many pages of output to produce, and how many figures to put 
on each page.  

pppplot.pl generates its clever graphics by opening a named pipe 
to execute commands in the B<R> data analysis language.  This does not 
work on all systems.  In particular, the current implementation of 
Perl on Mac OS X does not support named pipes.  

The PPP plot is an idea by Weigang Qiu. 

=head1 VERSION

$Id: pppplot.pl,v 1.4 2003/09/25 20:23:28 arlin Exp $

=head1 REQUIRES 

R, via named pipe (see DESCRIPTION)

=head1 SEE ALSO

R, prob-changes.pl

=head1 AUTHOR

Arlin Stoltzfus (stoltzfu@umbi.umd.edu)

=cut
