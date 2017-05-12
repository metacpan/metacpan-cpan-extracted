package Ace::Graphics::Glyph::arrow;
# package to use for drawing an arrow

use strict;
use vars '@ISA';
@ISA = 'Ace::Graphics::Glyph';

sub bottom {
  my $self = shift;
  my $val = $self->SUPER::bottom(@_);
  $val += $self->font->height if $self->option('tick');
  $val += $self->labelheight  if $self->option('label');
  $val;
}

# override draw method
sub draw {
  my $self = shift;
  my $parallel = $self->option('parallel');
  $parallel = 1 unless defined $parallel;
  $self->draw_parallel(@_) if $parallel;
  $self->draw_perpendicular(@_) unless $parallel;
}

sub draw_perpendicular {
  my $self = shift;
  my $gd = shift;
  my ($x1,$y1,$x2,$y2) = $self->calculate_boundaries(@_);

  my $ne = $self->option('northeast');
  my $sw = $self->option('southwest');
  $ne = $sw = 1 unless defined($ne) || defined($sw);

  # draw a perpendicular arrow at position indicated by $x1
  my $fg = $self->fgcolor;
  my $a2 = $self->SUPER::height/4;

  my @positions = $x1 == $x2 ? ($x1) : ($x1,$x2);
  for my $x (@positions) {
    if ($ne) {
      $gd->line($x,$y1,$x,$y2,$fg);
      $gd->line($x-$a2,$y1+$a2,$x,$y1,$fg);
      $gd->line($x+$a2,$y1+$a2,$x,$y1,$fg);
    }
    if ($sw) {
      $gd->line($x,$y1,$x,$y2,$fg);
      $gd->line($x-$a2,$y2-$a2,$x,$y2,$fg);
      $gd->line($x+$a2,$y2-$a2,$x,$y2,$fg);
    }
  }

  # add a label if requested
  if ($self->option('label')) {
    $self->draw_label($gd,@_);  # this draws the label aligned to the left
  }
}

sub draw_parallel {
  my $self = shift;
  my $gd = shift;
  my ($x1,$y1,$x2,$y2) = $self->calculate_boundaries(@_);

  my $fg = $self->fgcolor;
  my $a2 = $self->SUPER::height/2;
  my $center = $y1+$a2;

  my $ne = $self->option('northeast');
  my $sw = $self->option('southwest');
  # turn on both if neither specified
  $ne = $sw = 1 unless defined($ne) || defined($sw);

  # turn on ticks
  if ($self->option('tick')) {
    my $left = shift;

    my $scale = $self->scale;

    # figure out tick mark scale
    # we want no more than 1 tick mark every 30 pixels
    # and enough room for the labels
    my $font = $self->font;
    my $width = $font->width;
    my $font_color = $self->fontcolor;

    my $interval = 1;
    my $mindist =  30;
    my $widest = 5 + (length($self->end) * $width);
    $mindist = $widest if $widest > $mindist;


    my ($gcolor,$gtop,$gbottom);
    if ($self->option('grid')) {
      $gcolor = $self->color('grid');
      my $panel_height = $self->factory->panel->height;
      $gtop    = $self->factory->panel->pad_top;
      $gbottom = $panel_height - $self->factory->panel->pad_bottom;
    }

    while (1) {
      my $pixels = $interval * $scale;
      last if $pixels >= $mindist;
      $interval *= 10;
    }

    my $first_tick = $interval * int(0.5 + $self->start/$interval);

    for (my $i = $first_tick; $i < $self->end; $i += $interval) {
      my $tickpos = $left + $self->map_pt($i);
      $gd->line($tickpos,$gtop,$tickpos,$gbottom,$gcolor) if defined $gcolor;
      $gd->line($tickpos,$center-$a2,$tickpos,$center+$a2,$fg);
    }

    if ($self->option('tick') >= 2) {
      my $a4 = $self->SUPER::height/4;
      for (my $i = $first_tick - $interval; $i < $self->end; $i += $interval/10) {
	my $tickpos = $left + $self->map_pt($i);
	$gd->line($tickpos,$gtop,$tickpos,$gbottom,$gcolor) if defined $gcolor;
	$gd->line($tickpos,$center-$a4,$tickpos,$center+$a4,$fg);
      }
    }

    for (my $i = $first_tick; $i < $self->end; $i += $interval) {
      my $tickpos = $left + $self->map_pt($i);
      my $middle = $tickpos - (length($i) * $width)/2;
      $gd->string($font,$middle,$center+$a2-1,$i,$font_color)
	if $middle > 0 && $middle < $self->factory->panel->width-($font->width * length $i);
    }

  }

  $gd->line($x1,$center,$x2,$center,$fg);
  if ($sw) {  # west arrow
    $gd->line($x1,$center,$x1+$a2,$center-$a2,$fg);
    $gd->line($x1,$center,$x1+$a2,$center+$a2,$fg);
  }
  if ($ne) {  # east arrow
    $gd->line($x2,$center,$x2-$a2,$center+$a2,$fg);
    $gd->line($x2,$center,$x2-$a2,$center-$a2,$fg);
  }

  # add a label if requested
  $self->draw_label($gd,@_) if $self->option('label');

}

1;

__END__

=head1 NAME

Ace::Graphics::Glyph::arrow - The "arrow" glyph

=head1 SYNOPSIS

  See L<Ace::Graphics::Panel> and L<Ace::Graphics::Glyph>.

=head1 DESCRIPTION

This glyph draws arrows.  Depending on options, the arrows can be
labeled, be oriented vertically or horizontally, or can contain major
and minor ticks suitable for use as a scale.

=head2 OPTIONS

In addition to the common options, the following glyph-specific
options are recognized:

  Option      Description               Default
  ------      -----------               -------

  -tick       Whether to draw major       0
              and minor ticks.
	      0 = no ticks
	      1 = major ticks
	      2 = minor ticks

  -parallel   Whether to draw the arrow   true
	      parallel to the sequence
	      or perpendicular to it.

  -northeast  Whether to draw the         true
	      north or east arrowhead
	      (depending on orientation)

  -southwest  Whether to draw the         true
	      south or west arrowhead
	      (depending on orientation)

Set -parallel to false to display a point-like feature such as a
polymorphism, or to indicate an important location.  If the feature
start == end, then the glyph will draw a single arrow at the
designated location:

       ^
       |

Otherwise, there will be two arrows at the start and end:

       ^              ^
       |              |

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
