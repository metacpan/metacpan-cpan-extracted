#!/usr/bin/perl -w

use strict;
use Tk;
use Tk::Canvas;
use Getopt::Std;
use Math::Trig;
use lib ('.');
use Vector3D;
use Perspective;

my $width = 500;
my $height = 500;
my $screenDist = 1000;
my $background = 'blue';
my $fill = 'yellow';
my %opts = ();
getopts( 'w:h:b:f:', \%opts );
if( $opts{w} ) { $width = $opts{w} ; }
if( $opts{h} ) { $height = $opts{h} ; }
if( $opts{b} ) { $background = $opts{b} ; }
if( $opts{f} ) { $fill = $opts{f} ; }

my $pidiv180 = atan(1)/45;
my $top 	= MainWindow->new();
my $frame 	= $top->Frame();
my $can = $top->Canvas( 
	-width => $width, 
	-height=> $height, 
	-background=>$background );

my $rho = 10;  
my $theta = 0;  
my $phi = 0.0; 
my $rotateZ = 0.0;
my $rotateX = 0.0;
my $rotateY = 0.0;
my $TZ = 0;
my $TX = 0;
my $TY = 0;
my $N = 1;
sub clear{ $can->delete( 'all' ); }
sub doit {
	my $x_center = $can->reqwidth()/2.0;
	my $y_center = $can->reqheight()/2.0;
	my $per = new Perspective( $rho, $theta*$pidiv180, $phi*$pidiv180 );
	my @cube = (
		new Vector3D(  1, -1, -1 ), # 0
		new Vector3D(  1,  1, -1 ), # 1
		new Vector3D( -1,  1, -1 ), # 2
		new Vector3D( -1, -1, -1 ), # 3
		new Vector3D(  1, -1,  1 ), # 4
		new Vector3D(  1,  1,  1 ), # 5
		new Vector3D( -1,  1,  1 ), # 6
		new Vector3D( -1, -1,  1 )  # 7
	);

	for( my $i=0; $i<$N; $i++ ) {
	foreach my $v ( @cube ) { $v->translate( new Vector3D($TY, $TX, $TZ) ); }
	foreach my $v ( @cube ) { $v->rotateZ( $rotateZ * $pidiv180 ); }
	foreach my $v ( @cube ) { $v->rotateX( $rotateX * $pidiv180 ); }
	foreach my $v ( @cube ) { $v->rotateY( $rotateY * $pidiv180 ); }
	my( $x1, $y1, $x2, $y2 );
	$per->perspective( $cube[0], \$x1, \$y1 ); 
	$per->perspective( $cube[1], \$x2, \$y2 ); 
	$can->create( 'line',
		$screenDist * $x1 + $x_center,
		$screenDist * $y1 + $y_center,
		$screenDist * $x2 + $x_center,
		$screenDist * $y2 + $y_center,
		-fill => $fill
	);
	$per->perspective( $cube[1], \$x1, \$y1 ); 
	$per->perspective( $cube[2], \$x2, \$y2 ); 
	$can->create( 'line',
		$screenDist * $x1 + $x_center,
		$screenDist * $y1 + $y_center,
		$screenDist * $x2 + $x_center,
		$screenDist * $y2 + $y_center,
		-fill => $fill
	);
	$per->perspective( $cube[2], \$x1, \$y1 ); 
	$per->perspective( $cube[3], \$x2, \$y2 ); 
	$can->create( 'line',
		$screenDist * $x1 + $x_center,
		$screenDist * $y1 + $y_center,
		$screenDist * $x2 + $x_center,
		$screenDist * $y2 + $y_center,
		-fill => $fill
	);
	$per->perspective( $cube[3], \$x1, \$y1 ); 
	$per->perspective( $cube[0], \$x2, \$y2 ); 
	$can->create( 'line',
		$screenDist * $x1 + $x_center,
		$screenDist * $y1 + $y_center,
		$screenDist * $x2 + $x_center,
		$screenDist * $y2 + $y_center,
		-fill => $fill
	);
	$per->perspective( $cube[0], \$x1, \$y1 ); 
	$per->perspective( $cube[4], \$x2, \$y2 ); 
	$can->create( 'line',
		$screenDist * $x1 + $x_center,
		$screenDist * $y1 + $y_center,
		$screenDist * $x2 + $x_center,
		$screenDist * $y2 + $y_center,
		-fill => $fill
	);
	$per->perspective( $cube[4], \$x1, \$y1 ); 
	$per->perspective( $cube[5], \$x2, \$y2 ); 
	$can->create( 'line',
		$screenDist * $x1 + $x_center,
		$screenDist * $y1 + $y_center,
		$screenDist * $x2 + $x_center,
		$screenDist * $y2 + $y_center,
		-fill => $fill
	);
	$per->perspective( $cube[5], \$x1, \$y1 ); 
	$per->perspective( $cube[1], \$x2, \$y2 ); 
	$can->create( 'line',
		$screenDist * $x1 + $x_center,
		$screenDist * $y1 + $y_center,
		$screenDist * $x2 + $x_center,
		$screenDist * $y2 + $y_center,
		-fill => $fill
	);
	$per->perspective( $cube[5], \$x1, \$y1 ); 
	$per->perspective( $cube[6], \$x2, \$y2 ); 
	$can->create( 'line',
		$screenDist * $x1 + $x_center,
		$screenDist * $y1 + $y_center,
		$screenDist * $x2 + $x_center,
		$screenDist * $y2 + $y_center,
		-fill => $fill
	);
	$per->perspective( $cube[2], \$x1, \$y1 ); 
	$per->perspective( $cube[6], \$x2, \$y2 ); 
	$can->create( 'line',
		$screenDist * $x1 + $x_center,
		$screenDist * $y1 + $y_center,
		$screenDist * $x2 + $x_center,
		$screenDist * $y2 + $y_center,
		-fill => $fill
	);
	$per->perspective( $cube[6], \$x1, \$y1 ); 
	$per->perspective( $cube[7], \$x2, \$y2 ); 
	$can->create( 'line',
		$screenDist * $x1 + $x_center,
		$screenDist * $y1 + $y_center,
		$screenDist * $x2 + $x_center,
		$screenDist * $y2 + $y_center,
		-fill => $fill
	);
	$per->perspective( $cube[3], \$x1, \$y1 ); 
	$per->perspective( $cube[7], \$x2, \$y2 ); 
	$can->create( 'line',
		$screenDist * $x1 + $x_center,
		$screenDist * $y1 + $y_center,
		$screenDist * $x2 + $x_center,
		$screenDist * $y2 + $y_center,
		-fill => $fill
	);
	$per->perspective( $cube[7], \$x1, \$y1 ); 
	$per->perspective( $cube[4], \$x2, \$y2 ); 
	$can->create( 'line',
		$screenDist * $x1 + $x_center,
		$screenDist * $y1 + $y_center,
		$screenDist * $x2 + $x_center,
		$screenDist * $y2 + $y_center,
		-fill => $fill
	);

	}
}

