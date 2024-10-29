package App::SourcePlot::Plotter::Tk;

=head1 NAME

App::SourcePlot::Plotter::Tk - Create a Tk canvas with easy-to-use method names

=head1 DESCRIPTION

This class provides methods to use a GUI canvas with ease.  The
commands will be generalized to ensure easy transfer between graphing
packages.

=cut

use 5.004;
use Carp;
use strict;

use Tk;

our $VERSION = '1.32';

=head1 METHODS

=head2 Constructor

=over 4

=item new

Create a new instance of Plotter::Tk object.  A new canvas will be
created with the specified coordinates.  This method will create a new
window for use by the canvas if one is not passed in.

    $plotter = App::SourcePlot::Plotter::Tk->new($MainWindow, $width, $height);

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $screen = shift;
    my $width = shift;
    my $height = shift;

    my $ET = bless {
        FONT => '-*-Helvetica-Medium-R-Normal--*-140-*-*-*-*-*-*',
        FONT_COLOR => 'Black',
        DRAW_COLOR => 'Black',
        PEN_WIDTH => 1,
    }, $class;

    $ET->{CANVAS} = $screen->Canvas(
        -background => "LightCyan3",
        -relief => 'raised',
        -width => $width,
        -height => $height,
        -cursor => 'top_left_arrow',
    );
    $ET->{CANVAS}->grid(-row => 0, -column => 0, -sticky => 'nsew');

    $ET->setWorldSize(0, 0, 1, 1);
    $ET->usingWorld(0);

    return $ET;
}

=back

=head2 Canvas functions

=over 4

=item getCanvas

Used specifically within this module, it allows the programmer to add
new features to this module with ease by accessing the Tk canvas.

    $can = $plotter->getCanvas();

=cut

sub getCanvas {
    my $self = shift;
    return $self->{CANVAS};
}

=back

=head2 Setup tools

=over 4

=item width

Returns the width of a canvas.

    $w = $plotter->width();

=cut

sub width {
    my $self = shift;
    return $self->getCanvas->width;
}

=item height

Returns the width of a canvas.

    $w = $plotter->height();

=cut

sub height {
    my $self = shift;
    return $self->getCanvas->height;
}

=item setBackground

Sets the background color

    $plotter->setBackground('black');

=cut

sub setBackground {
    my $self = shift;
    my $color = shift;
    $self->getCanvas()->configure(-background => $color);
}

=item setForeground

Sets the foreground color.

    $plotter->setForeground('black');

=cut

sub setForeground {
    my $self = shift;
    my $color = shift;
    $self->getCanvas()->configure(-foreground => $color);
}

=item font

Sets and returns the font currently being used.

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

Sets and returns the font color.

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

Sets and returns the font size.

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
        $self->font($before . $size . '0' . $end);
        $self->{FONTSIZE} = $size;
    }
    else {
        $self->{FONT_SIZE} = $num / 10 if (!defined $self->{FONT_SIZE});
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

Packs the canvas into a certain position within a main window
or frame.

    $plotter->pack(-side => 'left');

=cut

sub pack {
    my $self = shift;
    $self->getCanvas()->pack(@_);
}

=back

=head2 Conversion from world to pixels

=over 4

=item worldCenter

Sets the center of the world coordinates on the screen Best to set the
centre in pixels, and then the appropriate world coordinates can be
set at this point using worldAtZero.

    $plotter->worldCenter ($centerx, $centery);

=cut

sub worldCenter {
    my $self = shift;
    if (@_) {
        ($self->{W_CENT_X}, $self->{W_CENT_Y}) = $self->toP(shift, shift);
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
    return (0, 0);
}


=item worldToPixRatio

Sets the ratio between the world coordinates and pixels

    $plotter->worldToPixRatio($dx, $dy);

=cut

sub worldToPixRatio {
    my $self = shift;
    if (@_) {
        $self->{W_RATIO_X} = shift;
        $self->{W_RATIO_Y} = shift;
    }
    return ($self->{W_RATIO_X}, $self->{W_RATIO_Y});
}

=item usingWorld

Tells the module whether you wish to use the world coordinates when
specifying coordinates, or if you want to use pixels. Returns and sets
the value (1 for on, 0 for off).

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

    $plotter->setWorldSize($centerx, $centery, $dx, $dy);

=cut

sub setWorldSize {
    my $self = shift;
    $self->worldCenter(shift, shift);
    $self->worldToPixRatio(shift, shift);
}

=item toP

Converts coordinates into pixels.  The input coordinates are assumed
to be associated with the value in usingWorld.

    ($x, $y) = $plotter->toP($x1, $y1);
    ($x) = $plotter->toPx($x1);
    ($y) = $plotter->toPy($y1);

=cut

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
    }
    else {
        return (shift, shift);
    }
}

=item toPx

Converts passed in paramter into pixels.

=cut

sub toPx {
    my $self = shift;
    if ($self->usingWorld()) {
        my ($zx, $zy) = $self->worldAtZero();
        my $x = (shift) - $zx;
        my ($wx, $wy) = $self->worldCenter();
        my ($wratx, $wraty) = $self->worldToPixRatio();
        $x = $x / $wratx + $wx;
        return $x;
    }
    else {
        return (shift);
    }
}

=item toPy

Converts passed in paramter into pixels.

=cut

sub toPy {
    my $self = shift;
    if ($self->usingWorld()) {
        my ($zx, $zy) = $self->worldAtZero();
        my $y = (shift) - $zy;
        my ($wx, $wy) = $self->worldCenter();
        my ($wratx, $wraty) = $self->worldToPixRatio();
        $y = $y / $wraty + $wy;
        return $y;
    }
    else {
        return (shift);
    }
}

=item toW

Converts pixel coordinates into current system.  The output
coordinates are assumed to be associated with the value in usingWorld.

    ($x, $y) = $plotter->toW($x1, $y1);
    ($x) = $plotter->toWx($x1);
    ($y) = $plotter->toWy($y1);

=cut

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
        return ($x + $zx, $y + $zy);
    }
    else {
        return (shift, shift);
    }
}

=item toWx

Must specify (x).

=cut

sub toWx {
    my $self = shift;
    if ($self->usingWorld()) {
        my ($zx, $zy) = $self->worldAtZero();
        my $x = shift;
        my ($wx, $wy) = $self->worldCenter();
        my ($wratx, $wraty) = $self->worldToPixRatio();
        $x = ($x - $wx) * $wratx;
        return $x + $zx;
    }
    else {
        return (shift);
    }
}

=item toWy

Must specify (y).

=cut

sub toWy {
    my $self = shift;
    if ($self->usingWorld()) {
        my ($zx, $zy) = $self->worldAtZero();
        my $y = shift;
        my ($wx, $wy) = $self->worldCenter();
        my ($wratx, $wraty) = $self->worldToPixRatio();
        $y = ($y - $wy) * $wraty;
        return $y + $zy;
    }
    else {
        return (shift);
    }
}

=back

=head2 Drawing tools

=over 4

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

    $plotter->delete('oval');

=cut

sub delete {
    my $self = shift;
    my $tag = shift;
    $self->getCanvas()->delete($tag);
}

=item printCanvas

Prints the canvas to a printer

    $plotter->printCanvas('file', 'filename');
    $plotter->printCanvas('printer', '-PHello');

=cut

sub printCanvas {
    my $self = shift;
    my $choice = shift;
    my $option = shift;
    my $MW = shift;
    local (*LPR);
    if ($choice eq 'file') {
        if (! open(LPR, ">$option")) {
            error($MW, "Could not print to file:   \n   $option");
        }
    }
    else {
        if (! open(LPR, "| $option")) {
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

    $plotter->configureTag('oval', -fill => 'black');

=cut

sub configureTag {
    my $self = shift;
    my $tag = shift;
    my @con = @_;
    $self->getCanvas()->itemconfigure($tag, @con);
}

=item bindTag

Binds the items with the given tag.

    $plotter->bindTag('oval', '<Any-Enter>' => sub {print "hello"});

=cut

sub bindTag {
    my $self = shift;
    my $tag = shift;
    my @con = @_;
    $self->getCanvas()->bind($tag, @con);
}

=item existTag

Returns the number of items associated with that tag

    $exists = $plotter->existTag('oval');

=cut

sub existTag {
    my $self = shift;
    my $tag = shift;
    my @items = $self->getCanvas()->find('withtag', $tag);
    my $len = @items;
    return $len;
}

=item raiseAbove

Raise the objects with the first tag above the objects with the second
tag.

    $plotter->raiseAbove('oval', 'square');

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

    $plotter->lowerBelow('oval', 'square');

=cut

sub lowerBelow {
    my $self = shift;
    my $tag = shift;
    my $tag2 = shift;
    $self->getCanvas()->lower($tag, $tag2);
}

=item drawTextVert

Draws text on the canvas in the given (x, y) coordinates using
the current font, font size, and font Color. Returns the text item
number.  Adds a tag name if one is given.  Draws it vertically

    $plotter->drawTextVert(5, 5, "hello");
    $id = $plotter->drawTextVert(5, 5, "hello", 'text');

=cut

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
        $num = ($num / 10) / $self->worldToPixRatio();
        $num = s/\..+//;
        $font = $before . $num . '0' . $end;
    }
    my $t = $self->getCanvas()->create(
        'text',
        $self->toP($x, $y),
        -text => $text,
        -font => $font,
        -width => 1,
        -fill => $self->fontColor()
    );
    if (@_) {
        my $tag = shift;
        $self->getCanvas()->addtag($tag, 'withtag', $t);
    }
    return $t;
}


=item drawText

Draws text on the canvas in the given (x, y) coordinates using
the current font, font size, and font Color. Returns the text item
number.  Adds a tag name if one is given.

    $plotter->drawText(5, 5, "hello");
    $id = $plotter->drawText(5, 5, "hello", 'text');

=cut

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
        $num = ($num / 10) / $self->worldToPixRatio();
        $num = s/\..+//;
        $font = $before . $num . '0' . $end;
    }
    my $t = $self->getCanvas()->create(
        'text',
        $self->toP($x, $y),
        -text => $text,
        -font => $font,
        -fill => $self->fontColor()
    );
    if (@_) {
        my $tag = shift;
        $self->getCanvas()->addtag($tag, 'withtag', $t);
    }
    return $t;
}

=item drawTextFromLeft

Draws text on the canvas in the given (x, y) coordinates using
the current font, font size, and font Color. Returns the text item
number.  Adds a tag name if one is given.

    $plotter->drawTextFromLeft(5, 5, "hello");
    $id = $plotter->drawTextFromLeft(5, 5, "hello", 'text');

=cut

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
        $num = ($num / 10) / $self->worldToPixRatio();
        $num = s/\..+//;
        $font = $before . $num . '0' . $end;
    }
    my $t = $self->getCanvas()->create(
        'text',
        $self->toP($x, $y),
        -text => $text,
        -font => $font,
        -fill => $self->fontColor(),
        -anchor => 'w'
    );
    if (@_) {
        my $tag = shift;
        $self->getCanvas()->addtag($tag, 'withtag', $t);
    }
    return $t;
}

=item drawTextFromRight

Draws text on the canvas in the given (x, y) coordinates using
the current font, font size, and font Color.  Returns the text item
number.  Adds a tag name if one is given.

    $plotter->drawTextFromRight(5, 5, "hello");
    $id = $plotter->drawTextFromRight(5, 5, "hello", 'text');

=cut

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
        $num = ($num / 10) / $self->worldToPixRatio();
        $num = s/\..+//;
        $font = $before . $num . '0' . $end;
    }
    my $t = $self->getCanvas()->create(
        'text',
        $self->toP($x, $y),
        -text => $text,
        -font => $font,
        -fill => $self->fontColor(),
        -anchor => 'e'
    );
    if (@_) {
        my $tag = shift;
        $self->getCanvas()->addtag($tag, 'withtag', $t);
    }
    return $t;
}

=item drawOval

Draws an oval on the canvas in the given set of (x, y)
coordinates Returns the ovals item number.  Adds a tag name if one is
given.

    $plotter->drawOval(5, 5, 10, 10);
    $id = $plotter->drawOval(5, 5, 10, 10, 'oval');

=cut

sub drawOval {
    my $self = shift;
    my $oval = $self->getCanvas()->create(
        'oval',
        $self->toP(shift, shift),
        $self->toP(shift, shift),
        -width => $self->penWidth(),
        -outline => $self->drawColor()
    );
    if (@_) {
        my $tag = shift;
        $self->getCanvas()->addtag($tag, 'withtag', $oval);
    }
    return $oval;
}

=item drawFillOval

Draws an oval on the canvas in the given set of (x, y)
coordinates and fills it.  Returns the ovals item number.  Adds a tag
name if one is given.

    $plotter->drawFillOval(5, 5, 10, 10);
    $id = $plotter->drawFillOval(5, 5, 10, 10, 'oval');

=cut

sub drawFillOval {
    my $self = shift;
    my $oval = $self->getCanvas()->create(
        'oval',
        $self->toP(shift, shift),
        $self->toP(shift, shift),
        -width => $self->penWidth(),
        -outline => $self->drawColor(),
        -fill => $self->drawColor()
    );
    if (@_) {
        my $tag = shift;
        $self->getCanvas()->addtag($tag, 'withtag', $oval);
    }
    return $oval;
}

=item drawLine

Draws a line on the canvas in the given set of (x, y)
coordinates Returns the lines item number.  Adds a tag name if one is
given.

    $plotter->drawLine(5, 5, 10, 10);
    $id = $plotter->drawLine(5, 5, 10, 10, 'line');

=cut

sub drawLine {
    my $self = shift;
    my $line = $self->getCanvas()->create(
        'line',
        $self->toP(shift, shift),
        $self->toP(shift, shift),
        -width => $self->penWidth(),
        -fill => $self->drawColor()
    );
    if (@_) {
        my $tag = shift;
        $self->getCanvas()->addtag($tag, 'withtag', $line);
    }
    return $line;
}


=item drawSmoothLine

Draws a smooth line on the canvas through the given (x, y)
coordinates.  Gives the object the tag $tag if one is given

    $plotter->drawSmoothLine(5 => 5, 10 => 10, 15 => 5, 20 => 0);
    $id = $plotter->drawSmoothLine(5 => 5, 10 => 10, 15 => 5, 20 => 0, $tag);

=cut

sub drawSmoothLine {
    my $self = shift;
    my @points = @_;
    my $tag = pop(@points);
    if ($tag =~ /^\-?\d*\.?\d+$/) {
        push(@points, $tag);
        print "pushing it back on\n";
        undef $tag;
    }
    my $len = @points;
    for (my $i = 0; $i < $len; $i ++) {
        if ($i =~ /[02468]$/) {
            $points[$i] = $self->toPx($points[$i]);
        }
        else {
            $points[$i] = $self->toPy($points[$i]);
        }
    }
    my $line = $self->getCanvas()->createLine(
        @points,
        -width => $self->penWidth(),
        -fill => $self->drawColor(),
        -joinstyle => 'round',
        -smooth => 1,
        -splinesteps => 10
    );

    if (defined $tag) {
        $self->getCanvas()->addtag($tag, 'withtag', $line);
    }
    return $line;
}

=item drawBox

Draws a box on the canvas in the given set of (x, y)
coordinates Returns the box item number.  Adds a tag name if one is
given.

    $plotter->drawBox(5, 5, 10, 10);
    $id = $plotter->drawBox(5, 5, 10, 10, 'box');

=cut

sub drawBox {
    my $self = shift;
    my $box = $self->getCanvas()->create(
        'rectangle',
        $self->toP(shift, shift),
        $self->toP(shift, shift),
        -width => $self->penWidth(),
        -fill => $self->drawColor()
    );
    if (@_) {
        my $tag = shift;
        $self->getCanvas()->addtag($tag, 'withtag', $box);
    }
    return $box;
}

1;

__END__

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
