package Ace::Graphics::Panel;
# This embodies the logic for drawing multiple tracks.

use Ace::Graphics::Track;
use GD;
use Carp 'croak';
use strict;
use constant KEYLABELFONT => gdSmallFont;
use constant KEYSPACING   => 10; # extra space between key columns
use constant KEYPADTOP    => 5;  # extra padding before the key starts
use constant KEYCOLOR     => 'cornsilk';

*push_track = \&add_track;

# package global
my %COLORS;

# Create a new panel of a given width and height, and add lists of features
# one by one
sub new {
  my $class = shift;
  my %options = @_;

  $class->read_colors() unless %COLORS;

  my $length = $options{-length} || 0;
  my $offset = $options{-offset} || 0;
  my $spacing = $options{-spacing} || 5;
  my $keycolor = $options{-keycolor} || KEYCOLOR;
  my $keyspacing = $options{-keyspacing} || KEYSPACING;

  $length   ||= $options{-segment}->length  if $options{-segment};
  $offset   ||= $options{-segment}->start-1 if $options{-segment};

  return bless {
		tracks => [],
		width  => $options{-width} || 600,
		pad_top    => $options{-pad_top}||0,
		pad_bottom => $options{-pad_bottom}||0,
		pad_left   => $options{-pad_left}||0,
		pad_right  => $options{-pad_right}||0,
		length => $length,
		offset => $offset,
		height => 0, # AUTO
		spacing => $spacing,
		keycolor => $keycolor,
		keyspacing => $keyspacing,
	       },$class;
}

sub width {
  my $self = shift;
  my $d = $self->{width};
  $self->{width} = shift if @_;
  $d + $self->pad_left + $self->pad_right;
}

sub spacing {
  my $self = shift;
  my $d = $self->{spacing};
  $self->{spacing} = shift if @_;
  $d;
}

sub length {
  my $self = shift;
  my $d = $self->{length};
  if (@_) {
    my $l = shift;
    $l = $l->length if ref($l) && $l->can('length');
    $self->{length} = $l;
  }
  $d;
}

sub pad_top {
  my $self = shift;
  my $d = $self->{pad_top};
  $self->{pad_top} = shift if @_;
  $d || 0;
}

sub pad_bottom {
  my $self = shift;
  my $d = $self->{pad_bottom};
  $self->{pad_bottom} = shift if @_;
  $d || 0;
}

sub pad_left {
  my $self = shift;
  my $d = $self->{pad_left};
  $self->{pad_left} = shift if @_;
  $d || 0;
}

sub pad_right {
  my $self = shift;
  my $d = $self->{pad_right};
  $self->{pad_right} = shift if @_;
  $d || 0;
}

sub add_track {
  my $self = shift;

  # due to indecision, we accept features
  # and/or glyph types in the first two arguments
  my ($features,$glyph_name) = ([],'generic');
  while ( $_[0] !~ /^-/) {
    my $arg = shift;
    $features   = $arg and next if ref($arg);
    $glyph_name = $arg and next unless ref($arg);
  }

  $self->_add_track($glyph_name,$features,+1,@_);
}

sub unshift_track {
  my $self = shift;
  # due to indecision, we accept features
  # and/or glyph types in the first two arguments
  my ($features,$glyph_name) = ([],'generic');
  while ( (my $arg = shift) !~ /^-/) {
    $features   = $arg and next if ref($arg);
    $glyph_name = $arg and next unless ref($arg);
  }

  $self->_add_track($glyph_name,$features,-1,@_);
}

sub _add_track {
  my $self = shift;
  my ($glyph_type,$features,$direction,@options) = @_;

  unshift @options,'-offset' => $self->{offset} if defined $self->{offset};
  unshift @options,'-length' => $self->{length} if defined $self->{length};

  $features = [$features] unless ref $features eq 'ARRAY';
  my $track  = Ace::Graphics::Track->new($glyph_type,$features,@options);
  $track->set_scale(abs($self->length),$self->{width});
  $track->panel($self);
  if ($direction >= 0) {
    push @{$self->{tracks}},$track;
  } else {
    unshift @{$self->{tracks}},$track;
  }

  return $track;
}

