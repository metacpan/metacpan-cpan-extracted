#!/usr/bin/perl -w

use strict;
use Math::Trig;
use lib ('.');
use Viewport;
use Tk;
use Tk::Canvas;
use Getopt::Std;
use constant PIdiv180 => 3.1415926/180; 
my $width = 500;
my $height = 500;
my $background = 'blue';
my $fill = 'yellow';
my %opts = ();
getopts( 'w:h:b:f:', \%opts );
if( $opts{w} ) { $width = $opts{w} ; }
if( $opts{h} ) { $height = $opts{h} ; }
if( $opts{b} ) { $background = $opts{b} ; }
if( $opts{f} ) { $fill = $opts{f} ; }
my $x_max 	= $width;
my $y_max 	= $height;
my $x_min 	= 5;
my $y_min 	= 5;

my $top 	= MainWindow->new();
my $frame 	= $top->Frame();
my $can 	= $top->Canvas( 
			-width => $width, 
			-height=> $height,
			-background => $background
#			-foreground => $foreground
		);
my $N = 10;
my @LoH;
my $vp = new Viewport();

sub incN { $N++; }
sub clear{ $can->delete( 'all' ); }
sub doit { 
	my $alpha = 0;
	my $theta = 0;
	my $phi	  = 0;
	my $x	  = 0;
	my $y	  = 0;
	my $start_x = 0;
	my $start_y = 0;
	my $rec = {};
	$rec->{x} = $x; $rec->{y} = $y; $rec->{code} = 0;
	push @LoH, $rec;
#print "xy = $x $y code = 0 count = $#LoH\n";	
	$vp->updatewindowboundaries( $x, $y );
	srand();
	while( $N-- > 1  ) {
		my $rec = {};
		$theta = rand(91) % 91 - 45;
		$alpha = ($alpha + $theta)/2;
		$phi += $alpha * PIdiv180;
		$x +=cos($phi);
		$y +=sin($phi);
		$rec->{x} = $x; $rec->{y} = $y; $rec->{code} = 1;
		push @LoH, $rec;
#print "xy = $x $y code = 0 count = $#LoH\n";	
		$vp->updatewindowboundaries( $x, $y );
	}
	$vp->viewportboundaries ( $x_min, $x_max, $y_min, $y_max, 0.9 );
	$can->create ( 'line', $x_min, $y_min, $x_min, $y_max, -fill =>$fill );
	$can->create ( 'line', $x_min, $y_max, $x_max, $y_max , -fill =>$fill);
	$can->create ( 'line', $x_max, $y_max, $x_max, $y_min, -fill =>$fill );
	$can->create ( 'line', $x_max, $y_min, $x_min, $y_min, -fill =>$fill );

	foreach my $r ( @LoH )  {
		my $xx = $r->{x};
		my $yy = $r->{y};
		my $ccode = $r->{code};
		if ( $ccode == 1 ) {
			my $x1 = $vp->x_viewport($start_x);
			my $y1 = $vp->y_viewport($start_y);
			my $x2 = $vp->x_viewport($xx); 
			my $y2 = $vp->y_viewport($yy);
			$can->create ( 'line', 
				$x1, $y1, $x2, $y2, -fill=>$fill
			);
		} 
		$start_x = $xx;
		$start_y = $yy;
	}
	@LoH = ();
}

$can->packAdjust( -side => 'left', -fill => 'both', -delay => 1 );
$frame->pack( 
	-side 	=> 'left', 
	-fill 	=> 'y', 
	-expand => 'y', 
	-anchor => 'w' );

my $nbutton = $frame->Button( 
	-relief 	=> "groove", 
	-text 		=> "n = ", 
	-command	=> \&incN  )->pack( anchor => 'w' );
my $mentry = $frame->Entry( 
	-width 	=> 10,
	-textvariable 	=> \$N)->form( 
	-left => [$nbutton,0] );

my $doButton = $frame->Button( 
	-relief 	=> "groove", 
	-text 		=> "Draw", 
	-command	=> \&doit  )->form( 
	-top => [$nbutton,0] );

my $clearButton = $frame->Button( 
	-relief 	=> "groove", 
	-text 		=> "Clear", 
	-command	=> \&clear  )->form( 
	-top 		=> [$nbutton,0],
	-left 		=> [$doButton,0] );

MainLoop;