$can->packAdjust( -side => 'left', -fill => 'both', -delay => 1 );
$frame->pack( 
	-side 	=> 'left', 
	-fill 	=> 'y', 
	-expand => 'y', 
	-anchor => 'w' );

my $mbutton = $frame->Button( 
	-relief 	=> "groove", 
	-text 		=> "rho = " )->pack( anchor => 'w' );
my $mentry = $frame->Entry( 
	-width 	=> 10,
	-textvariable 	=> \$rho)->form( 
	-left => [$mbutton,0] );

my $nbutton = $frame->Button( 
	-relief 	=> "groove", 
	-text 		=> "theta = ")->form( 
	-top => [$mbutton,0] );
my $nentry = $frame->Entry( 
	-width 	=> 10,
	-textvariable 	=> \$theta)->form( 
	-left => [$nbutton,0],
	-top => [$mbutton,0] );

my $phibutton = $frame->Button( 
	-relief 	=> "groove", 
	-text 		=> "phi = ", 
	)->form( -top => [$nbutton,0] );
my $phientry = $frame->Entry( 
	-width 	=> 10,
	-textvariable 	=> \$phi) ->form( 
	-left => [$phibutton,0],
	-top => [$nbutton,0] );
my $rotZbutton = $frame->Button( 
	-relief 	=> "groove", 
	-text 		=> "rotZ = ", 
	)->form( -top => [$phibutton,0] );
my $rotZentry = $frame->Entry( 
	-width 	=> 10,
	-textvariable 	=> \$rotateZ) ->form( 
	-left => [$rotZbutton,0],
	-top => [$phibutton,0] );
my $rotXbutton = $frame->Button( 
	-relief 	=> "groove", 
	-text 		=> "rotX = ", 
	)->form( -top => [$rotZbutton,0] );
my $rotXentry = $frame->Entry( 
	-width 	=> 10,
	-textvariable 	=> \$rotateX) ->form( 
	-left => [$rotXbutton,0],
	-top => [$rotZbutton,0] );
my $rotYbutton = $frame->Button( 
	-relief 	=> "groove", 
	-text 		=> "rotY = ", 
	)->form( -top => [$rotXbutton,0] );
my $rotYentry = $frame->Entry( 
	-width 	=> 10,
	-textvariable 	=> \$rotateY) ->form( 
	-left => [$rotYbutton,0],
	-top => [$rotXbutton,0] );
#####

my $TZbutton = $frame->Button( 
	-relief 	=> "groove", 
	-text 		=> "TX = ", 
	)->form( -top => [$rotYbutton,0] );
my $TZentry = $frame->Entry( 
	-width 	=> 10,
	-textvariable 	=> \$TX) ->form( 
	-left => [$TZbutton,0],
	-top => [$rotYbutton,0] );
my $TXbutton = $frame->Button( 
	-relief 	=> "groove", 
	-text 		=> "TY = ", 
	)->form( -top => [$TZbutton,0] );
my $TXentry = $frame->Entry( 
	-width 	=> 10,
	-textvariable 	=> \$TY) ->form( 
	-left => [$TXbutton,0],
	-top => [$TZbutton,0] );
my $TYbutton = $frame->Button( 
	-relief 	=> "groove", 
	-text 		=> "TZ = ", 
	)->form( -top => [$TXbutton,0] );
my $TYentry = $frame->Entry( 
	-width 	=> 10,
	-textvariable 	=> \$TZ) ->form( 
	-left => [$TYbutton,0],
	-top => [$TXbutton,0] );


######
my $dist_button = $frame->Button( 
	-relief 	=> "groove", 
	-text 		=> "Dist = ", 
	)->form( -top => [$TYbutton,0] );
my $dist_entry = $frame->Entry( 
	-width 	=> 10,
	-textvariable 	=> \$screenDist) ->form( 
	-left => [$dist_button,0],
	-top => [$TYbutton,0] );

my $N_button = $frame->Button( 
	-relief 	=> "groove", 
	-text 		=> "N = ", 
	)->form( -top => [$dist_button,0] );
my $N_entry = $frame->Entry( 
	-width 	=> 10,
	-textvariable 	=> \$N) ->form( 
	-left => [$N_button,0],
	-top => [$dist_button,0] );

my $doButton = $frame->Button( 
	-relief 	=> "groove", 
	-text 		=> "Draw", 
	-command	=> \&doit  )->form( 
	-top => [$N_button,0] );

my $clearButton = $frame->Button( 
	-relief 	=> "groove", 
	-text 		=> "Clear", 
	-command	=> \&clear  )->form( 
	-top 		=> [$N_button,0],
	-left 		=> [$doButton,0] );
MainLoop;