sub height {
  my $self = shift;
  my $spacing    = $self->spacing;
  my $key_height = $self->format_key;
  my $height = 0;
  $height += $_->height + $spacing foreach @{$self->{tracks}};
  $height + $key_height + $self->pad_top + $self->pad_bottom;
}

sub gd {
  my $self = shift;

  return $self->{gd} if $self->{gd};

  my $width  = $self->width;
  my $height = $self->height;
  my $gd = GD::Image->new($width,$height);
  my %translation_table;
  for my $name ('white','black',keys %COLORS) {
    my $idx = $gd->colorAllocate(@{$COLORS{$name}});
    $translation_table{$name} = $idx;
  }

  $self->{translations} = \%translation_table;
  $self->{gd}                = $gd;
  my $offset = 0;
  my $pl = $self->pad_left;
  my $pt = $self->pad_top;

  for my $track (@{$self->{tracks}}) {
    $track->draw($gd,$pl,$offset+$pt);
    $offset += $track->height + $self->spacing;
  }

  $self->draw_key($gd,$pl,$offset);
  return $self->{gd} = $gd;
}

sub draw_key {
  my $self = shift;
  my ($gd,$left,$top) = @_;
  my $key_glyphs = $self->{key_glyphs} or return;

  my $color = $self->translate($self->{keycolor});
  $gd->filledRectangle($left,$top,$self->width,$self->height,$color);
  $gd->string(KEYLABELFONT,$left,KEYPADTOP+$top,"KEY:",1);
  $top += KEYLABELFONT->height + KEYPADTOP;

  $_->draw($gd,$left,$top) foreach @$key_glyphs;
}

# Format the key section, and return its height
sub format_key {
  my $self = shift;

  return $self->{key_height} if defined $self->{key_height};

  my ($height,$width) = (0,0);
  my %tracks;
  my @glyphs;

  # determine how many glyphs become part of the key
  # and their max size
  for my $track (@{$self->{tracks}}) {
    next unless $track->option('key');
    my $glyph = $track->keyglyph;
    $tracks{$track} = $glyph;
    my ($h,$w) = ($glyph->height,
		  $glyph->right-$glyph->left);
    $height = $h if $h > $height;
    $width  = $w if $w > $width;
    push @glyphs,$glyph;
  }

  $width += $self->{keyspacing};

  # no key glyphs, no key
  return $self->{key_height} = 0 unless @glyphs;

  # now height and width hold the largest glyph, and $glyph_count
  # contains the number of glyphs.  We will format them into a
  # box that is roughly 3 height/4 width (golden mean)
  my $rows = 0;
  my $cols = 0;
  while (++$rows) {
    $cols = @glyphs / $rows;
    $cols = int ($cols+1) if $cols =~ /\./;  # round upward for fractions
    my $total_width  = $cols * $width;
    my $total_height = $rows * $width;
    last if $total_width <= $self->width;
  }

  # move glyphs into row-major format
  my $spacing = $self->spacing;
  my $i = 0;
  for (my $c = 0; $c < $cols; $c++) {
    for (my $r = 0; $r < $rows; $r++) {
      my $x = $c * ($width  + $spacing);
      my $y = $r * ($height + $spacing);
      next unless defined $glyphs[$i];
      $glyphs[$i]->move($x,$y);
      $i++;
    }
  }

  $self->{key_glyphs} = \@glyphs;     # remember our key glyphs
  # remember our key height
  return $self->{key_height} = ($height+$spacing) * $rows + KEYLABELFONT->height +KEYPADTOP;
}

# reverse of translate(); given index, return rgb triplet
sub rgb {
  my $self = shift;
  my $idx  = shift;
  my $gd = $self->{gd} or return;
  return $gd->rgb($idx);
}

sub translate {
  my $self = shift;

  if (@_ == 3) { # rgb triplet
    my $gd = $self->gd or return 1;
    return $gd->colorClosest(@_);
  }

  # otherwise...
  my $color = shift;
  if ($color =~ /^\#([0-9A-F]{2})([0-9A-F]{2})([0-9A-F]{2})$/i) {
    my $gd = $self->gd or return 1;
    my ($r,$g,$b) = (hex($1),hex($2),hex($3));
    return $gd->colorClosest($r,$g,$b);
  } else {
    my $table = $self->{translations} or return $self->fgcolor;
    return $table->{$color} || 1;
  }
}

sub set_pen {
  my $self = shift;
  my ($linewidth,$color) = @_;
  return $self->{pens}{$linewidth} if $self->{pens}{$linewidth};

  my $pen = $self->{pens}{$linewidth} = GD::Image->new($linewidth,$linewidth);
  my @rgb = $self->rgb($color);
  my $bg = $pen->colorAllocate(255,255,255);
  my $fg = $pen->colorAllocate(@rgb);
  $pen->fill(0,0,$fg);
  $self->{gd}->setBrush($pen);
}

sub png {
  my $gd = shift->gd;
  $gd->png;
}

sub boxes {
  my $self = shift;
  my @boxes;
  my $offset = 0;
  my $pl = $self->pad_left;
  my $pt = $self->pad_top;
  for my $track (@{$self->{tracks}}) {
    my $boxes = $track->boxes($pl,$offset+$pt);
    push @boxes,@$boxes;
    $offset += $track->height + $self->spacing;
  }
  return wantarray ? @boxes : \@boxes;
}

sub read_colors {
  my $class = shift;
  while (<DATA>) {
    chomp;
    last if /^__END__/;
    my ($name,$r,$g,$b) = split /\s+/;
    $COLORS{$name} = [hex $r,hex $g,hex $b];
  }
}

sub color_names {
    my $class = shift;
    $class->read_colors unless %COLORS;
    return wantarray ? keys %COLORS : [keys %COLORS];
}


1;

__DATA__
white                FF           FF            FF
black                00           00            00
aliceblue            F0           F8            FF
antiquewhite         FA           EB            D7
aqua                 00           FF            FF
aquamarine           7F           FF            D4
azure                F0           FF            FF
beige                F5           F5            DC
bisque               FF           E4            C4
blanchedalmond       FF           EB            CD
blue                 00           00            FF
blueviolet           8A           2B            E2
brown                A5           2A            2A
burlywood            DE           B8            87
cadetblue            5F           9E            A0
chartreuse           7F           FF            00
chocolate            D2           69            1E
coral                FF           7F            50
cornflowerblue       64           95            ED
cornsilk             FF           F8            DC
crimson              DC           14            3C
cyan                 00           FF            FF
darkblue             00           00            8B
darkcyan             00           8B            8B
darkgoldenrod        B8           86            0B
darkgray             A9           A9            A9
darkgreen            00           64            00
darkkhaki            BD           B7            6B
darkmagenta          8B           00            8B
darkolivegreen       55           6B            2F
darkorange           FF           8C            00
darkorchid           99           32            CC
darkred              8B           00            00
darksalmon           E9           96            7A
darkseagreen         8F           BC            8F
darkslateblue        48           3D            8B
darkslategray        2F           4F            4F
darkturquoise        00           CE            D1
darkviolet           94           00            D3
deeppink             FF           14            100
deepskyblue          00           BF            FF
dimgray              69           69            69
dodgerblue           1E           90            FF
firebrick            B2           22            22
floralwhite          FF           FA            F0
forestgreen          22           8B            22
fuchsia              FF           00            FF
gainsboro            DC           DC            DC
ghostwhite           F8           F8            FF
gold                 FF           D7            00
goldenrod            DA           A5            20
gray                 80           80            80
green                00           80            00
greenyellow          AD           FF            2F
honeydew             F0           FF            F0
hotpink              FF           69            B4
indianred            CD           5C            5C
indigo               4B           00            82
ivory                FF           FF            F0
khaki                F0           E6            8C
lavender             E6           E6            FA
lavenderblush        FF           F0            F5
lawngreen            7C           FC            00
lemonchiffon         FF           FA            CD
lightblue            AD           D8            E6
lightcoral           F0           80            80
lightcyan            E0           FF            FF
lightgoldenrodyellow FA           FA            D2
lightgreen           90           EE            90
lightgrey            D3           D3            D3
lightpink            FF           B6            C1
lightsalmon          FF           A0            7A
lightseagreen        20           B2            AA
lightskyblue         87           CE            FA
lightslategray       77           88            99
lightsteelblue       B0           C4            DE
lightyellow          FF           FF            E0
lime                 00           FF            00
limegreen            32           CD            32
linen                FA           F0            E6
magenta              FF           00            FF
maroon               80           00            00
mediumaquamarine     66           CD            AA
mediumblue           00           00            CD
mediumorchid         BA           55            D3
mediumpurple         100          70            DB
mediumseagreen       3C           B3            71
mediumslateblue      7B           68            EE
mediumspringgreen    00           FA            9A
mediumturquoise      48           D1            CC
mediumvioletred      C7           15            85
midnightblue         19           19            70
mintcream            F5           FF            FA
mistyrose            FF           E4            E1
moccasin             FF           E4            B5
navajowhite          FF           DE            AD
navy                 00           00            80
oldlace              FD           F5            E6
olive                80           80            00
olivedrab            6B           8E            23
orange               FF           A5            00
orangered            FF           45            00
orchid               DA           70            D6
palegoldenrod        EE           E8            AA
palegreen            98           FB            98
paleturquoise        AF           EE            EE
palevioletred        DB           70            100
papayawhip           FF           EF            D5
peachpuff            FF           DA            B9
peru                 CD           85            3F
pink                 FF           C0            CB
plum                 DD           A0            DD
powderblue           B0           E0            E6
purple               80           00            80
red                  FF           00            00
rosybrown            BC           8F            8F
royalblue            41           69            E1
saddlebrown          8B           45            13
salmon               FA           80            72
sandybrown           F4           A4            60
seagreen             2E           8B            57
seashell             FF           F5            EE
sienna               A0           52            2D
silver               C0           C0            C0
skyblue              87           CE            EB
slateblue            6A           5A            CD
slategray            70           80            90
snow                 FF           FA            FA
springgreen          00           FF            7F
steelblue            46           82            B4
tan                  D2           B4            8C
teal                 00           80            80
thistle              D8           BF            D8
tomato               FF           63            47
turquoise            40           E0            D0
violet               EE           82            EE
wheat                F5           DE            B3
whitesmoke           F5           F5            F5
yellow               FF           FF            00
yellowgreen          9A           CD            32
__END__

=head1 NAME

Ace::Graphics::Panel - PNG graphics of Ace::Sequence::Feature objects

=head1 SYNOPSIS

  use Ace::Sequence;
  use Ace::Graphics::Panel;

  my $db     = Ace->connect(-host=>'brie2.cshl.org',-port=>2005) or die;
  my $cosmid = Ace::Sequence->new(-seq=>'Y16B4A',
				  -db=>$db,-start=>-15000,-end=>15000) or die;

  my @transcripts = $cosmid->transcripts;

  my $panel = Ace::Graphics::Panel->new(
				      -segment => $cosmid,
				      -width  => 800
				     );


  $panel->add_track(arrow => $cosmid,
 		  -bump => 0,
 		  -tick=>2);

  $panel->add_track(transcript => \@transcripts,
 		    -fillcolor =>  'wheat',
 		    -fgcolor   =>  'black',
                    -key       => 'Curated Genes',
 		    -bump      =>  +1,
 		    -height    =>  10,
 		    -label     =>  1);

  my $boxes = $panel->boxes;
  print $panel->png;

=head1 DESCRIPTION

The Ace::Graphics::Panel class provides drawing and formatting
services for Ace::Sequence::Feature objects or Das::Segment::Feature
objects.

Typically you will begin by creating a new Ace::Graphics::Panel
object, passing it the width of the visual display and the length of
the segment.  

You will then call add_track() one or more times to add sets of
related features to the picture.  When you have added all the features
you desire, you may call png() to convert the image into a PNG-format
image, or boxes() to return coordinate information that can be used to
create an imagemap.

Note that this modules depends on GD.

=head1 METHODS

This section describes the class and object methods for
Ace::Graphics::Panel.

=head2 CONSTRUCTORS

There is only one constructor, the new() method.

=over 4

=item $panel = Ace::Graphics::Panel->new(@options)

The new() method creates a new panel object.  The options are
a set of tag/value pairs as follows:

  Option      Value                                Default
  ------      -----                                -------

  -length     Length of sequence segment, in bp    0

  -segment    An Ace::Sequence or Das::Segment     none
              object, used to derive length if
	      not provided

  -offset     Base pair to place at extreme left   $segment->start
	      of image.

  -width      Desired width of image, in pixels    600

  -spacing    Spacing between tracks, in pixels    5

  -pad_top    Additional whitespace between top    0
	      of image and contents, in pixels

  -pad_bottom Additional whitespace between top    0
	      of image and bottom, in pixels

  -pad_left   Additional whitespace between left   0
	      of image and contents, in pixels

  -pad_right  Additional whitespace between right  0
	      of image and bottom, in pixels

  -keycolor   Background color for the key printed 'cornsilk'
              at bottom of panel (if any)

  -keyspacing Spacing between key glyphs in the    10
              key printed at bottom of panel
              (if any)

Typically you will pass new() an object that implements the
Bio::RangeI interface, providing a length() method, from which the
panel will derive its scale.

  $panel = Ace::Graphics::Panel->new(-segment => $sequence,
				     -width   => 800);

new() will return undef in case of an error. If the specified glyph
name is not a valid one, new() will throw an exception.

=back

=head2 OBJECT METHODS

=over 4

=item $track = $panel->add_track($glyph,$features,@options)

The add_track() method adds a new track to the image. 

Tracks are horizontal bands which span the entire width of the panel.
Each track contains a number of graphical elements called "glyphs",
each corresponding to a sequence feature. There are different glyph
types, but each track can only contain a single type of glyph.
Options passed to the track control the color and size of the glyphs,
whether they are allowed to overlap, and other formatting attributes.
The height of a track is determined from its contents and cannot be
directly influenced.

The first two arguments are the glyph name and an array reference
containing the list of features to display.  The order of the
arguments is irrelevant, allowing either of these idioms:

  $panel->add_track(arrow => \@features);
  $panel->add_track(\@features => 'arrow');

The glyph name indicates how each feature is to be rendered.  A
variety of glyphs are available, and the number is growing.
Currently, the following glyphs are available:

  Name        Description
  ----        -----------

  box	      A filled rectangle, nondirectional.

  ellipse     A filled ellipse, nondirectional.

  arrow	      An arrow; can be unidirectional or bidirectional.
	      It is also capable of displaying a scale with
	      major and minor tickmarks, and can be oriented
	      horizontally or vertically.

  segments    A set of filled rectangles connected by solid lines.
	      Used for interrupted features, such as gapped
	      alignments.

  transcript  Similar to segments, but the connecting line is
	      a "hat" shape, and the direction of transcription
	      is indicated by a small arrow.

  transcript2 Similar to transcript, but the arrow that indicates
              the direction of transcription is the last exon
              itself.

  primers     Two inward pointing arrows connected by a line.
	      Used for STSs.

  toomany     A "cloud", to indicate too many features to show
	      individually.  This is a placeholder that will be
	      replaced by something more clever, such as a histogram
	      or density plot.

  group	      A group of related features connected by a dashed line.
	      This is used internally by the Track class and should
	      not be called explicitly.

If the glyph name is omitted from add_track(), the "box" glyph will be
used by default.

The @options array is a list of name/value pairs that control the
attributes of the track.  The options are in turn passed to the
glyphs.  Each glyph has its own specialized subset of options, but
some are shared by all glyphs:

  Option      Description               Default
  ------      -----------               -------

  -glyph      Glyph to use              none

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

  -bump	      Bump direction		0

  -connect_groups                       false
              Connect groups by a
	      dashed line (see below)

  -key        Show this track in the    undef
              key

Colors can be expressed in either of two ways: as symbolic names such
as "cyan" and as HTML-style #RRGGBB triples.  The symbolic names are
the 140 colors defined in the Netscape/Internet Explorer color cube,
and can be retrieved using the Ace::Graphics::Panel->color_names()
method.

The background color is used for the background color of the track
itself.  The foreground color controls the color of lines and strings.
The interior color is used for filled objects such as boxes.

The -label argument controls whether or not the ID of the feature
should be printed next to the feature.  It is accepted by most, but
not all of the glyphs.

The -bump argument controls what happens when glyphs collide.  By
default, they will simply overlap (value 0).  A -bump value of +1 will
cause overlapping glyphs to bump downwards until there is room for
them.  A -bump value of -1 will cause overlapping glyphs to bump
upwards.

The -key argument declares that the track is to be shown in a key
appended to the bottom of the image.  The key contains a picture of a
glyph and a label describing what the glyph means.  The label is
specified in the argument to -key.

If present, the -glyph argument overrides the glyph given in the first
or second argument.

add_track() returns an Ace::Graphics::Track object.  You can use this
object to add additional features or to control the appearance of the
track with greater detail, or just ignore it.  Tracks are added in
order from the top of the image to the bottom.  To add tracks to the
top of the image, use unshift_track().

Typical usage is:

 $panel->add_track( thistle    => \@genes,
 		    -fillcolor =>  'green',
 		    -fgcolor   =>  'black',
 		    -bump      =>  +1,
 		    -height    => 10,
 		    -label     => 1);

=item $track = unshift_track($glyph,$features,@options)

unshift_track() works like add_track(), except that the new track is
added to the top of the image rather than the bottom.

B<Adding groups of features:> It is not uncommon to add a group of
features which are logically connected, such as the 5' and 3' ends of
EST reads.  To group features into sets that remain on the same
horizontal position and bump together, pass the sets as an anonymous
array.  To connect the groups by a dashed line, pass the
-connect_groups argument with a true value.  For example:

  $panel->add_track(segments => [[$abc_5,$abc_3],
				 [$xxx_5,$xxx_3],
				 [$yyy_5,$yyy_3]],
		    -connect_groups => 1);

=item $gd = $panel->gd

The gd() method lays out the image and returns a GD::Image object
containing it.  You may then call the GD::Image object's png() or
jpeg() methods to get the image data.

=item $png = $panel->png

The png() method returns the image as a PNG-format drawing, without
the intermediate step of returning a GD::Image object.

=item $boxes = $panel->boxes

=item @boxes = $panel->boxes

The boxes() method returns the coordinates of each glyph, useful for
constructing an image map.  In a scalar context, boxes() returns an
array ref.  In an list context, the method returns the array directly.

Each member of the list is an anonymous array of the following format:

  [ $feature, $x1, $y1, $x2, $y2 ]

The first element is the feature object; either an
Ace::Sequence::Feature, a Das::Segment::Feature, or another Bioperl
Bio::SeqFeatureI object.  The coordinates are the topleft and
bottomright corners of the glyph, including any space allocated for
labels.

=back

=head2 ACCESSORS

The following accessor methods provide access to various attributes of
the panel object.  Called with no arguments, they each return the
current value of the attribute.  Called with a single argument, they
set the attribute and return its previous value.

Note that in most cases you must change attributes prior to invoking
gd(), png() or boxes().  These three methods all invoke an internal
layout() method which places the tracks and the glyphs within them,
and then caches the result.

   Accessor Name      Description
   -------------      -----------

   width()	      Get/set width of panel
   spacing()	      Get/set spacing between tracks
   length()	      Get/set length of segment (bp)
   pad_top()	      Get/set top padding
   pad_left()	      Get/set left padding
   pad_bottom()	      Get/set bottom padding
   pad_right()	      Get/set right padding

=head2 INTERNAL METHODS

The following methods are used internally, but may be useful for those
implementing new glyph types.

=over 4

=item @names = Ace::Graphics::Panel->color_names

Return the symbolic names of the colors recognized by the panel
object.  In a scalar context, returns an array reference.

=item @rgb = $panel->rgb($index)

Given a GD color index (between 0 and 140), returns the RGB triplet
corresponding to this index.  This method is only useful within a
glyph's draw() routine, after the panel has allocated a GD::Image and
is populating it.

=item $index = $panel->translate($color)

Given a color, returns the GD::Image index.  The color may be
symbolic, such as "turquoise", or a #RRGGBB triple, as in #F0E0A8.
This method is only useful within a glyph's draw() routine, after the
panel has allocated a GD::Image and is populating it.

=item $panel->set_pen($width,$color)

Changes the width and color of the GD drawing pen to the values
indicated.  This is called automatically by the GlyphFactory fgcolor()
method.

=back

=head1 BUGS

Please report them.

=head1 SEE ALSO

L<Ace::Sequence>,L<Ace::Sequence::Feature>,
L<Ace::Graphics::Track>,L<Ace::Graphics::Glyph>,
L<GD>

=head1 AUTHOR

Lincoln Stein <lstein@cshl.org>.

Copyright (c) 2001 Cold Spring Harbor Laboratory

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut

