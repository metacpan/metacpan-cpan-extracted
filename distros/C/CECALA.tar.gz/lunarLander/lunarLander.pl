#!/usr/bin/perl -w


### Place g in m/sec2  
### Moon 1.62
### Mercury   3.58
### Venus 8.87
### Mars 3.74
### Jupiter   26.01
### Saturn   11.17
### Uranus   10.49
### Neptune   13.25
### Pluto 0.73

use strict;
use lib ('../Vectors2D');
use lib ('../Viewport');
use lib ('../Clip2');

use Tk;
use Tk::Canvas;
use Math::Trig;
use Vector2D;
use Viewport;
use Clip2;
use Getopt::Std;

my $width = 500;
my $height = 500;
my $background = 'blue';
my $fill = 'yellow';
my $gravity = new Vector2D(0, 1.62);
my $acceleration = new Vector2D(0, 20.0);
my $LanderVelocity = new  Vector2D( 0, 0 );
my $staticWindow = 0;
my $accelerationAbs = 20.0;
my %opts = ();
getopts( 'w:h:b:f:g:X:Y:a:S', \%opts );
if( $opts{w} ) { $width = $opts{w} ; }
if( $opts{h} ) { $height = $opts{h} ; }
if( $opts{b} ) { $background = $opts{b} ; }
if( $opts{f} ) { $fill = $opts{f} ; }
if( $opts{g} ) { $gravity->sety ($opts{g}) ; }
if( $opts{a} ) { 
	$acceleration->sety ($opts{a}) ; 
	$accelerationAbs = $opts{a};
}
if( $opts{X} ) { $LanderVelocity->setx ($opts{X}) ; }
if( $opts{Y} ) { $LanderVelocity->sety ($opts{Y}) ; }
if( $opts{S} ) { $staticWindow = 1; }

my @LandScape = (
	new Vector2D(  -800,   40 ), #pt 0
	new Vector2D(  -500,   50 ), #pt 1
	new Vector2D(  -400,   50 ), #pt 2
	new Vector2D(  -300,  100 ), #pt 3
	new Vector2D(  -100,    0 ), #pt 4
	new Vector2D(   100,    0 ), #pt 5
	new Vector2D(   150,   75 ), #pt 7
	new Vector2D(   300,   75 ), #pt 8
	new Vector2D(   400,   300 ), #pt 9
	new Vector2D(   450,   100 ), #pt 10
	new Vector2D(   800,   0 ), #pt 11
);

my @Lander = (
	new Vector2D(  0,  0 + 800), #pt 0
	new Vector2D( 10,  0 + 800), #pt 1
	new Vector2D(  5,  0 + 800), #pt 2
	new Vector2D( 10, 10 + 800), #pt 3
	new Vector2D( 20, 20 + 800), #pt 4
	new Vector2D( 40, 20 + 800), #pt 5
	new Vector2D( 50, 10 + 800), #pt 6
	new Vector2D( 55,  0 + 800), #pt 7
	new Vector2D( 50,  0 + 800), #pt 8
	new Vector2D( 60,  0 + 800), #pt 9
	new Vector2D( 55, 30 + 800), #pt 10
	new Vector2D( 55, 40 + 800), #pt 11
	new Vector2D( 40, 50 + 800), #pt 12
	new Vector2D( 20, 50 + 800), #pt 13
	new Vector2D(  5, 40 + 800), #pt 14
	new Vector2D(  5, 30 + 800), #pt 15
	new Vector2D( 30, -40 + 800), #thruster flame pt 16
	new Vector2D( 30, 25 + 800) #center of gravity pt 17
);

my $top = MainWindow->new();
my $can = $top->Canvas( 
	-width => $width, 
	-height=> $height,
	-background => $background  )->form();

my $x_max 	= $width;
my $y_max 	= $height;
my $x_min 	= 5;
my $y_min 	= 5;
my $x_center = $can->reqwidth()/2.0;
my $y_center = $can->reqheight()/2.0;

my $pi	= 4 * atan(1.0);
my $phi = $pi/15.0;

my $cosphi = cos ( $phi );
my $sinphi = sin ( $phi );
my $center = new Vector2D( $x_center, $y_center );
my $r_max = $can->reqwidth()/2;
my $start = $center->plus( new Vector2D( 0.9 * $r_max, 0 ) );
my $vp = new Viewport();
my $clipbox = new Clip2();

### set up Keys
sub kPressed { ### Fire Thruster
	#Draw Thruster Flame
	&drawThrusterFlame;
	$LanderVelocity->incr( $acceleration );
	Ev('k');
}
sub lPressed { ### Rotate clockwise
	&rotateLanderCounterClockwise;
	Ev('l');
}

sub jPressed { ### Rotate clockwise
	&rotateLanderClockwise;
	Ev('j');
}

$top->bind( '<Key-k>',  \&kPressed );
$top->bind( '<Key-l>',  \&lPressed );
$top->bind( '<Key-j>',  \&jPressed );
### set up window
foreach my $v ( @Lander ) {
	$vp->updatewindowboundaries( $v->getx(), $v->gety() );
}
foreach my $v ( @LandScape ) {
	$vp->updatewindowboundaries( $v->getx(), $v->gety() );
}
$vp->viewportboundaries ( $x_min, $x_max, $y_min, $y_max, 0.9 );

&drawLander;
&drawLandScape;
$can->after( 100, \&play );
MainLoop;

sub rotateLanderClockwise {
	### $Lander[17] is Lander's center of gravity
	foreach my $v ( @Lander ) {
		$v = $v->rotate( $Lander[17], $cosphi, $sinphi );
	}
	$acceleration = $acceleration->rotate( 
		new Vector2D( 0.0, 0.0),
		$cosphi, 
		$sinphi 
	);
}

sub rotateLanderCounterClockwise {
	### $Lander[17] is Lander's center of gravity
	foreach my $v ( @Lander ) {
		$v = $v->rotate( $Lander[17], $cosphi, -$sinphi );
	}
	$acceleration = $acceleration->rotate( 
		new Vector2D( 0.0,0.0),
		$cosphi, 
		-$sinphi 
	);
}


sub moveLander {
	$can->delete( 'Lander' );
	$LanderVelocity->decr ( $gravity );
	foreach my $v ( @Lander ) {
		# my $u = $LanderVelocity->plus( $gravity->mult( 0.5 ));
		my $u = $LanderVelocity + $gravity *  0.5;
		$v->incr( $u );
		if ( $staticWindow == 0 ) {
			$vp->updatewindowboundaries( $v->getx(), $v->gety() );
		}
	}
	if ( $staticWindow == 0 ) {
		$vp->viewportboundaries ( $x_min, $x_max, $y_min, $y_max, 0.9 );
		&drawLandScape;
	}
	&drawLander;
}

# Physics: 
# 	xt = x0 + v0t + ½at2
#       vt = v0 + at
#       a  = -9.8 
#### Perl
#
#
# t=1 let a = 9.8 for earth
#	x = x + v + 0.5 a	
#	x +=v + 0.5 a	
#
#	v = v + a
#	v += a
sub play {
	&moveLander;
	&updateClipBox;
#	&drawClipBox;
	my $rc = 0; #&touchDown;
	if ( $rc == 0 ) {
		$can->after( 100, \&play );
	} elsif ( $rc < 0 ) {
		print "CRASH!!!!\n";
	} else {
		print "The eagle has landed!\n";	
	}
}

sub drawClipBox {
	$can->create ( 'line', 
		$vp->x_viewport($clipbox->getxmin()), 
		$vp->y_viewport($clipbox->getymin()), 
		$vp->x_viewport($clipbox->getxmin()), 
		$vp->y_viewport($clipbox->getymax()), 
		-fill => $fill,
		-tag  => 'clipbox'
	);
	$can->create ( 'line', 
		$vp->x_viewport($clipbox->getxmin()), 
		$vp->y_viewport($clipbox->getymax()), 
		$vp->x_viewport($clipbox->getxmax()), 
		$vp->y_viewport($clipbox->getymax()), 
		-fill => $fill,
		-tag  => 'clipbox'
	);
	$can->create ( 'line', 
		$vp->x_viewport($clipbox->getxmax()), 
		$vp->y_viewport($clipbox->getymax()), 
		$vp->x_viewport($clipbox->getxmax()), 
		$vp->y_viewport($clipbox->getymin()), 
		-fill => $fill,
		-tag  => 'clipbox'
	);
	$can->create ( 'line', 
		$vp->x_viewport($clipbox->getxmax()), 
		$vp->y_viewport($clipbox->getymin()), 
		$vp->x_viewport($clipbox->getxmin()), 
		$vp->y_viewport($clipbox->getymin()), 
		-fill => $fill,
		-tag  => 'clipbox'
	);
}

sub touchDown {
	my $clipped = 0;
	for ( my $i=0; $i<$#LandScape ; $i++ ) {
		$clipped = $clipbox->cliped( 
			$LandScape[$i]->getx(),
			$LandScape[$i]->gety(),
			$LandScape[$i+1]->getx(),
			$LandScape[$i+1]->gety()
		); 
		$can->create( 'line', 
			$vp->x_viewport($LandScape[$i]->getx()),
			$vp->y_viewport($LandScape[$i]->gety()),
			$vp->x_viewport($LandScape[$i+1]->getx()),
			$vp->y_viewport($LandScape[$i+1]->gety()),
			-fill => 'white'
		); 
	}
#	print "Clip is $clipped\n";
	return $clipped;
}

sub drawThrusterFlame {
	$can->create ( 'line', 
		$vp->x_viewport($Lander[4]->getx()), 
		$vp->y_viewport($Lander[4]->gety()), 
		$vp->x_viewport($Lander[16]->getx()), 
		$vp->y_viewport($Lander[16]->gety()), 
		-fill => $fill,
		-tag  => ['Flame', 'Lander']
	);
	$can->create ( 'line', 
		$vp->x_viewport($Lander[16]->getx()), 
		$vp->y_viewport($Lander[16]->gety()), 
		$vp->x_viewport($Lander[5]->getx()), 
		$vp->y_viewport($Lander[5]->gety()), 
		-fill => $fill,
		-tag  => ['Flame', 'Lander']
	);
}

sub drawLandScape {
	$can->delete( 'LandScape' );
	my $start_x = $LandScape[0]->getx();
	my $start_y = $LandScape[0]->gety();
	for my $v ( @LandScape ) {
		$can->create ( 'line', 
			$vp->x_viewport($start_x), 
			$vp->y_viewport($start_y), 
			$vp->x_viewport($v->getx()), 
			$vp->y_viewport($v->gety()), 
			-fill => $fill,
			-tag  => 'LandScape'
		);
		$start_x = $v->getx();
		$start_y = $v->gety();
	};
}
	
