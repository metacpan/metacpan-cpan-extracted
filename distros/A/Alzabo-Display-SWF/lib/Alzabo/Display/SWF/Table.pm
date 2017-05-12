package Alzabo::Display::SWF::Table;

use strict;
use warnings;
use SWF qw(:ALL);
use Alzabo::Display::SWF::Util qw/rgb2ary/;
use Alzabo::Display::SWF::Text;
use Alzabo::Display::SWF::Column;
our $VERSION = '0.01';

sub new {
  my ($pkg, $t, $m, $scale, $cfg ) = @_;
  my $tfdb = $cfg->{fdb_dir} . '/' . $cfg->{table}{fdb} .'.fdb';

  my $self = { columns => [], text => undef , head => undef , body => undef,
               dx => undef, dy => undef, keys => [], column_by_name => {} };
  bless $self, $pkg;

  my $f = new SWF::Font $tfdb;
  my $txt = new Alzabo::Display::SWF::Text
    $t->name, $f, rgb2ary( $cfg->{table}{color}{fg} );
  my $w = 0;
  my $dx = 14;
  my $dy = 0;
  for my $c ( $t->columns ) {
    my $co = new Alzabo::Display::SWF::Column $c->name, $cfg;
    $self->{column_by_name}{$c->name} = $co;
    $co->{dy} = $dy;
    $w = $_ > $w ? $_ : $w for $co->{width} + $dx;
    $dy+=20;
  }
  $w = $_ > $w ? $_ : $w for $txt->getStringWidth($t->name) + 14;
  $w += 10;
  $dy += 3;

  my $th = new SWF::Shape;
  $th->setLineStyle($scale*2, rgb2ary( $cfg->{table}{linestyle}{color} ));
  $th->setLeftFill($th->addFill( rgb2ary( $cfg->{table}{color}{bg} )));
  $th->movePenTo(0, 6);
  $th->drawLine(0, 13);
  $th->drawLine($w, 0);
  $th->drawLine(0, -13);
  $th->drawCurve(0, -6, -6, 0);
  $th->drawLine(-$w+12, 0);
  $th->drawCurve(-6, 0, 0, 6);
  my $tb = new SWF::Shape;
  $tb->setLineStyle($scale*2, rgb2ary( $cfg->{table}{linestyle}{color} ) );
  $tb->setLeftFill($tb->addFill(rgb2ary( $cfg->{column}{color}{bg} )));
  $tb->movePenTo(0, 19);
  $tb->drawLine(0, $dy);
  $tb->drawLine($w, 0);
  $tb->drawLine(0, -$dy);
  $tb->drawLine(-$w, 0);

  $self->{head} = $m->add($th);
  $self->{body} = $m->add($tb);
  $self->{text} = $m->add($txt);
  $self->{width} = $w;
  $self->{height} = $dy + 19;

  return $self;
}

sub moveTo {
  my ($self, $x, $y)  = @_;
  $self->{head}->moveTo($x, $y+6);
  $self->{body}->moveTo($x, $y+6);
  $self->{text}->moveTo($x+19, $y+19);
  my $dy = 33;
  for ( 0 .. $#{ $self->{columns} } ) { 
    $self->{columns}[$_]->moveTo($x+19, $y+$dy+6);
    $self->{keys}[$_]->moveTo($x+10, $y+$dy+3) if $self->{keys}[$_];
    $dy+=20;
  }
}

1;
