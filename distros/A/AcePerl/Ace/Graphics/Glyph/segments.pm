package Ace::Graphics::Glyph::segments;
# package to use for drawing anything that is interrupted
# (has the segment() method)

use strict;
use vars '@ISA';
use GD;
@ISA = 'Ace::Graphics::Glyph';

use constant GRAY  => 'lightgrey';
my %BRUSHES;

# override right to allow for label
sub calculate_right {
  my $self = shift;
  my $left = $self->left;
  my $val = $self->SUPER::calculate_right(@_);

  if ($self->option('label') && (my $description = $self->description)) {
    my $description_width = $self->font->width * length $self->description;
    $val = $left + $description_width if $left + $description_width > $val;
  }
  $val;
}

# override draw method
sub draw {
  my $self = shift;

  # bail out if this isn't the right kind of feature
  # handle both das-style and Bio::SeqFeatureI style,
  # which use different names for subparts.
  my @segments;
  my $f = $self->feature;
  if ($f->can('merged_segments')) {
    @segments = $f->merged_segments;

  } elsif ($f->can('segments')) {
    @segments = $f->segments;

  } elsif ($f->can('sub_SeqFeature')) {
    @segments = $f->sub_SeqFeature;

  } else {
    return $self->SUPER::draw(@_);
  }

  # get parameters
  my $gd = shift;
  my ($x1,$y1,$x2,$y2) = $self->calculate_boundaries(@_);
  my ($left,$top) = @_;

  my $gray = $self->color(GRAY);

  my (@boxes,@skips);
  my $stranded = $self->option('stranded');

  for (my $i=0; $i < @segments; $i++) {
    my ($start,$stop) = ($left + $self->map_pt($segments[$i]->start),
			 $left + $self->map_pt($segments[$i]->end));

    my $strand = 0;
    my $target;

    if ($stranded
	&& $segments[$i]->can('target') 
	&& ($target = $segments[$i]->target) 
	&& $target->can('start')) {
      $strand = $target->start < $target->end ? 1 : -1;
    }

    # probably unnecessary, but we do it out of paranaoia
    ($start,$stop) = ($stop,$start) if $start > $stop;

    push @boxes,[$start,$stop,$strand];

    if (my $next_segment = $segments[$i+1]) {
      my ($next_start,$next_stop) = ($left + $self->map_pt($next_segment->start),
				     $left + $self->map_pt($next_segment->end));
      # probably unnecessary, but we do it out of paranaoia
      ($next_start,$next_stop) = ($next_stop,$next_start) if $next_start > $next_stop;

      # fudge boxes that are within two pixels of each other
      if ($next_start - $stop < 2) {
	$boxes[-1][1] = $next_start;
      }
      push @skips,[$stop+1,$next_start-1];
    }
  }

  my $fg     = $self->fgcolor;
  my $fill   = $self->fillcolor;
  my $center = ($y1 + $y2)/2;

  # each segment becomes a box
  for my $e (@boxes) {
    my @rect = ($e->[0],$y1,$e->[1],$y2);
    if ($e->[2] == 0 || !$stranded) {
      $self->filled_box($gd,@rect);
    } else {
#      $self->filled_arrow($gd,1,@rect);
      $self->oriented_box($gd,$e->[2],@rect);
    }
  }

  # each skip becomes a simple line
  for my $i (@skips) {
    next unless $i->[1] - $i->[0] >= 1;
    $gd->line($i->[0],$center,$i->[1],$center,$gray);
  }

  # draw label
  $self->draw_label($gd,@_) if $self->option('label');
}

sub oriented_box {
  my $self = shift;
  my $gd  = shift;
  my $orientation = shift;
  my ($x1,$y1,$x2,$y2) = @_;
  $self->filled_box($gd,@_);
  return unless $x2 - $x1 >= 4;
  $BRUSHES{$orientation} ||= $self->make_brush($orientation);
  my $top = int(1.5 + $y1 + ($y2 - $y1 - ($BRUSHES{$orientation}->getBounds)[1])/2);
  $gd->setBrush($BRUSHES{$orientation});
  $gd->setStyle(0,0,0,1);
  $gd->line($x1+2,$top,$x2-2,$top,gdStyledBrushed);
}

sub make_brush {
  my $self = shift;
  my $orientation = shift;

  my $brush   = GD::Image->new(3,3);
  my $bgcolor = $brush->colorAllocate(255,255,255); #white
  $brush->transparent($bgcolor);
  my $fgcolor   = $brush->colorAllocate($self->factory->panel->rgb($self->fgcolor));
  if ($orientation > 0) {
    $brush->setPixel(0,0,$fgcolor);
    $brush->setPixel(1,1,$fgcolor);
    $brush->setPixel(0,2,$fgcolor);
  } else {
    $brush->setPixel(1,0,$fgcolor);
    $brush->setPixel(0,1,$fgcolor);
    $brush->setPixel(1,2,$fgcolor);
  }
  $brush;
}


sub description {
  my $self = shift;
  $self->feature->info;
}

1;

__END__

=head1 NAME

Ace::Graphics::Glyph::segments - The "discontinuous segments" glyph

=head1 SYNOPSIS

  See L<Ace::Graphics::Panel> and L<Ace::Graphics::Glyph>.

=head1 DESCRIPTION

This glyph draws a sequence feature that consists of multiple
discontinuous segments, such as the exons on a transcript or a gapped
alignment.  The representation is a series of filled rectangles
connected by line segments.

The features passed to it must either respond to the
Bio::SequenceFeatureI-style subSeqFeatures() method, or the
AcePerl/Das-style segments() or merged_segments() methods.

=head2 OPTIONS

In addition to the common options, this glyph recognizes the
b<-stranded> argument.  If b<-stranded> is true and the feature is an
alignment (has the target() method) then the glyph will draw little
arrows in the segment boxes to indicate the direction of the
alignment.

=head1 BUGS

Please report them.

=head1 SEE ALSO

L<Ace::Sequence>, L<Ace::Sequence::Feature>, L<Ace::Graphics::Panel>,
L<Ace::Graphics::Track>,
L<Ace::Graphics::Glyph::anchored_arrow>,
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
