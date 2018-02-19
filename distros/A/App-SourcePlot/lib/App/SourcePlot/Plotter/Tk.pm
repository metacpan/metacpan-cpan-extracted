package App::SourcePlot::Plotter::Tk;

=head1 NAME

App::SourcePlot::Plotter::Tk - creates a Tk canvas with easy-to-use method names.

=head1 DESCRIPTION

This class provides methods to use a GUI canvas with ease.  The
commands will be generalized to ensure easy transfer between graphing
packages.


=cut

use 5.004;
use Carp;
use strict;
use vars qw/$VERSION/;

# Load Tk module
use Tk;

$VERSION = '1.29';

=head1 EXTERNAL MODULES

  Tk

=cut

=head1 PUBLIC METHODS

These are the methods avaliable in this class:

=over 4

=item new

Create a new instance of Plotter::Tk object.  A new canvas will be
created with the specified coordinates.  This method will create a new
window for use by the canvas if one is not passed in.

  $plotter = new App::SourcePlot::Plotter::Tk();
  $plotter = new App::SourcePlot::Plotter::Tk($width, $height);
  $plotter = new App::SourcePlot::Plotter::Tk($width, $height, $numWindowsX, $numWindowsY);
  $plotter = new App::SourcePlot::Plotter::Tk($width, $height, $numWindowsX, $numWindowsY, $MainWindow);

=cut

sub new {

  my $proto = shift;
  my $class = ref($proto) || $proto;

  my $ET = {};  # Anon hash

  if (@_) {
    $ET->{X_SIZE} = shift;
    $ET->{Y_SIZE} = shift;
    $ET->{X_SIZE} = 200 if ($ET->{X_SIZE} == 0);
    $ET->{Y_SIZE} = 200 if ($ET->{Y_SIZE} == 0);
  } else {
    $ET->{X_SIZE} = 200;
    $ET->{Y_SIZE} = 200;
  }

  bless($ET, $class);

  my $numx = 1;
  my $numy = 1;
  # how many canvases to make
  if (@_) {
    $numx = shift;
    $numy = shift;
  }
  if (@_) {
    my $screen = shift;
    my $frame;
    my ($i,$j);
    for ($i=0;$i<$numy;$i++) {
      $frame = $screen->Frame;
      for ($j=0;$j<$numx;$j++) {
        $ET->{CANVAS}[$i*$numy + $j] = $frame->Canvas(
            -background=>"LightCyan3",
            -relief => 'raised',
            -width  => $ET->{X_SIZE},
            -height => $ET->{Y_SIZE},
            -cursor => 'top_left_arrow',
        );
        $ET->{CANVAS}[$i*$numy + $j]->pack(-side => 'left', -fill => 'x');
      }
      $frame->pack(-side=>'top');
    }
    $ET->numCanvases($numx * $numy);
  } else {
    $ET->{MW} = MainWindow->new;
    $ET->{MW}->resizable(0,0);
    $ET->{CANVAS} = $ET->{MW}->Canvas(
          -background=>"LightCyan3",
          -relief => 'raised',
          -width  => $ET->{X_SIZE},
          -height => $ET->{Y_SIZE},
          -cursor => 'top_left_arrow',
    );
    $ET->{MW}->configure(-background=>"#eeeeee", -foreground=>"#000088");
  }
  $ET->{FONT} = '-*-Helvetica-Medium-R-Normal--*-140-*-*-*-*-*-*';
  $ET->{FONT_COLOR} = 'Black';
  $ET->{DRAW_COLOR} = 'Black';
  $ET->{PEN_WIDTH} = 1;
  $ET->{SUFFIX} = "gif";

  $ET->gamma(1.0);
  $ET->setWorldSize(0, 0, 1, 1);
  $ET->usingWorld(0);
  $ET->currentCanvasNum(0);
  $ET->zoomNum(1);

  return $ET;
}


=item destroy

Destroys an object of this type.  Cleans up the variables and windows
within.

  destroy $plotter;

=cut

sub DESTROY {
  my $self = shift;
  $self->{MW}->destroy if defined $self->{MW};
}

############################################################
#  Canvas functions
#


=item getCanvas

Used specifically within this module, it allows the programmer to add
new features to this module with ease by accessing the Tk canvas

  $can = $plotter->getCanvas();

=cut

# canvas object returned
sub getCanvas {
  my $self = shift;
  return $self->{CANVAS}[$self->currentCanvasNum()];
}


=item currentCanvasNum

Either sets the current canvas by number or returns the current
canvass number.

  $canNum = $plotter->currentCanvasNum();
  $plotter->currentCanvasNum(3);

=cut

sub currentCanvasNum {
  my $self = shift;
  if (@_) {
    $self->{CURRENT_CANVAS_NUM} = shift;
  }
  return $self->{CURRENT_CANVAS_NUM};
}


=item nextCanvas

increments the current canvas number by one, looping back to 0 if
passing the last.

  $plotter->nextCanvas();

=cut

sub nextCanvas {
  my $self = shift;
  my $c = $self->currentCanvasNum() + 1;
  $self->currentCanvasNum($c);
  if (!defined $self->getCanvas()) {
    $self->currentCanvasNum(0);
  }
  return $self->getCanvas();
}


=item numCanvases

Sets and returns the number of canvases.

  $numCan = $plotter->numCanvases();
  $plotter->numCanvases(3);

=cut

sub numCanvases {
  my $self = shift;
  if (@_) {
    $self->{NUM_CANVASES} = shift;
  }
  return $self->{NUM_CANVASES};
}

############################################################
#  Setup tools
#


=item defaultSuffix

Returns the default suffix for graphics files

  $suf = $plotter->defaultSuffix();
  $plotter->defaultSuffix('gif');

=cut

sub defaultSuffix {
  my $self = shift;
  $self->{SUFFIX} = shift if @_;
  return $self->{SUFFIX};
}


=item width

Returns the width of a canvas.

  $w = $plotter->width();

=cut

sub width {
  my $self = shift;
  return $self->toWx ($self->{X_SIZE});
}


=item height

Returns the width of a canvas.

  $w = $plotter->height();

=cut

sub height {
  my $self = shift;
  return $self->toWy($self->{Y_SIZE});
}


=item setBackground

Sets the background color

  $plotter->setBackground('black');

=cut

sub setBackground {
  my $self = shift;
  my $color = shift;
  $self->getCanvas()->configure(-background=>$color);
}


=item setForeground

Sets the foreground color

  $plotter->setForeground('black');

=cut

sub setForeground {
  my $self = shift;
  my $color = shift;
  $self->getCanvas()->configure(-foreground=>$color);
  #-background=>$bbg, -foreground=>$bfg
}


=item font

Sets and returns the font currently being used

  $f = $plotter->font();
  $plotter->font($f);

=cut

sub font {
  my $self = shift;
  if (@_) {
    $self->{FONT} = shift;
  }
  return $self->{FONT};
}


=item fontColor

Sets and returns the font color

  $plotter->fontColor('black');

=cut

sub fontColor {
  my $self = shift;
  if (@_) {
    $self->{FONT_COLOR} = shift;
  }
  return $self->{FONT_COLOR};
}


=item fontSize

Sets and returns the font size

  $plotter->fontSize(5);
  $size = $plotter->fontSize();

=cut

sub fontSize {
  my $self = shift;
  my $font = $self->font();
  $font =~ /\d+/;
  my $before = $`;
  my $num = $&;
  my $end = $';
  if (@_) {
    my $size = shift;
    $self->font ($before . $size  . '0' . $end);
    $self->{FONTSIZE} = $size;
  } else {
    $self->{FONT_SIZE} = $num/10 if (!defined $self->{FONT_SIZE});
  }
  return $self->{FONT_SIZE};
}


=item drawColor

Sets and returns the drawing color, used for filling as well.

  $plotter->drawColor('Black');
  $c = $plotter->drawColor();

=cut

sub drawColor {
  my $self = shift;
  if (@_) {
    $self->{DRAW_COLOR} = shift;
  }
  return $self->{DRAW_COLOR};
}


=item penWidth

Sets and returns the width lines, circles, etc will be drawn in.

  $plotter->penWidth(3);
  $w = $plotter->penWidth();

=cut

sub penWidth {
  my $self = shift;
  if (@_) {
    $self->{PEN_WIDTH} = shift;
  }
  return $self->{PEN_WIDTH};
}


=item pack

Packs the current canvas into a certain position within a main window
or frame.

  $plotter->pack(-side => 'left');

=cut

sub pack {
  my $self = shift;
  $self->getCanvas()->pack(@_);
}

############################################################
#  The conversion tools from world to pixels
#


=item worldCenter

Sets the center of the world coordinates on the screen Best to set the
centre in pixels, and then the appropriate world coordinates can be
set at this point using worldAtZero.

  $plotter->worldCenter ($centerx, $centery);

=cut

sub worldCenter {
  my $self = shift;
  if (@_) {
    ($self->{W_CENT_X}, $self->{W_CENT_Y}) = $self->toP (shift, shift);
  }
  return ($self->{W_CENT_X}, $self->{W_CENT_Y});
}


=item worldAtZero

Offsets the centre of the world coordinates to allow specific world
coordinates to be the new centre coordinates.

  $plotter->worldAtZero ($centerx, $centery);

=cut

sub worldAtZero {
  my $self = shift;
  if (@_) {
    $self->{ZCENT_X} = shift;
    $self->{ZCENT_Y} = shift;
  }
  if (defined $self->{ZCENT_X}) {
    return ($self->{ZCENT_X}, $self->{ZCENT_Y});
  }
  return (0,0);
}


=item worldToPixelRatio

Sets the ratio between the world coordinates and pixels

  $plotter->worldToPixRatio ($dx, $dy);

=cut

sub worldToPixRatio {
  my $self = shift;
  if (@_) {
    $self->{W_RATIO_X} = shift;
    $self->{W_RATIO_Y} = shift;
  }
  if ($self->{W_RATIO_X} == undef) {
    my ($x, $y) = $self->photoWorldSize();
    $x = $x/$self->origPhot()->width;
    $y = $y/$self->origPhot()->height;
    $self->worldToPixRatio ($x, $y);
  }
  return ($self->{W_RATIO_X}, $self->{W_RATIO_Y});
}


=item usingWorld

Tells the module whether you wish to use the world coordinates when
specifying coordinates, or if you want to use pixels Returns and sets
the value (1 for on, 0 for off)

  $u = $plotter->usingWorld();
  $plotter->usingWorld(1);

=cut

sub usingWorld {
  my $self = shift;
  if (@_) {
    $self->{USE_WORLD} = shift;
  }
  return $self->{USE_WORLD};
}


=item setWorldSize

Sets the center of the world coordinates and the ratio between those
coordinates and pixels

  $plotter->setWorldSize ($centerx, $centery, $dx, $dy);

=cut

# must specify (x-center, y-center, x-ratio-to-pixel, y-rat)

sub setWorldSize {
  my $self = shift;
  $self->worldCenter(shift, shift);
  $self->worldToPixRatio(shift, shift);
}


=item toP

Converts coordinates into pixels.  The input coordinates are assumed
to be associated with the value in usingWorld.

  ($x, $y) = $plotter->toP ($x1, $y1);
  ($x) = $plotter->toPx ($x1);
  ($y) = $plotter->toPy ($y1);

=cut

# converts passed in paramter into pixels
# must specify (x, y)
sub toP {
  my $self = shift;
  if ($self->usingWorld()) {
    my ($zx, $zy) = $self->worldAtZero();
    my $x = (shift) - $zx;
    my $y = (shift) - $zy;
    my ($wx, $wy) = $self->worldCenter();
    my ($wratx, $wraty) = $self->worldToPixRatio();
    $x = $x / $wratx + $wx;
    $y = $y / $wraty + $wy;
    return ($x, $y);
  } else {
    return (shift, shift);
  }
}

# converts passed in paramter into pixels
# must specify (x)
sub toPx {
  my $self = shift;
  if ($self->usingWorld()) {
    my ($zx, $zy) = $self->worldAtZero();
    my $x = (shift) - $zx;
    my ($wx, $wy) = $self->worldCenter();
    my ($wratx, $wraty) = $self->worldToPixRatio();
    $x = $x / $wratx + $wx;
    return $x;
  } else {
    return (shift);
  }
}

# converts passed in paramter into pixels
# must specify (y)
sub toPy {
  my $self = shift;
  if ($self->usingWorld()) {
    my ($zx, $zy) = $self->worldAtZero();
    my $y = (shift) - $zy;
    my ($wx, $wy) = $self->worldCenter();
    my ($wratx, $wraty) = $self->worldToPixRatio();
    $y = $y / $wraty + $wy;
    return $y;
  } else {
    return (shift);
  }
}


=item toW

Converts pixel coordinates into current system.  The output
coordinates are assumed to be associated with the value in usingWorld.

  ($x, $y) = $plotter->toW ($x1, $y1);
  ($x) = $plotter->toWx ($x1);
  ($y) = $plotter->toWy ($y1);

=cut

# converts passed in paramter into the current system being used
# must specify (x, y)
sub toW {
  my $self = shift;
  if ($self->usingWorld()) {
    my ($zx, $zy) = $self->worldAtZero();
    my $x = shift;
    my $y = shift;
    my ($wx, $wy) = $self->worldCenter();
    my ($wratx, $wraty) = $self->worldToPixRatio();
    $x = ($x - $wx) * $wratx;
    $y = ($y - $wy) * $wraty;
    return ($x+$zx, $y+$zy);
  } else {
    return (shift, shift);
  }
}

# must specify (x)
sub toWx {
  my $self = shift;
  if ($self->usingWorld()) {
    my ($zx, $zy) = $self->worldAtZero();
    my $x = shift;
    my ($wx, $wy) = $self->worldCenter();
    my ($wratx, $wraty) = $self->worldToPixRatio();
    $x = ($x - $wx) * $wratx;
    return $x + $zx;
  } else {
    return (shift);
  }
}

# must specify (y)
sub toWy {
  my $self = shift;
  if ($self->usingWorld()) {
    my ($zx, $zy) = $self->worldAtZero();
    my $y = shift;
    my ($wx, $wy) = $self->worldCenter();
    my ($wratx, $wraty) = $self->worldToPixRatio();
    $y = ($y - $wy) * $wraty;
    return $y + $zy;
  } else {
    return (shift);
  }
}

############################################################
#  drawing tools
#


=item clean

Removes all drawn objects from the canvas.

  $plotter->clean();

=cut

sub clean {
  my $self = shift;
  $self->getCanvas()->delete('all');
}


=item delete

Deletes all objects with one specific tag.

  $plotter->delete ('oval');

=cut

sub delete {
  my $self = shift;
  my $tag = shift;
  $self->getCanvas()->delete($tag);
}


=item printCanvas

Prints the canvas to a printer

  $plotter->printCanvas ('file', 'filename');
  $plotter->printCanvas ('printer', '-PHello');

=cut

sub printCanvas {
  my $self = shift;
  my $choice = shift;
  my $option = shift;
  my $MW = shift;
  local (*LPR);
  if ($choice eq 'file') {
    if (!open (LPR, ">$option")) {
      error($MW, "Could not print to file:   \n   $option");
    }
  } else {
    if (!open (LPR, "| $option")) {
      error($MW, "Could not print with options:   \n   $option");
    }
  }
  print LPR $self->getCanvas()->postscript();
  close LPR;
}


=item flushGraphics

This function is not used in this module but should be included as the
last command before you want your graphics to appear.  Allows for easy
mobility between different plotters.

  $plotter->flushGraphics();

=cut

sub flushGraphics {
  my $self = shift;
}


=item configureTag

Configures the items with the given tag.

  $plotter->configureTag ('oval', -fill => 'black');

=cut

sub configureTag {
  my $self = shift;
  my $tag = shift;
  my @con = @_;
  $self->getCanvas()->itemconfigure ($tag, @con);
}


=item bindTag

Binds the items with the given tag.

  $plotter->bindTag ('oval', '<Any-Enter>' => sub {print "hello"});

=cut

sub bindTag {
  my $self = shift;
  my $tag = shift;
  my @con = @_;
  $self->getCanvas()->bind ($tag, @con);
}


=item existTag

Returns the number of items associated with that tag

  $exists = $plotter->existTag ('oval');

=cut

sub existTag {
  my $self = shift;
  my $tag = shift;
  my @items = $self->getCanvas()->find ('withtag', $tag);
  my $len = @items;
  return $len;
}


=item raiseAbove

Raise the objects with the first tag above the objects with the second
tag.

  $plotter->raiseAbove ('oval', 'square');

=cut

sub raiseAbove {
  my $self = shift;
  my $tag = shift;
  my $tag2 = shift;
  $self->getCanvas()->raise($tag, $tag2);
}


=item lowerBelow

Lowers the objects with the first tag below the objects with the
second tag.

  $plotter->lowerBelow ('oval', 'square');

=cut

sub lowerBelow {
  my $self = shift;
  my $tag = shift;
  my $tag2 = shift;
  $self->getCanvas()->lower($tag, $tag2);
}


=item drawTextVert

Draws text on the current canvas in the given (x, y) coordinates using
the current font, font size, and font Color. Returns the text item
number.  Adds a tag name if one is given.  Draws it vertically

  $plotter->drawTextVert (5,5, "hello");
  $id = $plotter->drawTextVert (5,5, "hello", 'text');

=cut

# must specify (x, y, text)
sub drawTextVert {
  my $self = shift;
  my $x = shift;
  my $y = shift;
  my $text = shift;
  my $font = $self->font();
  if ($self->usingWorld()) {
    $font =~ /\d+/;
    my $before = $`;
    my $num = $&;
    my $end = $';
    $num = ($num/10) / $self->worldToPixRatio();
    $num = s/\..+//;
    $font = $before . $num  . '0' . $end;
  }
  my $t = $self->getCanvas()->create('text', $self->toP($x, $y),
     -text => $text,
     -font => $font,
     -width => 1,
     -fill => $self->fontColor());
  if (@_) {
    my $tag = shift;
    $self->getCanvas()->addtag ($tag, 'withtag', $t);
  }
  return $t;
}


=item drawText

Draws text on the current canvas in the given (x, y) coordinates using
the current font, font size, and font Color. Returns the text item
number.  Adds a tag name if one is given.

  $plotter->drawText (5,5, "hello");
  $id = $plotter->drawText (5,5, "hello", 'text');

=cut

# must specify (x, y, text)
sub drawText {
  my $self = shift;
  my $x = shift;
  my $y = shift;
  my $text = shift;
  my $font = $self->font();
  if ($self->usingWorld()) {
    $font =~ /\d+/;
    my $before = $`;
    my $num = $&;
    my $end = $';
    $num = ($num/10) / $self->worldToPixRatio();
    $num = s/\..+//;
    $font = $before . $num  . '0' . $end;
  }
  my $t = $self->getCanvas()->create('text', $self->toP($x, $y),
     -text => $text,
     -font => $font,
     -fill => $self->fontColor());
  if (@_) {
    my $tag = shift;
    $self->getCanvas()->addtag ($tag, 'withtag', $t);
  }
  return $t;
}


=item drawTextFromLeft

Draws text on the current canvas in the given (x, y) coordinates using
the current font, font size, and font Color. Returns the text item
number.  Adds a tag name if one is given.

  $plotter->drawTextFromLeft (5,5, "hello");
  $id = $plotter->drawTextFromLeft (5,5, "hello", 'text');

=cut

# must specify (x, y, text)
sub drawTextFromLeft {
  my $self = shift;
  my $x = shift;
  my $y = shift;
  my $text = shift;
  my $font = $self->font();
  if ($self->usingWorld()) {
    $font =~ /\d+/;
    my $before = $`;
    my $num = $&;
    my $end = $';
    $num = ($num/10) / $self->worldToPixRatio();
    $num = s/\..+//;
    $font = $before . $num  . '0' . $end;
  }
  my $t = $self->getCanvas()->create('text', $self->toP($x, $y),
     -text => $text,
     -font => $font,
     -fill => $self->fontColor(),
     -anchor => 'w');
  if (@_) {
    my $tag = shift;
    $self->getCanvas()->addtag ($tag, 'withtag', $t);
  }
  return $t;
}


=item drawTextFromRight

Draws text on the current canvas in the given (x, y) coordinates using
the current font, font size, and font Color.  Returns the text item
number.  Adds a tag name if one is given.

  $plotter->drawTextFromRight (5,5, "hello");
  $id = $plotter->drawTextFromRight (5,5, "hello", 'text');

=cut

# must specify (x, y, text)
sub drawTextFromRight {
  my $self = shift;
  my $x = shift;
  my $y = shift;
  my $text = shift;
  my $font = $self->font();
  if ($self->usingWorld()) {
    $font =~ /\d+/;
    my $before = $`;
    my $num = $&;
    my $end = $';
    $num = ($num/10) / $self->worldToPixRatio();
    $num = s/\..+//;
    $font = $before . $num  . '0' . $end;
  }
  my $t = $self->getCanvas()->create('text', $self->toP($x, $y),
     -text => $text,
     -font => $font,
     -fill => $self->fontColor(),
     -anchor => 'e');
  if (@_) {
    my $tag = shift;
    $self->getCanvas()->addtag ($tag, 'withtag', $t);
  }
  return $t;
}


=item drawOval

Draws an oval on the current canvas in the given set of (x, y)
coordinates Returns the ovals item number.  Adds a tag name if one is
given.

  $plotter->drawOval (5,5, 10, 10);
  $id = $plotter->drawOval (5,5, 10, 10, 'oval');

=cut

# must specify (left, top, right, bottom)
sub drawOval {
  my $self = shift;
  my $oval = $self->getCanvas()->create('oval',
      $self->toP(shift, shift),
      $self->toP(shift, shift),
      -width => $self->penWidth(),
      -outline=>$self->drawColor()
  );
  if (@_) {
    my $tag = shift;
    $self->getCanvas()->addtag ($tag, 'withtag', $oval);
  }
  return $oval;
}


=item drawFillOval

Draws an oval on the current canvas in the given set of (x, y)
coordinates and fills it.  Returns the ovals item number.  Adds a tag
name if one is given.

  $plotter->drawFillOval (5,5, 10, 10);
  $id = $plotter->drawFillOval (5,5, 10, 10, 'oval');

=cut

# must specify (left, top, right, bottom)
sub drawFillOval {
  my $self = shift;
  my $oval = $self->getCanvas()->create('oval',
      $self->toP(shift, shift),
      $self->toP(shift, shift),
      -width => $self->penWidth(),
      -outline=>$self->drawColor(),
      -fill => $self->drawColor()
  );
  if (@_) {
    my $tag = shift;
    $self->getCanvas()->addtag ($tag, 'withtag', $oval);
  }
  return $oval;
}


=item drawLine

Draws a line on the current canvas in the given set of (x, y)
coordinates Returns the lines item number.  Adds a tag name if one is
given.

  $plotter->drawLine (5,5, 10, 10);
  $id = $plotter->drawLine (5,5, 10, 10, 'line');

=cut

# must specify (x, y, x2, y2)
sub drawLine {
  my $self = shift;
  my $line = $self->getCanvas()->create('line',
      $self->toP(shift, shift),
      $self->toP(shift, shift),
      -width=>$self->penWidth(),
      -fill =>$self->drawColor());
  if (@_) {
    my $tag = shift;
    $self->getCanvas()->addtag ($tag, 'withtag', $line);
  }
  return $line;
}


=item drawSmoothLine

Draws a smooth line on the current canvas through the given (x, y)
coordinates.  Gives the object the tag $tag if one is given

  $plotter->drawSmoothLine (5=>5, 10=>10, 15=>5, 20=>0);
  $id = $plotter->drawSmoothLine (5=>5, 10=>10, 15=>5, 20=>0, $tag);

=cut

sub drawSmoothLine {
  my $self = shift;
  my @points = @_;
  my $tag = pop (@points);
  if ($tag =~ /^\-?\d*\.?\d+$/) {
    push (@points, $tag);
    print "pushing it back on\n";
    undef $tag;
  }
  my $len = @points;
  for (my $i = 0; $i < $len; $i++) {
    if ($i =~ /[02468]$/) {
       $points[$i] = $self->toPx($points[$i]);
    } else {
       $points[$i] = $self->toPy($points[$i]);
    }
  }
  my $line = $self->getCanvas()->createLine(
      @points,
      -width=>$self->penWidth(),
      -fill =>$self->drawColor(),
      -joinstyle => 'round',
      -smooth => 1,
      -splinesteps => 10
  );

  if (defined $tag) {
    $self->getCanvas()->addtag ($tag, 'withtag', $line);
  }
  return $line;
}


=item drawBox

Draws a box on the current canvas in the given set of (x, y)
coordinates Returns the box item number.  Adds a tag name if one is
given.

  $plotter->drawBox (5,5, 10, 10);
  $id = $plotter->drawBox (5,5, 10, 10, 'box');

=cut

# must specify (x, y, x2, y2)
sub drawBox {
  my $self = shift;
  my $box = $self->getCanvas()->create('rectangle',
      $self->toP(shift, shift),
      $self->toP(shift, shift),
      -width=>$self->penWidth(),
      -fill =>$self->drawColor());
  if (@_) {
    my $tag = shift;
    $self->getCanvas()->addtag ($tag, 'withtag', $box);
  }
  return $box;
}


=item gamma

Sets the light intensity for the image.

  $g = $plotter->gamma();
  $plotter->gamma(3);

=cut

sub gamma {
  my $self = shift;
  if (@_) {
    my $p = $self->phot();
    $self->{GAMMA} = shift;
    if (defined $p) {
      $p->configure (-gamma => $self->{GAMMA});
    }
  }
  return $self->{GAMMA};
}



=item photoWorldSize

Sets and returns the current photos world sizes in arcseconds

  ($xs, $ys) = $plotter->photoWorldSize();
  $plotter->photoWorldSize(5,5);

=cut

sub photoWorldSize {
  my $self = shift;
  if (@_) {
    $self->{PHOTO_WORLD_SIZE_X} = shift;
    $self->{PHOTO_WORLD_SIZE_Y} = shift;
    $self->{W_RATIO_X} = undef;
  }
  return ($self->{PHOTO_WORLD_SIZE_X},$self->{PHOTO_WORLD_SIZE_Y});
}



=item photoFile

Sets and returns the current image file

  $img = $plotter->photoFile();
  $plotter->photoFile("file");

=cut

sub photoFile {
  my $self = shift;
  if (@_) {
    $self->{PHOTO_FILE} = shift;
  }
  return $self->{PHOTO_FILE};
}


=item origPhot

Sets and returns the original image

  $img = $plotter->origPhot();
  $plotter->origPhot($img);

=cut

sub origPhot {
  my $self = shift;
  if (@_) {
    $self->{ORIG_PHOT}->delete if (defined $self->{ORIG_PHOT});
    $self->{ORIG_PHOT} = shift;

    # need to reset the world ratio
    $self->{W_RATIO_X} = undef;
  }
  return $self->{ORIG_PHOT};
}

=item setImage

Sets the image stored in the file specified by photFile into memory.

  $plotter->setImage();

=cut

sub setImage {
  my $self = shift;

  my ($suffix, $source) = split(/\./, reverse $self->photoFile(),2);
  $suffix = reverse $suffix;
  $source = reverse $source;
  if ($suffix =~ /fits/i) {
    my $gif = $source . ".gif";
    system "fitsToGif ".$self->photoFile();
    $self->photoFile($gif);
    my $img = $self->getCanvas()->Photo( -file => $self->photoFile);
    $self->origPhot($img);
#    unlink $self->photoFile();
  } else {
    my $img = $self->getCanvas()->Photo( -file => $self->photoFile);
    $self->origPhot($img);
    if ($self->photoFile() =~ /dss/ || $self->photoFile() =~ /NoObs/) {
      return 0;
    }
  }
  return 1;
}



=item phot

Retrieves an image from the specified file.  Returns the image object

  $img = $plotter->phot();
  $plotter->phot();
  $plotter->phot(100, 100);

=cut

# must specify (width, height) to get
sub phot {
  my $self = shift;
  if (@_) {
    my $img;
    $self->{PHOT}->delete if defined $self->{POT};
    if (!defined $self->origPhot()) {
      $img = $self->getCanvas()->Photo( -file => $self->photoFile);
      $self->origPhot($img);
    } else {
      if (defined $self->phot()) {
        $self->phot()->delete;
      }
      $img = $self->origPhot();
    }
    my $tar = $self->getCanvas()->Photo( -gamma => $self->gamma());
    my ($pictx, $picty);
    $tar->copy($img, -zoom => $self->zoomNum(), $self->zoomNum());
    $self->{PHOT} = $tar;
  }
  return $self->{PHOT};
}


=item drawPhot

Draws a picture on the current canvas, centering it.  The picture is
can be changed by using the phot method.

  $plotter->drawPhot ();

=cut

# must specify ()
sub drawPhot {
  my $self = shift;
  my ($x, $y);
  if (defined $self->phot()) {
    $x = ($self->toPx($self->width())-$self->phot()->width)/2;
    $y = ($self->toPy($self->height())-$self->phot()->height)/2;
    $self->getCanvas()->create( 'image',$x,$y,
      '-anchor' => 'nw',
      '-image'  => $self->phot() );
  }
}

=item monitorXY

Monitor the X and Y coordinates of the cursor on the canvas.
This can be used to provide feedback to the user as to the
current cursor position.

Arguments are 2 scalar references. These references are updated
to contain the current value of the cursor position or
a value of 'undef' (a string) when the cursor is not present
in the plotting area.

If called without arguments, the bindings are removed.

=cut

sub monitorXY {
  my $self = shift;
  if (@_) {
    my ($xref, $yref) = @_;
    croak "Arguments must be scalar references"
      unless (ref($xref)eq 'SCALAR' && ref($yref) eq 'SCALAR');

    # Get the canvas
    my $canvas = $self->getCanvas;

    # Set up a binding for click
    # Call a separate sub for clarity rather than use a closure
    $canvas->Tk::bind("<Button-1>",
                      [ $self => '_XYcallback',
                        $canvas, Ev('x'), Ev('y'), $xref, $yref ]);

  } else {
    # Remove bindings
  }

}

# internal routine used by monitorXY
sub _XYcallback {
  my $self = shift;
  my ($canv, $x, $y, $xref, $yref) = @_;

  # Need to translate widget coordinates to canvas coordinates and
  # then to World coordinates
  ($$xref, $$yref) = $self->toW( $canv->canvasx($x), $canv->canvasy($y) );

  print "Coordinates: $$xref, $$yref ",
    $canv->canvasx($x)," ",$canv->canvasy($y),"\n";
}




=item zoomOut

Zooms the world to pixel ratio and the current image out.

  $plotter->zoomOut ();

=cut

sub zoomOut {
  my $self = shift;
  return if ($self->zoomNum()/2 < 1 );
  $self->zoomNum($self->zoomNum()/2);
  $self->phot($self->zoomNum(), $self->zoomNum());
  my ($x, $y) = $self->worldToPixRatio();
  $self->worldToPixRatio($x*2, $y*2);
}


=item zoomIn

Zooms the world to pixel ratio and the current image in.

  $plotter->zoomIn();

=cut

sub zoomIn {
  my $self = shift;
  $self->zoomNum($self->zoomNum()*2);
  $self->phot($self->zoomNum(), $self->zoomNum());
  my ($x, $y) = $self->worldToPixRatio();
  $self->worldToPixRatio($x/2, $y/2);
}


=item zoomNum

Returns the zoom factor for the picture

  $plotter->zoomNum(5);
  $num = $plotter->zoomNum();

=cut

sub zoomNum {
  my $self = shift;
  $self->{ZOOMNUM} = shift if (@_);
  return $self->{ZOOMNUM};
}

############################################################
#
#  Displays a Tk error window with the passed in string
#
#  Parameters:
#    $MW - a Tk MainWindow object
#    $text - the error message to be printed
#    $title - optionally add a title the tk window
#
#  Returns nothing
#
sub error {
  my $MW = shift;
  my $errWin = $MW->Toplevel(-borderwidth=>10);
  $errWin->title('Observation Log Error!');
  $errWin->resizable(0,0);
  $errWin->Button(
     -text         => 'Ok',
     -command      => sub{
       destroy $errWin;
  })->pack(-side=>'bottom');
  my $message = shift;
  $errWin->Label (
    -text => "\nError!\n\n   ".$message."   \n",
    -relief=>'sunken'
  )->pack(-side=>'bottom', pady => 10);
  $errWin->title(shift) if @_;
  $MW->update;
  $errWin->grab;
}

=back

=head1 AUTHOR

Casey Best (University of Victoria) with help from Tim Jenness.

=head1 COPYRIGHT

Copyright (C) 2012 Science and Technology Facilities Council.
Copyright 1998-2000 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.

=cut

1;
