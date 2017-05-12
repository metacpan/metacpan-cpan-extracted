package Ace::Graphics::GlyphFactory;
# parameters for creating sequence glyphs of various sorts
# you *do* like glyphs, don't you?

use strict;
use Carp qw(carp croak confess);
use Ace::Graphics::Glyph;
use GD;

sub DESTROY { }

sub new {
  my $class   = shift;
  my $type    = shift;
  my @options = @_;

  # normalize options
  my %options;
  while (my($key,$value) = splice (@options,0,2)) {
    $key =~ s/^-//;
    $options{lc $key} = $value;
  }
  $options{bgcolor}   ||= 'white';
  $options{fgcolor}   ||= 'black';
  $options{fillcolor} ||= 'turquoise';
  $options{height}    ||= 10;
  $options{font}      ||= gdSmallFont;
  $options{fontcolor} ||= 'black';

  $type = $options{glyph} if defined $options{glyph};

  my $glyphclass = 'Ace::Graphics::Glyph';
  $glyphclass .= "\:\:$type" if $type && $type ne 'generic';

    confess("the requested glyph class, ``$type'' is not available: $@")
      unless (eval "require $glyphclass");

  return bless {
		glyphclass => $glyphclass,
		scale      => 1,   # 1 pixel per kb
		options    => \%options,
	       },$class;
}

sub clone {
  my $self = shift;
  my %val = %$self;
  $val{options} = {%{$self->{options}}};
  return bless \%val,ref($self);
}

# set the scale for glyphs we create
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

# font to draw with
sub font {
  my $self = shift;
  $self->option('font',@_);
}

# set the height for glyphs we create
sub height {
  my $self = shift;
  $self->option('height',@_);
}

sub options {
  my $self = shift;
  my $g = $self->{options};
  $self->{options} = shift if @_;
  $g;
}

sub panel {
  my $self = shift;
  my $g = $self->{panel};
  $self->{panel} = shift if @_;
  $g;
}

sub option {
  my $self        = shift;
  my $option_name = shift;
  my $o = $self->{options} or return;
  my $d = $o->{$option_name};
  $o->{$option_name} = shift if @_;
  $d;
}

# set the foreground and background colors
# expressed as GD color indices
sub _fgcolor {
  my $self = shift;
  my $c = $self->option('color',@_) || $self->option('fgcolor',@_) || $self->option('outlinecolor',@_);
  $self->translate($c);
}

sub fgcolor {
  my $self = shift;
  my $linewidth = $self->option('linewidth');
  return $self->_fgcolor unless defined($linewidth) && $linewidth > 1;
  $self->panel->set_pen($linewidth,$self->_fgcolor);
  return gdBrushed;
}

sub fontcolor {
  my $self = shift;
  my $c = $self->option('fontcolor',@_);
  $self->translate($c);
#  return $self->_fgcolor;
}

sub bgcolor {
  my $self = shift;
  my $c = $self->option('bgcolor',@_);
  $self->translate($c);
}

sub fillcolor {
  my $self = shift;
  my $c = $self->option('fillcolor',@_) || $self->option('color',@_);
  $self->translate($c);
}

sub length {  shift->option('length',@_) }
sub offset {  shift->option('offset',@_) }
sub translate { my $self = shift; $self->panel->translate(@_) || $self->fgcolor; }
sub rgb       { shift->panel->rgb(@_) }

# create a new glyph from configuration
sub glyph {
  my $self    = shift;
  my $feature = shift;
  return $self->{glyphclass}->new(-feature => $feature,
				  -factory => $self);
}

1;
__END__

=head1 NAME

Ace::Graphics::GlyphFactory - Create Ace::Graphics::Glyphs

=head1 SYNOPSIS

  use Ace::Graphics::GlyphFactory;

  my $factory = Ace::Graphics::GlyphFactory($glyph_name,@options);

=head1 DESCRIPTION

The Ace::Graphics::GlyphFactory class is used internally by
Ace::Graphics::Track and Ace::Graphics::Glyph to hold the options
pertaining to a set of related glyphs and creating them on demand.
This class is not ordinarily useful to the end-developer.

=head1 METHODS

This section describes the class and object methods for
Ace::Graphics::GlyphFactory.

=head2 CONSTRUCTORS

There is only one constructor, the new() method.  It is ordinarily
called by Ace::Graphics::Track, in the make_factory() subroutine.

=over 4

=item $factory = Ace::Graphics::GlyphFactory->new($glyph_name,@options)

The new() method creates a new factory object.  The object will create
glyphs of type $glyph_name, and using the options specified in
@options.  Generic options are described in L<Ace::Graphics::Panel>,
and specific options are described in each of the
Ace::Graphics::Glyph::* manual pages.
=back

=head2 OBJECT METHODS

Once a track is created, the following methods can be invoked:

=over 4

=item $glyph = $factory->glyph($feature)

Given a sequence feature, creates an Ace::Graphics::Glyph object to
display it.  The various attributes of the glyph are set from the
options provided at factory creation time.

=item $option = $factory->option($option_name [,$new_option])

Given an option name, returns its value.  If a second argument is
provided, sets the option to the new value and returns its previous
one.

=item $index = $factory->fgcolor

Returns the desired foreground color for the glyphs in the form of an
GD::Image color index.  This may be the one of the special colors
gdBrushed and gdStyled.  This is only useful while the enclosing
Ace::Graphics::Panel object is rendering the object.  In other
contexts it returns undef.

=item $scale = $factory->scale([$scale])

Get or set the scale, in pixels/bp, for the glyph.  This is
ordinarily set by the Ace::Graphics::Track object just prior to
rendering, and called by each glyphs' map_pt() method when performing
the rendering.

=item $color = $factory->bgcolor([$color])

Get or set the background color for the glyphs.

=item $color = $factory->fillcolor([$color])

Get or set the fill color for the glyphs.

=item $font = $factory->font([$font])

Get or set the font to use for rendering the glyph.

=item $color = $factory->fontcolor

Get the color for the font (to set it, use fgcolor()).  This is subtly
different from fgcolor() itself, because it will never return a styled
color, such as gdBrushed.

=item $panel = $factory->panel([$panel])

Get or set the panel that contains the GD::Image object used by this
factory.

=item $index = $factory->translate($color)

=item @rgb = $factory->rgb($index)

These are convenience procedures that are passed through to the
enclosing Panel object and have the same effect as the like-named
methods in that class.  See L<Ace::Graphics::Panel>.

=back

=head1 BUGS

Please report them.

=head1 SEE ALSO

L<Ace::Sequence>, L<Ace::Sequence::Feature>, L<Ace::Graphics::Panel>,
L<Ace::Graphics::Track>, L<Ace::Graphics::Glyph>

=head1 AUTHOR

Lincoln Stein <lstein@cshl.org>.

Copyright (c) 2001 Cold Spring Harbor Laboratory

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut
