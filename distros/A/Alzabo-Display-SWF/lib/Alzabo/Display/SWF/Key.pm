package Alzabo::Display::SWF::Key;

use strict;
use warnings;
use fields qw/r segments name linestyle_up linestyle_over  fill1 fill2 opac/;

use SWF::Sprite;
use SWF::Shape;
use SWF::Button;
use SWF::Action;
our $VERSION = '0.01';

my $PI = 3.1415926535;

sub new {
  my $pkg = shift;
  my $self = { @_ };
  bless $self, $pkg;
  return $self;
}

sub indicator {
  my ($self, $fk) = @_;
  our ($r, $segments) = ($self->{r}, $self->{segments});
  my $c = new SWF::Sprite();
  my $b = new SWF::Button();
  my $s = new SWF::Shape();
  $s->setLineStyle( @{ $self->{linestyle_up} } );
  $s->movePenTo($r, 0);
  my $start = 0;
  #print STDERR "drawing BUTTON_UP shape ...\n";
  for ( my $end = 360/$segments; $end <= 360; $end += 360/$segments ) {
    # Calculate the midpoint angle. The control point
    # lies on this line
    my $midpoint = $start+($end-$start)/2;
    # draw_arc() draws a circular arc between 2 points
    draw_arc(
      $s,
      $r*cos(radians($start)), $r*sin(radians($start)),
      $r*cos(radians($end  )), $r*sin(radians($end  )),
      radians($midpoint)
    );
    $start = $end;
  }
  $b->addShape($s, SWF::Button::SWFBUTTON_UP);

  my $t = new SWF::Shape();
  $t->setLineStyle( @{ $self->{linestyle_over} } ); #, $self->{opac} );
  $t->movePenTo($r, 0);
  $start = 0;
  #print STDERR "drawing my BUTTON_OVER circle ...\n";
  for ( my $end = 360/$segments; $end <= 360; $end += 360/$segments ) {
    # Calculate the midpoint angle. The control point
    # lies on this line
    my $midpoint = $start+($end-$start)/2;
    # draw_arc() draws a circular arc between 2 points
    draw_arc(
      $t,
      $r*cos(radians($start)), $r*sin(radians($start)),
      $r*cos(radians($end  )), $r*sin(radians($end  )),
      radians($midpoint)
    );
    $start = $end;
  }

  scalar @{ $fk } ? $b->addShape($t, SWF::Button::SWFBUTTON_OVER)
                  : $b->addShape($s, SWF::Button::SWFBUTTON_OVER);

  my $fks = new SWF::Shape();
  $fks->setLineStyle( @{ $self->{linestyle_over} } , $self->{opac} );
  for my $fk ( @{ $fk } ) {
    my ($x, $y) = @{ $fk->{xy} };
    my $l = sqrt( $x*$x + $y*$y);
    my $z = $r+4;
    $fks->movePenTo($x*$z/$l, $y*$z/$l);
    #print STDERR "drawing Line to $fk->{name} ($x, $y)\n";
    $fks->drawLineTo($x*($l-$z)/$l, $y*($l-$z)/$l);
    #$fks->movePenTo($x+$r, $y);
    #$start = 0;
    #print STDERR "drawing other BUTTON_OVER circle ...\n";
    #for ( my $end = 360/$segments; $end <= 360; $end += 360/$segments ) {
    #  my $midpoint = $start+($end-$start)/2;
    #  draw_arc(
    #    $fks,
    #    $r*cos(radians($start)), $r*sin(radians($start)),
    #    $r*cos(radians($end  )), $r*sin(radians($end  )),
    #    radians($midpoint), $x, $y
    #  );
    #  $start = $end;
    #}
  }

  my $f1 = new SWF::Shape();
  $f1->setLineStyle( 0, @{ $self->{linestyle_up} } );
  $f1->setLeftFill($f1->addFill( @{ $self->{fill1} } ));
  $f1->movePenTo($r, 0);
  $start = 0;
  #print STDERR "drawing BUTTON_HIT circle ...\n";
  for ( my $end = 360/$segments; $end <= 360 ; $end += 360/$segments ) {
    my $midpoint = $start+($end-$start)/2;
    draw_arc(
      $f1,
      $r*cos(radians($start)), $r*sin(radians($start)),
      $r*cos(radians($end  )), $r*sin(radians($end  )),
      radians($midpoint)
    );
    $start = $end;
  }

  $c->add($f1);
  $b->addShape($f1, SWF::Button::SWFBUTTON_HIT);

  if ( defined $self->{fill2} ) {
    my $f2 = new SWF::Shape();
    $f2->setLineStyle( 0, @{ $self->{linestyle_up} } );
    $f2->setLeftFill($f2->addFill( @{ $self->{fill2} } ));
    $f2->movePenTo(-$r, 0);
    $start = 180;
    #print STDERR "drawing half circle ...\n";
    for ( my $end = 180 + 360/$segments; $end <= 360 ; $end += 360/$segments )
    {
      my $midpoint = $start+($end-$start)/2;
      draw_arc(
        $f2,
        $r*cos(radians($start)), $r*sin(radians($start)),
        $r*cos(radians($end  )), $r*sin(radians($end  )),
        radians($midpoint)
      );
      $start = $end;
    }
    $f2->drawLine(-2*$r, 0);
    $c->add($f2);
  }

  my $bi = $c->add($b);
  $b->setAction(
    new SWF::Action("nextFrame();"),
    SWF::Button::SWFBUTTON_MOUSEOVER
  );
  $b->setAction(
    new SWF::Action("play();"),
    SWF::Button::SWFBUTTON_MOUSEOUT
  );
  $c->nextFrame;
  $c->add(new SWF::Action("stop();"));
  $c->nextFrame;
  my $fki = $c->add($fks);
  $c->add(new SWF::Action("swapDepths(2);"));#
  $c->nextFrame;
  return $c;
}

sub draw_arc {
    # Take a shape, a start coordinate, end coordinate and
    # pre-computed mid-point angle as arguments
    our $r;
    my ($s, $x1, $y1, $x2, $y2, $angle, $x, $y) = @_;
    $x ||= 0;
    $y ||= 0;
    my $cx = 2*($r*cos($angle)-.25*$x1-.25*$x2);
    my $cy = 2*($r*sin($angle)-.25*$y1-.25*$y2);
    #printf STDERR "Angle %.2f :: %.2f, %.2f :: %.2f, %.2f :: %.2f, %.2f\n",
    #      $angle, $x1, $y1, $x2, $y2, $cx, $cy;

    # Draw the curve on the Shape

    $s->drawCurveTo($x+$cx, $y+$cy, $x+$x2, $y+$y2);
    #$s->drawCurve($cx-$x1, $cy-$y1, $x2-$cx, $y2-$cy);
}

sub radians { return ($_[0]/180)*$PI }

1;
