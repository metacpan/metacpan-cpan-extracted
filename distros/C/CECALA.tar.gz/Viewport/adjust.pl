#!/usr/bin/perl -w

use strict;
use lib ('.');
use Viewport;
use Tk;
use Tk::Canvas;
use Getopt::Std;

my $width = 500;
my $height = 500;

my %opts = ();
getopts( 'w:h:', \%opts );
print "w: $opts{w}; h: $opts{h}\n";
if( $opts{w} ) { $width = $opts{w} ; }
if( $opts{h} ) { $height = $opts{h} ; }
my $top 	= MainWindow->new();
my $can 	= $top->Canvas( -width => $width, -height=> $height )->form();
my $x_max 	= $width;
my $y_max 	= $height;
my $x_min 	= 5;
my $y_min 	= 5;
my $x_center 	= $can->reqwidth()/2.0;
my $y_center 	= $can->reqheight()/2.0;
my $r_max 	= $can->reqwidth()/2;
my @LoH;
my $vp = new Viewport();

# read from file 
# of format x=123 y=321 code=0
while(<>) {
	next if /^#/;
	my $rec = {};
	for my $field ( split ) {
		my ($k, $v ) = split /=/, $field;
		$rec->{$k} = $v;
	}
	push @LoH, $rec;
	$vp->updatewindowboundaries( $rec->{x}, $rec->{y} );
}

$vp->viewportboundaries ( $x_min, $x_max, $y_min, $y_max, 0.9 );
$vp->print();
$can->create ( 'line', $x_min, $y_min, $x_min, $y_max );
$can->create ( 'line', $x_min, $y_max, $x_max, $y_max );
$can->create ( 'line', $x_max, $y_max, $x_max, $y_min );
$can->create ( 'line', $x_max, $y_min, $x_min, $y_min );

my $start_x = 0;
my $start_y = 0;
foreach my $r ( @LoH )  {
	my $x = $r->{x};
	my $y = $r->{y};
	my $code = $r->{code};

	if ( $code == 1 ) {
		$can->create ( 'line', 
			$vp->x_viewport($start_x), 
			$vp->y_viewport($start_y), 
			$vp->x_viewport($x), 
			$vp->y_viewport($y)
		);
	} 
	$start_x = $x;
	$start_y = $y;
}

$vp->print();
MainLoop;
