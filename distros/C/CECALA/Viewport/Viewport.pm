package Viewport;
use strict;
use Exporter;
#use Tk;
#use Tk::Canvas;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(&new);
%EXPORT_TAGS = ( DEFAULT => [qw(&new)],
                   Both    => [qw(&new)]);
use constant BIG => 1.0e+30;

sub new  {
	my ($pkg) = @_;
	bless {
		_xmin 	=>  BIG,
		_ymin 	=>  BIG,
		_xmax 	=> -1 * BIG,
		_ymax 	=> -1 * BIG,
		_xC 	=> 0,
		_yC 	=> 0,
		_XC 	=> 0,
		_YC 	=> 0,
		_f  	=> 0,
		_windowset => 0
	}, $pkg;
}
sub getxmin { my $obj = shift; return $obj->{_xmin}; }
sub getymin { my $obj = shift; return $obj->{_ymin}; }

sub getxmax { my $obj = shift; return $obj->{_xmax}; }
sub getymax { my $obj = shift; return $obj->{_ymax}; }

sub getxC   { my $obj = shift; return $obj->{_xC};   }
sub getyC   { my $obj = shift; return $obj->{_yC};   }

sub getXC   { my $obj = shift; return $obj->{_XC};   }
sub getYC   { my $obj = shift; return $obj->{_YC};   }
sub getf    { my $obj = shift; return $obj->{_f};    }
sub getwindowset    { my $obj = shift; return $obj->{_windowset};    }

sub setxmin { my $obj = shift; my $v = shift; $obj->{_xmin} = $v; }
sub setymin { my $obj = shift; my $v = shift; $obj->{_ymin} = $v; }

sub setxmax { my $obj = shift; my $v = shift; $obj->{_xmax} = $v; }
sub setymax { my $obj = shift; my $v = shift; $obj->{_ymax} = $v; }

sub setxC   { my $obj = shift; my $v = shift; $obj->{_xC}   = $v; }
sub setyC   { my $obj = shift; my $v = shift; $obj->{_yC}   = $v; }

sub setXC   { my $obj = shift; my $v = shift; $obj->{_XC}   = $v; }
sub setYC   { my $obj = shift; my $v = shift; $obj->{_YC}   = $v; }
sub setf    { my $obj = shift; my $v = shift; $obj->{_f}    = $v; }
sub setwindowset    { my $obj = shift; my $v = shift; $obj->{_windowset}    = $v; }

sub updatewindowboundaries {
	my $obj = shift;
	my $x	= shift;
	my $y	= shift;
	my $xmin = $obj->getxmin();
	my $xmax = $obj->getxmax();
	my $ymin = $obj->getymin();
	my $ymax = $obj->getymax();
	if ($x < $xmin) { $obj->setxmin( $x ); }
	if ($x > $xmax) { $obj->setxmax( $x ); }
	if ($y < $ymin) { $obj->setymin( $y ); }
	if ($y > $ymax) { $obj->setymax( $y ); }
	$obj->setwindowset( 1 );
}

sub viewportboundaries {
	my $obj 		= shift;
	my $Xmin		= shift;
	my $Xmax		= shift;
	my $Ymin		= shift;
	my $Ymax		= shift;
	my $reductionfactor 	= shift;
	my $xmin = $obj->getxmin();
	my $xmax = $obj->getxmax();
	my $ymin = $obj->getymin();
	my $ymax = $obj->getymax();
	my ( $fx, $fy );
	my $windowset = $obj->getwindowset();
	if ( $windowset == 0 ) {
		die "Viewport::updatewindowboundaries() has not been called\n";
	}
		
	$obj->setXC( 0.5 * ( $Xmin + $Xmax ));
	$obj->setYC( 0.5 * ( $Ymin + $Ymax ));
	$fx = ($Xmax-$Xmin) / ( $xmax - $xmin + 1.0E-7);
	$fy = ($Ymax-$Ymin) / ( $ymax - $ymin + 1.0E-7);
	$obj->setf( $reductionfactor * ($fx<$fy?$fx:$fy));
	$obj->setxC( 0.5 * ( $xmin + $xmax ));
	$obj->setyC( 0.5 * ( $ymin + $ymax ));
}

sub x_viewport {
	my $obj = shift;
	my $x 	= shift;
	my $xC	= $obj->getxC();
	my $XC	= $obj->getXC();
	my $f	= $obj->getf();
	my $rc 	= $XC + $f * ($x - $xC);
	return $rc;
}

sub y_viewport {
	my $obj = shift;
	my $y 	= shift;
	my $yC	= $obj->getyC();
	my $YC	= $obj->getYC();
	my $f	= $obj->getf();
	my $rc  = $YC + $f * ($yC-$y);
	#works but upside down my $rc  = $YC + $f * ($y-$yC);
	return $rc;
}

sub print {
	my $obj = shift;
	print  	"$obj->{_xmin}:$obj->{_ymin}:" .
		"$obj->{_xmax}:$obj->{_ymax}:" .
		"$obj->{_xC}:$obj->{_yC}:$obj->{_XC}:" .
		"$obj->{_YC}:$obj->{_f}\n";
}

1;
