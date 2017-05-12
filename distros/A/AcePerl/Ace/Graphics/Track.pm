package Ace::Graphics::Track;
# This embodies the logic for drawing a single track of features.
# Features are of uniform style and are controlled by descendents of
# the Ace::Graphics::Glyph class (eek!).

use Ace::Graphics::GlyphFactory;
use Ace::Graphics::Fk;
use GD;  # maybe
use Carp 'croak';
use vars '$AUTOLOAD';
use strict;

sub AUTOLOAD {
  my $self = shift;
  my($pack,$func_name) = $AUTOLOAD=~/(.+)::([^:]+)$/;
  $self->factory->$func_name(@_);
}

sub DESTROY { }

# Pass a list of Ace::Sequence::Feature objects, and a glyph name
sub new {
  my $class = shift;
  my ($glyph_name,$features,@options) = @_;

  $glyph_name ||= 'generic';
  $features   ||= [];

  my $glyph_factory = $class->make_factory($glyph_name,@options);
  my $self = bless {
		    features => [],                     # list of Ace::Sequence::Feature objects
		    factory  => $glyph_factory,         # the glyph class associated with this track
		    glyphs   => undef,                  # list of glyphs
		   },$class;
  $self->add_feature($_) foreach @$features;
  $self;
}

# control bump direction:
#    +1   => bump downward
#    -1   => bump upward
#     0   => no bump
sub bump {
  my $self = shift;
  $self->factory->option('bump',@_);
}

# add a feature (or array ref of features) to the list
sub add_feature {
  my $self       = shift;
  my $feature    = shift;
  if (ref($feature) eq 'ARRAY') {
    my $name     = ++$self->{group_name};
    $self->{group_ids}{$name} = $feature;
  } else {
    push @{$self->{features}},$feature;
  }
}

# link a set of features together so that they bump as a group
sub add_group {
  my $self     = shift;
  my $features = shift;
  ref($features) eq 'ARRAY' or croak("Usage: Ace::Graphics::Track->add_group(\$arrayref)");
  $self->add_feature($features);
}

# delegate lineheight to the glyph
sub lineheight {
  shift->{factory}->height(@_);
}

# the scale is horizontal, measured in pixels/bp
sub scale {
  my $self = shift;
  my $g = $self->{scale};
  $self->{scale} = shift if @_;
  $g;
}

sub width {
  my $self = shift;
  my $g = $self->{width};
  $self->{width} = shift if @_;
  $g;
}

# set scale by a segment
sub scale_to_segment {
  my $self = shift;
  my ($segment,$desired_width) = @_;
  $self->set_scale(abs($segment->length),$desired_width);
}

sub set_scale {
  my $self = shift;
  my ($bp,$desired_width) = @_;
  $desired_width ||= 512;
  $self->scale($desired_width/$bp);
  $self->width($desired_width);
}

# return the glyph class
sub factory {
  my $self = shift;
  my $g = $self->{factory};
  $self->{factory} = shift if @_;
  $g;
}

# return boxes for each of the glyphs
# will be an array of four-element [$feature,l,t,r,b] arrays
sub boxes {
  my $self = shift;
  my ($left,$top) = @_;
  $top  += 0; $left += 0;
  my @result;

  my $glyphs = $self->layout;

  for my $g (@$glyphs) {
    my ($l,$t,$r,$b) = $g->box;
    push @result,[$g->feature,$left+$l,$top+$t,$left+$r,$top+$b];

  }

  return wantarray ? @result : \@result;
}

# synthesize a key glyph
sub keyglyph {
  my $self = shift;
  my $scale = 1/$self->scale;  # base pairs/pixel
  # two segments, at pixels 0->50, 60->80
  my $offset = $self->offset;
  my $feature = Ace::Graphics::Fk->new(-segments=>[ [ 0*$scale +$offset,50*$scale+$offset],
						    [60*$scale+$offset, 80*$scale+$offset]
						    ],
				       -name => $self->option('key'),
				       -strand => '+1');
  my $factory = $self->factory->clone;
  $factory->scale($self->scale);
  $factory->width($self->width);
  $factory->option(label=>1);  # turn on labels
  return $factory->glyph($feature);
}

# draw glyphs onto a GD object at the indicated position
sub draw {
  my $self = shift;
  my ($gd,$left,$top) = @_;
  $top  += 0;  $left += 0;
  my $glyphs = $self->layout;

  # draw background
  my $bgcolor = $self->factory->bgcolor;
  # $gd->filledRectangle($left,$top,$left+$self->width,$top+$self->height,$bgcolor);

  if (my $label = $self->factory->option('track_label')) {
    my $font = $self->factory->font;
    my $y = $top + ($self->height-$font->height)/2;
    my $x = $left - length($label) * $font->width;
    $gd->string($font,$x,$y,$label,$self->factory->fontcolor);
  }
  $_->draw($gd,$left,$top) foreach @$glyphs;

  if ($self->factory->option('connectgroups')) {
    $_->draw($gd,$left,$top) foreach @{$self->{groups}};
  }
}

# lay out -- this uses the infamous bump algorithm
sub layout {
  my $self = shift;
  my $force = shift || 0;
  return $self->{glyphs} if $self->{glyphs} && !$force;

  my $f = $self->{features};
  my $factory = $self->factory;
  $factory->scale($self->scale);  # set the horizontal scale
  $factory->width($self->width);

  # create singleton glyphs
  my @singletons = map { $factory->glyph($_) } @$f;

  # create linked groups of glyphs
  my @groups;
  if (my $groups = $self->{group_ids}) {
    my $groupfactory = Ace::Graphics::GlyphFactory->new('group');
    for my $g (values %$groups) {
      my @g = map { $factory->glyph($_) } @$g;
      push @groups,$groupfactory->glyph(\@g);
    }
  }

  return $self->{glyphs} = [] unless @singletons || @groups;

  # run the bumper on the groups
  $self->_bump([@singletons,@groups]) if $self->bump;

  # merge the singletons and groups and sort them horizontally
  my @glyphs = sort {$a->left <=> $b->left } @singletons,map {$_->members} @groups;

  # If -1 bumping was allowed, then normalize so that the top glyph is at zero
  my ($topmost) = sort {$a->top <=> $b->top} @glyphs;
  my $offset = 0 - $topmost->top;
  $_->move(0,$offset) foreach @glyphs;

  $self->{groups}        = \@groups;
  return $self->{glyphs} = \@glyphs;
}

# bumper - glyphs already sorted left to right
sub _bump {
  my $self   = shift;
  my $glyphs = shift;
  my $bump_direction = $self->bump;  # +1 means bump down, -1 means bump up

  my @occupied;
  my $rightmost = -2;
  for my $g (sort { $a->left <=> $b->left} @$glyphs) {

    my $pos = 0;
    while (1) {
      # look for collisions
      last if $g->left > $rightmost + 2;
      my $bottom = $pos + $g->height;

      my $collision = 0;
      for my $old (@occupied) {
	last if $old->right + 2 < $g->left;
	next if $old->bottom < $pos;
	next if $old->top > $bottom;
	$collision = $old;
	last;
      }
      last unless $collision;
      if ($bump_direction > 0) {
	$pos += $collision->height + 2;                    # collision, so bump
      } else {
	$pos -= $g->height + 2;
      }
    }

    $g->move(0,$pos);
    @occupied = sort { $b->right <=> $a->right } ($g,@occupied);
    $rightmost = $g->right if $g->right > $rightmost;
  }
}

# return list of glyphs -- only after they are laid out
sub glyphs { shift->{glyphs} }

# height is determined by the layout, and cannot be externally controlled
sub height {
  my $self = shift;
  return $self->{cache_height} if defined $self->{cache_height};

  $self->layout;
  my $glyphs = $self->{glyphs} or croak "Can't lay out";
  return 0 unless @$glyphs;

  my ($topmost)    = sort { $a->top    <=> $b->top }    @$glyphs;
  my ($bottommost) = sort { $b->bottom <=> $a->bottom } @$glyphs;

  return $self->{cache_height} = $bottommost->bottom - $topmost->top;
}

sub make_factory {
  my ($class,$type,@options) = @_;
  Ace::Graphics::GlyphFactory->new($type,@options);
}


1;
__END__

=head1 NAME

Ace::Graphics::Track - PNG graphics of Ace::Sequence::Feature objects

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


  my $track = $panel->add_track('transcript'
   		                -fillcolor =>  'wheat',
				-fgcolor   =>  'black',
				-bump      =>  +1,
				-height    =>  10,
				-label     =>  1);
  foreach (@transcripts) {
     $track->add_feature($_);
  }

  my $boxes = $panel->boxes;
  print $panel->png;


=head1 DESCRIPTION

The Ace::Graphics::Track class is used by Ace::Graphics::Panel to lay
out a set of sequence features using a uniform glyph type. You will
ordinarily work with panels rather than directly with tracks.

=head1 METHODS

This section describes the class and object methods for
Ace::Graphics::Panel.

=head2 CONSTRUCTORS

There is only one constructor, the new() method.  It is ordinarily
called by Ace::Graphics::Panel, and not in end-developer code.

=over 4

=item $track = Ace::Graphics::Track->new($glyph_name,$features,@options)

The new() method creates a new track object from the provided glyph
name and list of features.  The arguments are similar to those in
Ace::Graphics::Panel->new().

If successful new() will return a new Ace::Graphics::Track.
Otherwise, it will return undef.

If the specified glyph name is not a valid one, new() will throw an
exception.

=back

=head2 OBJECT METHODS

Once a track is created, the following methods can be invoked.

=over 4

=item $track->add_feature($feature)

This adds a new feature to the track.  The feature can either be a
single object that implements the Bio::SeqFeatureI interface (such as
an Ace::Sequence::Feature or Das::Segment::Feature), or can be an
anonymous array containing a set of related features.  In the latter
case, the track will attempt to keep the features in the same
horizontal band and will not allow any other features to overlap.

=item $track->add_group($group)

This behaves the same as add_feature(), but requires that its argument
be an array reference containing a list of grouped features.

=item $track->draw($gd,$left,$top)

Render the track on a previously-created GD::Image object.  The $left
and $top arguments indicate the position at which to start rendering.

=item $boxes = $track->boxes($left,$top)

=item @boxes = $track->boxes($left,$top)

Return an array of array references indicating glyph coordinates for
each of the render features.  $left and $top indicate the offset for
the track on the image plane.  In a scalar context, this method
returns an array reference of glyph coordinates.  In a list context,
it returns the list itself.

See Ace::Graphics::Panel->boxes() for the format of the result.

=back

=head2 ACCESSORS

The following accessor methods provide access to various attributes of
the track object.  Called with no arguments, they each return the
current value of the attribute.  Called with a single argument, they
set the attribute and return its previous value.

Note that in most cases you must change attributes before the track's
layout() method is called.

   Accessor Name      Description
   -------------      -----------

   scale()	      Get/set the track scale, measured in pixels/bp
   lineheight()	      Get/set the height of each glyph, pixels
   width()	      Get/set the width of the track
   bump()	      Get/set the bump direction

=head2 INTERNAL METHODS

The following methods are used internally, but may be useful for those
implementing new glyph types.

=over 4

=item $glyphs = $track->layout

Layout the features, and return an anonymous array of
Ace::Graphics::Glyph objects that have been created and correctly
positioned.

Because layout is an expensive operation, calling this method several
times will return the previously-cached result, ignoring any changes
to track attributes.

=item $height = $track->height

Invokes layout() and returns the height of the track.

=item $glyphs = $track->glyphs

Returns the glyph cache.  Returns undef before layout() and a
reference to an array of glyphs after layout().

=item $factory = $track->make_factory(@options)

Given a set of options (argument/value pairs), returns a
Ace::Graphics::GlyphFactory for use in creating the glyphs with the
desired settings.

=back

=head1 BUGS

Please report them.

=head1 SEE ALSO

L<Ace::Sequence>,L<Ace::Sequence::Feature>,L<Ace::Graphics::Panel>,
L<Ace::Graphics::GlyphFactory>,L<Ace::Graphics::Glyph>

=head1 AUTHOR

Lincoln Stein <lstein@cshl.org>.

Copyright (c) 2001 Cold Spring Harbor Laboratory

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut

