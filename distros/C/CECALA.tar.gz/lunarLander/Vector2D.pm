package Vector2D;
use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use overload
      "-"    => \&minus,
      "+"    => \&plus,
      "*"    => \&mult;




$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(&new);
%EXPORT_TAGS = ( DEFAULT => [qw(&new &getx &gety &getxy)],
                   Both    => [qw(&new &getx &gety)]);

sub new  {
	my ($pkg,$x,$y) = @_;
	bless {
		_x => $x,
		_y => $y
	}, $pkg;
}

sub getx { my $obj = shift; return $obj->{_x}; }
sub gety { my $obj = shift; return $obj->{_y}; }
sub setx { my $obj = shift; my $v = shift; $obj->{_x} = $v; }
sub sety { my $obj = shift; my $v = shift; $obj->{_y} = $v; }

sub getxy { 
	my $obj = shift; 
	my @xy = ( $obj->getx(), $obj->gety() );
	return @xy;
}

sub plus {
	my $u = shift;
	my $v = shift;
	return new Vector2D ( 
		$u->getx() + $v->getx(),
		$u->gety() + $v->gety()
	);
}

sub minus {
	my $u = shift;
	my $v = shift;
	return new Vector2D ( 
		$u->getx() - $v->getx(),
		$u->gety() - $v->gety()
	);
}

sub mult {
	my $v = shift;
	my $c = shift;
	return new Vector2D ( 
		$c * $v->getx(),
		$c * $v->gety()
	);
}

sub incr {
	my $u = shift;
	my $v = shift;
	$u->{_x} += $v->{_x};
	$u->{_y} += $v->{_y};
	return $u;
}

sub decr {
	my $u = shift;
	my $v = shift;
	$u->{_x} -= $v->{_x};
	$u->{_y} -= $v->{_y};
	return $u;
}

sub scale {
	my $v = shift;
	my $c = shift;
	$v->{_x} *= $c;
	$v->{_y} *= $c;
	return $v;
}

sub rotate {
	my $P = shift; #vector
	my $C = shift; #vector
	my $cosphi = shift;
	my $sinphi = shift;
	my $dx = $P->{_x} - $C->{_x};
	my $dy = $P->{_y} - $C->{_y};
	return new Vector2D ( 
		$C->{_x} + $dx * $cosphi - $dy * $sinphi,
		$C->{_y} + $dx * $sinphi + $dy * $cosphi
	);
}

sub print {
	my $v = shift; #vector
	print "( " . $v->getx() . ", " . $v->gety() . ")";
}


1;