sub drawLander {
	$can->create ( 'line', 
		$vp->x_viewport($Lander[0]->getx()), 
		$vp->y_viewport($Lander[0]->gety()), 
		$vp->x_viewport($Lander[1]->getx()), 
		$vp->y_viewport($Lander[1]->gety()), 
		-fill => $fill,
		-tag  => 'Lander'
	);
	$can->create ( 'line', 
		$vp->x_viewport($Lander[2]->getx()), 
		$vp->y_viewport($Lander[2]->gety()), 
		$vp->x_viewport($Lander[3]->getx()), 
		$vp->y_viewport($Lander[3]->gety()), 
		-fill => $fill,
		-tag  => 'Lander'
	);
	$can->create ( 'line', 
		$vp->x_viewport($Lander[3]->getx()), 
		$vp->y_viewport($Lander[3]->gety()), 
		$vp->x_viewport($Lander[4]->getx()), 
		$vp->y_viewport($Lander[4]->gety()), 
		-fill => $fill,
		-tag  => 'Lander'
	);
	$can->create ( 'line', 
		$vp->x_viewport($Lander[4]->getx()), 
		$vp->y_viewport($Lander[4]->gety()), 
		$vp->x_viewport($Lander[5]->getx()), 
		$vp->y_viewport($Lander[5]->gety()), 
		-fill => $fill,
		-tag  => 'Lander'
	);
	$can->create ( 'line', 
		$vp->x_viewport($Lander[5]->getx()), 
		$vp->y_viewport($Lander[5]->gety()), 
		$vp->x_viewport($Lander[6]->getx()), 
		$vp->y_viewport($Lander[6]->gety()), 
		-fill => $fill,
		-tag  => 'Lander'
	);
	$can->create ( 'line', 
		$vp->x_viewport($Lander[6]->getx()), 
		$vp->y_viewport($Lander[6]->gety()), 
		$vp->x_viewport($Lander[7]->getx()), 
		$vp->y_viewport($Lander[7]->gety()), 
		-fill => $fill,
		-tag  => 'Lander'
	);
	$can->create ( 'line', 
		$vp->x_viewport($Lander[8]->getx()), 
		$vp->y_viewport($Lander[8]->gety()), 
		$vp->x_viewport($Lander[9]->getx()), 
		$vp->y_viewport($Lander[9]->gety()), 
		-fill => $fill,
		-tag  => 'Lander'
	);
	$can->create ( 'line', 
		$vp->x_viewport($Lander[5]->getx()), 
		$vp->y_viewport($Lander[5]->gety()), 
		$vp->x_viewport($Lander[10]->getx()), 
		$vp->y_viewport($Lander[10]->gety()), 
		-fill => $fill,
		-tag  => 'Lander'
	);
	$can->create ( 'line', 
		$vp->x_viewport($Lander[10]->getx()), 
		$vp->y_viewport($Lander[10]->gety()), 
		$vp->x_viewport($Lander[11]->getx()), 
		$vp->y_viewport($Lander[11]->gety()), 
		-fill => $fill,
		-tag  => 'Lander'
	);
	$can->create ( 'line', 
		$vp->x_viewport($Lander[11]->getx()), 
		$vp->y_viewport($Lander[11]->gety()), 
		$vp->x_viewport($Lander[12]->getx()), 
		$vp->y_viewport($Lander[12]->gety()), 
		-fill => $fill,
		-tag  => 'Lander'
	);
	$can->create ( 'line', 
		$vp->x_viewport($Lander[12]->getx()), 
		$vp->y_viewport($Lander[12]->gety()), 
		$vp->x_viewport($Lander[13]->getx()), 
		$vp->y_viewport($Lander[13]->gety()), 
		-fill => $fill,
		-tag  => 'Lander'
	);
	$can->create ( 'line', 
		$vp->x_viewport($Lander[13]->getx()), 
		$vp->y_viewport($Lander[13]->gety()), 
		$vp->x_viewport($Lander[14]->getx()), 
		$vp->y_viewport($Lander[14]->gety()), 
		-fill => $fill,
		-tag  => 'Lander'
	);
	$can->create ( 'line', 
		$vp->x_viewport($Lander[14]->getx()), 
		$vp->y_viewport($Lander[14]->gety()), 
		$vp->x_viewport($Lander[15]->getx()), 
		$vp->y_viewport($Lander[15]->gety()), 
		-fill => $fill,
		-tag  => 'Lander'
	);
	$can->create ( 'line', 
		$vp->x_viewport($Lander[15]->getx()), 
		$vp->y_viewport($Lander[15]->gety()), 
		$vp->x_viewport($Lander[4]->getx()), 
		$vp->y_viewport($Lander[4]->gety()), 
		-fill => $fill,
		-tag  => 'Lander'
	);
}

### get collision detection bounding box from lander
sub updateClipBox {
	my $smallest_x 	= $Lander[0]->getx();
	my $smallest_y 	= $Lander[0]->gety();
	my $largest_x 	= $Lander[0]->getx();
	my $largest_y 	= $Lander[0]->gety();
	my $i = 0;

	
	foreach my $v ( @Lander ) {
		# pts 16 and 17 are not really parts of the lander
		# pt 16 is the flame and 17 is center of gravity
		if ( $i < 16 ) {
			if( $v->getx() <= $smallest_x ) { $smallest_x = $v->getx(); }
			if( $v->gety() <= $smallest_y ) { $smallest_y = $v->gety(); }
			if( $v->getx() >= $largest_x ) { $largest_x = $v->getx(); }
			if( $v->gety() >= $largest_y ) { $largest_y = $v->gety(); }
		}
		$i++;
	}
	$clipbox->setclipboundaries( $smallest_x, $smallest_y, $largest_x, $largest_y);
#	print " ($smallest_x, $smallest_y, $largest_x, $largest_y) \n";
}
