#!/usr/bin/perl -w

use strict;
use lib ('.');
use constant N=>30;
use Viewport;
use Tk;
use Tk::Canvas;
use Getopt::Std;
my $width = 500;
my $height = 500;

my %opts = ();
getopts( 'w:h:', \%opts );
if( $opts{w} ) { $width = $opts{w} ; }
if( $opts{h} ) { $height = $opts{h} ; }
my $x_max 	= $width;
my $y_max 	= $height;
my $x_min 	= 5;
my $y_min 	= 5;

my $top 	= MainWindow->new();
my $frame 	= $top->Frame();
my $can 	= $top->Canvas( -width => $width, -height=> $height );
my $curveFile = "curvefit.crv";
my @LoH;
my $vp = new Viewport();

sub getCurveFile  { 
	my $userSelectedFile = $top->getOpenFile (
		-defaultextension => ".crv",
		-filetypes	=> 
			[
				['Curve Files', '.crv'],
				['All Files', '*']
			],
		-initialdir	=>	".",	
		-initialfile	=>	"curvefit.crv",
		-title		=> 	"Selected Data File"
	); 
	if ($userSelectedFile) {
		$curveFile = $userSelectedFile;
	}
}


sub clear{ $can->delete( 'all' ); }
sub doit { 
	my $x	= 0;
	my $y	= 0;
	my $n	= 0;
	my $start_x = 0;
	my $start_y = 0;
	my $rec = {};
	unless ( open CF, "<$curveFile" ) {
		print "Cannot open $curveFile :$!\n";
		return;
	}
	$n = <CF>;
	print "n is $n";
	while(<CF>) {
		next if /^#/;
		my $rec = {};
		for my $field ( split ) {
			my ($k, $v ) = split /=/, $field;
			$rec->{$k} = $v;
		}
		push @LoH, $rec;
		$vp->updatewindowboundaries( $rec->{x}, $rec->{y} );
	}
	close CF;
	$vp->viewportboundaries ( $x_min, $x_max, $y_min, $y_max, 0.9 );
	$can->create ( 'line', $x_min, $y_min, $x_min, $y_max );
	$can->create ( 'line', $x_min, $y_max, $x_max, $y_max );
	$can->create ( 'line', $x_max, $y_max, $x_max, $y_min );
	$can->create ( 'line', $x_max, $y_min, $x_min, $y_min );

	### Draw the points
	### foreach my $r ( @LoH )  {
	### 	my $xx = $r->{x};
	### 	my $yy = $r->{y};
	### 	my $x1 = $vp->x_viewport($start_x);
	### 	my $y1 = $vp->y_viewport($start_y);
	### 	my $x2 = $vp->x_viewport($xx); 
	### 	my $y2 = $vp->y_viewport($yy);
	### 	$can->create ( 'line', $x1, $y1, $x2, $y2);
	### 	$start_x = $xx;
	### 	$start_y = $yy;
	### }
	### Draw the points
	foreach my $r ( @LoH )  {
		my $xx = $r->{x};
		my $yy = $r->{y};
		my $x1 = $vp->x_viewport($xx); 
		my $y1 = $vp->y_viewport($yy);
		$can->create ( 'line', $x1-2.0, $y1-2.0, $x1+2.0, $y1+2.0);
		$can->create ( 'line', $x1+2.0, $y1-2.0, $x1-2.0, $y1+2.0);
	}
	for ( my $i=1; $i<$n-1; $i++ ) {
		my $xA = $LoH[$i-1]->{x};
		my $xB = $LoH[$i  ]->{x};
		my $xC = $LoH[$i+1]->{x};
		my $xD = $LoH[$i+2]->{x};

		my $yA = $LoH[$i-1]->{y};
		my $yB = $LoH[$i  ]->{y};
		my $yC = $LoH[$i+1]->{y};
		my $yD = $LoH[$i+2]->{y};

print " A=( $xA, $yA ) B=( $xB, $yB ) C=( $xC, $yC ) D=( $xD, $yD ) \n";
		my $a0 = ( $xA+ 4*$xB +$xC )/ 6.0;
		my $a1 = ( $xC-$xA ) / 2.0;
		my $a2 = ( $xA- 2*$xB +$xC )/2.0;
		my $a3 = ( -$xA+ 3*($xB-$xC) + $xD)/6.0;

		my $b0 = ( $yA+ 4*$yB +$yC )/ 6.0;
		my $b1 = ( $yC-$yA ) / 2.0;
		my $b2 = ( $yA- 2*$yB +$yC )/2.0;
		my $b3 = ( -$yA+ 3*($yB-$yC) + $yD)/6.0;

		my $t = 0;
		my $start_x = $vp->x_viewport((($a3*$t+$a2)*$t+$a1)*$t+$a0);
		my $start_y = $vp->y_viewport((($b3*$t+$b2)*$t+$b1)*$t+$b0);
		for( my $j=0; $j<=N; $j++ ) {
			$t = $j/N;
			my $X = $vp->x_viewport((($a3*$t+$a2)*$t+$a1)*$t+$a0);
			my $Y = $vp->y_viewport((($b3*$t+$b2)*$t+$b1)*$t+$b0);
			$can->create ( 'line', $start_x, $start_y, $X, $Y);
			$start_x = $X;
			$start_y = $Y;
		}

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
	-text 		=> "File:", 
	-command	=> \&getCurveFile  )->pack( anchor => 'w' );
my $mentry = $frame->Entry( 
	-width 	=> 20,
	-textvariable 	=> \$curveFile)->form( -left => [$nbutton,0] );

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
