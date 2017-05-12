package Alzabo::Display::SWF::Column;

use strict;
use warnings;

use SWF qw(:ALL);
use Alzabo::Display::SWF::Util qw/rgb2ary button_shape/;
use Alzabo::Display::SWF::Text;
our $VERSION = '0.01';

sub new {
  my ($pkg, $name, $cfg) = @_;
  my ( $fdb, $bfdb ) = map $cfg->{fdb_dir}.'/'.$_.'.fdb'
                           => $cfg->{column}{fdb}{up},
                              $cfg->{column}{fdb}{over};

  my @c_bg = rgb2ary( $cfg->{column}{color}{bg} );
  my @c_up = rgb2ary( $cfg->{column}{color}{fg}{up} );
  my @c_over = rgb2ary( $cfg->{column}{color}{fg}{over} );

  my $f = new SWF::Font $fdb;
  my $fb = new SWF::Font $bfdb;

  my $t = new Alzabo::Display::SWF::Text $name, $f, @c_up;
  my $tb = new Alzabo::Display::SWF::Text $name, $fb, @c_over;
  my $w = $tb->getStringWidth($name);

  my $bs1 = button_shape($w, @c_bg);
  my $bs2 = button_shape($w, @c_bg);

  my $b = new SWF::Button;
  $b->addShape($bs1, SWF::Button::SWFBUTTON_HIT);
  $b->addShape($bs1, SWF::Button::SWFBUTTON_UP);
  $b->addShape($bs2, SWF::Button::SWFBUTTON_OVER);
  $b->setAction(
    new SWF::Action("nextFrame();"),
    SWF::Button::SWFBUTTON_MOUSEOVER
  );
  $b->setAction(
    new SWF::Action("play();"),
    SWF::Button::SWFBUTTON_MOUSEOUT
  );
  my $v = new SWF::Sprite;
  my $bi = $v->add($b);

  $bi->moveTo(-1, -11);
  $bi->setName("button");
  my $ti = $v->add($t);
  $v->nextFrame;
  $v->add(new SWF::Action("stop();"));
  $v->nextFrame;
  $v->remove($ti);
  $v->add($tb);
  $v->nextFrame;

  my $self = { sprite => $v, width => $w, dy => undef, displayItem => undef,
               is_primary_key => undef, is_foreign_key => undef,
               foreign_keys => [] };
  bless $self, $pkg;
  return $self;
}

1;
