package Ace::Graphics::Glyph;

use strict;
use GD;

# simple glyph class
# args:  -feature => $feature_object
# args:  -factory => $factory_object
sub new {
  my $class = shift;
  my %arg = @_;
  my $feature = $arg{-feature};
  my ($start,$end) = ($feature->start,$feature->end);
  ($start,$end) = ($end,$start) if $start > $end;
  return bless {
		@_,
		top   => 0,
		left  => 0,
		right => 0,
		start => $start,
		end   => $end
	       },$class;
}

# delegates
# any of these can be overridden safely
sub factory   {  shift->{-factory}            }
sub feature   {  shift->{-feature}            }
sub fgcolor   {  shift->factory->fgcolor      }
sub bgcolor   {  shift->factory->bgcolor   }
sub fontcolor {  shift->factory->fontcolor      }
sub fillcolor {  shift->factory->fillcolor }
sub scale     {  shift->factory->scale     }
sub width     {  shift->factory->width     }
sub font      {  shift->factory->font      }
sub option    {  shift->factory->option(shift) }
sub color     {
  my $self    = shift;
  my $factory = $self->factory;
  my $color   = $factory->option(shift) or return $self->fgcolor;
  $factory->translate($color);
}

sub start     { shift->{start}                 }
sub end       { shift->{end}                   }
sub offset    { shift->factory->offset      }
sub length    { shift->factory->length      }

# this is a very important routine that dictates the
# height of the bounding box.  We start with the height
# dictated by the factory, and then adjust if needed
sub height   {
  my $self = shift;
  $self->{cache_height} = $self->calculate_height unless exists $self->{cache_height};
  return $self->{cache_height};
}

sub calculate_height {
  my $self = shift;
  my $val = $self->factory->height;
  $val += $self->labelheight if $self->option('label');
  $val;
}

# change our offset
sub move {
  my $self = shift;
  my ($dx,$dy) = @_;
  $self->{left} += $dx;
  $self->{top}  += $dy;
}

# positions, in pixel coordinates
sub top    { shift->{top}                 }
sub bottom { my $s = shift; $s->top + $s->height   }
sub left {
  my $self = shift;
  $self->{cache_left} = $self->calculate_left unless exists $self->{cache_left};
  return $self->{left} + $self->{cache_left};
}
sub right {
  my $self = shift;
  $self->{cache_right} = $self->calculate_right unless exists $self->{cache_right};
  return $self->{left} + $self->{cache_right};
}

sub calculate_left {
  my $self = shift;
  my $val = $self->{left} + $self->map_pt($self->{start} - 1);
  $val > 0 ? $val : 0;
}

sub calculate_right {
  my $self = shift;
  my $val = $self->{left} + $self->map_pt($self->{end} - 1);
  $val = 0 if $val < 0;
  $val = $self->width if $val > $self->width;
  if ($self->option('label') && (my $label = $self->label)) {
    my $left = $self->left;
    my $label_width = $self->font->width * CORE::length $label;
    my $label_end   = $left + $label_width;
    $val = $label_end if $label_end > $val;
  }
  $val;
}

sub map_pt {
  my $self = shift;
  my $point = shift;
  $point -= $self->offset;
  my $val = $self->{left} + $self->scale * $point;
  my $right = $self->{left} + $self->width;
  $val = -1 if $val < 0;
  $val = $self->width if $right && $val > $right;
  return int $val;
}

sub labelheight {
  my $self = shift;
  return $self->{labelheight} ||= $self->font->height;
}

sub label {
  my $f = (my $self = shift)->feature;
  if (ref (my $code = $self->option('label')) eq 'CODE') {
    return $code->($f);
  }
  my $info = eval {$f->info};
  return $info if $info;
  return $f->seqname if $f->can('seqname');
  return $f->primary_tag;
}

# return array containing the left,top,right,bottom
sub box {
  my $self = shift;
  return ($self->left,$self->top,$self->right,$self->bottom);
}

# these are the sequence boundaries, exclusive of labels and doodads
sub calculate_boundaries {
  my $self = shift;
  my ($left,$top) = @_;

  my $x1 = $left + $self->map_pt($self->{start} - 1);
  $x1 = 0 if $x1 < 0;

  my $x2 = $left + $self->map_pt($self->{end} - 1);
  $x2 = 0 if $x2 < 0;

  my $y1 = $top + $self->{top};
  $y1 += $self->labelheight if $self->option('label');
  my $y2 = $y1 + $self->factory->height;

  $x2 = $x1 if $x2-$x1 < 1;
  $y2 = $y1 if $y2-$y1 < 1;

  return ($x1,$y1,$x2,$y2);
}

sub filled_box {
  my $self = shift;
  my $gd = shift;
  my ($x1,$y1,$x2,$y2,$color) = @_;

  my $fc = defined($color) ? $color : $self->fillcolor;

  my $linewidth = $self->option('linewidth') || 1;
  $gd->filledRectangle($x1,$y1,$x2,$y2,$fc);
  $gd->rectangle($x1,$y1,$x2,$y2,$self->fgcolor);

  # and fill it
#  $self->fill($gd,$x1,$y1,$x2,$y2);

  # if the left end is off the end, then cover over
  # the leftmost line
  my ($width) = $gd->getBounds;
  $gd->line($x1,$y1,$x1,$y2,$fc)
    if $x1 < 0;

  $gd->line($x2,$y1,$x2,$y2,$fc)
    if $x2 > $width;
}

sub filled_oval {
  my $self = shift;
  my $gd = shift;
  my ($x1,$y1,$x2,$y2) = @_;
  my $cx = ($x1+$x2)/2;
  my $cy = ($y1+$y2)/2;

  my $linewidth = $self->option('linewidth') || 1;
  if ($linewidth > 1) {
    my $pen = $self->make_pen($linewidth);
    # draw a box
    $gd->setBrush($pen);
    $gd->arc($cx,$cy,$x2-$x1,$y2-$y1,0,360,gdBrushed);
  } else {
    $gd->arc($cx,$cy,$x2-$x1,$y2-$y1,0,360,$self->fgcolor);
  }

  # and fill it
  $gd->fill($cx,$cy,$self->fillcolor);
}

# directional arrow
sub filled_arrow {
  my $self = shift;
  my $gd  = shift;
  my $orientation = shift;

  my ($x1,$y1,$x2,$y2) = @_;
  my ($width) = $gd->getBounds;
  my $indent = ($y2-$y1);

  if ($x2 - $x1 < $indent) {
    $indent = ($x2-$x1)/2;
  }

  return $self->filled_box($gd,@_)
    if ($orientation == 0)
      or ($x1 < 0 && $orientation < 0)
	or ($x2 > $width && $orientation > 0)
	  or ($x2 - $x1 < $indent);

  my $h = ($y2-$y1)/4;  # half height of terminal bar
  my $c = ($y2+$y1)/2;  # vertical center
  my $fg = $self->fgcolor;
  my $fc = $self->fillcolor;
  if ($orientation > 0) {
    $gd->line($x1,$y1,$x2-$indent,$y1,$fg);
    $gd->line($x2-$indent,$y1,$x2,$c,$fg);
    $gd->line($x2,$c,$x2-$indent,$y2,$fg);
    $gd->line($x2-$indent,$y2,$x1,$y2,$fg);
    $gd->line($x1,$y2,$x1,$y1,$fg);
    $gd->line($x2,$c-$h,$x2,$c+$h+1,$fg);
    $gd->fillToBorder($x1+1,$c,$fg,$fc);
  } else {
    $gd->line($x1,$c,$x1+$indent+1,$y1,$fg);
    $gd->line($x1+$indent+1,$y1,$x2,$y1,$fg);
    $gd->line($x2,$y1,$x2,$y2,$fg);
    $gd->line($x2,$y2,$x1+$indent+1,$y2,$fg);
    $gd->line($x1+$indent+1,$y2,$x1,$c,$fg);
    $gd->line($x1,$c-$h,$x1,$c+$h+1,$fg);
    $gd->fillToBorder($x2-1,$c,$fg,$fc);
  }
}

sub fill {
  my $self = shift;
  my $gd   = shift;
  my ($x1,$y1,$x2,$y2) = @_;
  if ( ($x2-$x1) >= 2 && ($y2-$y1) >= 2 ) {
    $gd->fill($x1+1,$y1+1,$self->fillcolor);
  }
}

# draw the thing onto a canvas
# this definitely gets overridden
sub draw {
  my $self = shift;
  my $gd   = shift;
  my ($left,$top) = @_;
  my ($x1,$y1,$x2,$y2) = $self->calculate_boundaries($left,$top);

  # for nice thin lines
  $x2 = $x1 if $x2-$x1 < 1;

  if ($self->option('strand_arrow')) {
    my $orientation = $self->feature->strand;
    $self->filled_arrow($gd,$orientation,$x1,$y1,$x2,$y2);
  } else {
    $self->filled_box($gd,$x1,$y1,$x2,$y2);
  }

  # add a label if requested
  $self->draw_label($gd,@_) if $self->option('label');
}

sub draw_label {
  my $self = shift;
  my ($gd,$left,$top) = @_;
  my $label = $self->label or return;
  $gd->string($self->font,$left + $self->left,$top + $self->top,$label,$self->fontcolor);
}

1;

=head1 NAME

Ace::Graphics::Glyph - Base class for Ace::Graphics::Glyph objects

=head1 SYNOPSIS

See L<Ace::Graphics::Panel>.

=head1 DESCRIPTION

Ace::Graphics::Glyph is the base class for all glyph objects.  Each
glyph is a wrapper around an Ace::Sequence::Feature object, knows how
to render itself on an Ace::Graphics::Panel, and has a variety of
configuration variables.

End developers will not ordinarily work directly with
Ace::Graphics::Glyph, but may want to subclass it for customized
displays.

=head1 METHODS

This section describes the class and object methods for
Ace::Graphics::Glyph.

=head2 CONSTRUCTORS

Ace::Graphics::Glyph objects are constructed automatically by an
Ace::Graphics::GlyphFactory, and are not usually created by
end-developer code.

=over 4

=item $glyph = Ace::Graphics::Glyph->new(-feature=>$feature,-factory=>$factory)

Given a sequence feature, creates an Ace::Graphics::Glyph object to
display it.  The -feature argument points to the
Ace::Sequence::Feature object to display.  -factory indicates an
Ace::Graphics::GlyphFactory object from which the glyph will fetch all
its run-time configuration information.

A standard set of options are recognized.  See L<OPTIONS>.

=back

=head2 OBJECT METHODS

Once a glyph is created, it responds to a large number of methods.  In
this section, these methods are grouped into related categories.

Retrieving glyph context:

=over 4

=item $factory = $glyph->factory

Get the Ace::Graphics::GlyphFactory associated with this object.  This
cannot be changed once it is set.

=item $feature = $glyph->feature

Get the sequence feature associated with this object.  This cannot be
changed once it is set.

=back

Retrieving glyph options:

=over 4

=item $fgcolor = $glyph->fgcolor

=item $bgcolor = $glyph->bgcolor

=item $fontcolor = $glyph->fontcolor

=item $fillcolor = $glyph->fillcolor

These methods return the configured foreground, background, font and
fill colors for the glyph in the form of a GD::Image color index.

=item $width = $glyph->width

Return the maximum width allowed for the glyph.  Most glyphs will be
smaller than this.

=item $font = $glyph->font

Return the font for the glyph.

=item $option = $glyph->option($option)

Return the value of the indicated option.

=item $index = $glyph->color($color)

Given a symbolic or #RRGGBB-form color name, returns its GD index.

=back


Retrieving information about the sequence:

=over 4

=item $start = $glyph->start

=item $end   = $glyph->end

These methods return the start and end of the glyph in base pair
units.

=item $offset = $glyph->offset

Returns the offset of the segment (the base pair at the far left of
the image).

=item $length = $glyph->length

Returns the length of the sequence segment.

=back


Retrieving formatting information:

=over 4

=item $top = $glyph->top

=item $left = $glyph->left

=item $bottom = $glyph->bottom

=item $right = $glyph->right

These methods return the top, left, bottom and right of the glyph in
pixel coordinates.

=item $height = $glyph->height

Returns the height of the glyph.  This may be somewhat larger or
smaller than the height suggested by the GlyphFactory, depending on
the type of the glyph.

=item $scale = $glyph->scale

Get the scale for the glyph in pixels/bp.

=item $height = $glyph->labelheight

Return the height of the label, if any.

=item $label = $glyph->label

Return a human-readable label for the glyph.

=back

These methods are called by Ace::Graphics::Track during the layout
process:

=over 4

=item $glyph->move($dx,$dy)

Move the glyph in pixel coordinates by the indicated delta-x and
delta-y values.

=item ($x1,$y1,$x2,$y2) = $glyph->box

Return the current position of the glyph.

=back

These methods are intended to be overridden in subclasses:

=over 4

=item $glyph->calculate_height

Calculate the height of the glyph.

=item $glyph->calculate_left

Calculate the left side of the glyph.

=item $glyph->calculate_right

Calculate the right side of the glyph.

=item $glyph->draw($gd,$left,$top)

Optionally offset the glyph by the indicated amount and draw it onto
the GD::Image object.


=item $glyph->draw_label($gd,$left,$top)

Draw the label for the glyph onto the provided GD::Image object,
optionally offsetting by the amounts indicated in $left and $right.

=back

These methods are useful utility routines:

=over 4

=item $pixels = $glyph->map_pt($bases);

Map the indicated base position, given in base pair units, into
pixels, using the current scale and glyph position.

=item $glyph->filled_box($gd,$x1,$y1,$x2,$y2)

Draw a filled rectangle with the appropriate foreground and fill
colors, and pen width onto the GD::Image object given by $gd, using
the provided rectangle coordinates.

=item $glyph->filled_oval($gd,$x1,$y1,$x2,$y2)

As above, but draws an oval inscribed on the rectangle.

=back

=head2 OPTIONS

The following options are standard among all Glyphs.  See individual
glyph pages for more options.

  Option      Description               Default
  ------      -----------               -------

  -fgcolor    Foreground color		black

  -outlinecolor				black
	      Synonym for -fgcolor

  -bgcolor    Background color          white

  -fillcolor  Interior color of filled  turquoise
	      images

  -linewidth  Width of lines drawn by	1
		    glyph

  -height     Height of glyph		10

  -font       Glyph font		gdSmallFont

  -label      Whether to draw a label	false

You may pass an anonymous subroutine to -label, in which case the
subroutine will be invoked with the feature as its single argument.
The subroutine must return a string to render as the label.

=head1 SUBCLASSING Ace::Graphics::Glyph

By convention, subclasses are all lower-case.  Begin each subclass
with a preamble like this one:

 package Ace::Graphics::Glyph::crossbox;

 use strict;
 use vars '@ISA';
 @ISA = 'Ace::Graphics::Glyph';

Then override the methods you need to.  Typically, just the draw()
method will need to be overridden.  However, if you need additional
room in the glyph, you may override calculate_height(),
calculate_left() and calculate_right().  Do not directly override
height(), left() and right(), as their purpose is to cache the values
returned by their calculating cousins in order to avoid time-consuming
recalculation.

A simple draw() method looks like this:

 sub draw {
  my $self = shift;
  $self->SUPER::draw(@_);
  my $gd = shift;

  # and draw a cross through the box
  my ($x1,$y1,$x2,$y2) = $self->calculate_boundaries(@_);
  my $fg = $self->fgcolor;
  $gd->line($x1,$y1,$x2,$y2,$fg);
  $gd->line($x1,$y2,$x2,$y1,$fg);
 }

This subclass draws a simple box with two lines criss-crossed through
it.  We first call our inherited draw() method to generate the filled
box and label.  We then call calculate_boundaries() to return the
coordinates of the glyph, disregarding any extra space taken by
labels.  We call fgcolor() to return the desired foreground color, and
then call $gd->line() twice to generate the criss-cross.

For more complex draw() methods, see Ace::Graphics::Glyph::transcript
and Ace::Graphics::Glyph::segments.

=head1 BUGS

Please report them.

=head1 SEE ALSO

L<Ace::Sequence>, L<Ace::Sequence::Feature>, L<Ace::Graphics::Panel>,
L<Ace::Graphics::Track>, L<Ace::Graphics::Glyph::anchored_arrow>,
L<Ace::Graphics::Glyph::arrow>,
L<Ace::Graphics::Glyph::box>,
L<Ace::Graphics::Glyph::primers>,
L<Ace::Graphics::Glyph::segments>,
L<Ace::Graphics::Glyph::toomany>,
L<Ace::Graphics::Glyph::transcript>,

=head1 AUTHOR

Lincoln Stein <lstein@cshl.org>.

Copyright (c) 2001 Cold Spring Harbor Laboratory

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut
