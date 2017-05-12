package Ace::Graphics::Glyph::graded_segments;
# package to use for drawing anything that is interrupted
# (has the segment() method) and that has a score associated
# with each segment

use strict;
use vars '@ISA';
use GD;
use Ace::Graphics::Glyph::segments;
@ISA = 'Ace::Graphics::Glyph::segments';

# override draw method
sub draw {
  my $self = shift;

  # bail out if this isn't the right kind of feature
  # handle both das-style and Bio::SeqFeatureI style,
  # which use different names for subparts.
  my @segments;
  my $f = $self->feature;
  if ($f->can('segments')) {
    @segments = $f->segments;

  } elsif ($f->can('sub_SeqFeature')) {
    @segments = $f->sub_SeqFeature;

  } else {
    return $self->SUPER::draw(@_);
  }

  # figure out the colors
  my $max_score = $self->option('max_score');
  unless ($max_score) {
    $max_score = 0;
    foreach (@segments) {
      my $s = eval { $_->score };
      $max_score = $s if $s > $max_score;
    }
  }

  # allocate colors
  my $fill   = $self->fillcolor;
  my %segcolors;
  my ($red,$green,$blue) = $self->factory->rgb($fill);
  foreach (sort {$a->start <=> $b->start} @segments) {
    my $s = eval { $_->score };
    unless (defined $s) {
      $segcolors{$_} = $fill;
      next;
    }
    my($r,$g,$b) = map {(255 - (255-$_) * ($s/$max_score))} ($red,$green,$blue);
    my $idx      = $self->factory->translate($r,$g,$b);
    $segcolors{$_} = $idx;
  }

  # get parameters
  my $gd = shift;
  my ($x1,$y1,$x2,$y2) = $self->calculate_boundaries(@_);
  my ($left,$top) = @_;

  my (@boxes,@skips);

  for (my $i=0; $i < @segments; $i++) {
    my $color = $segcolors{$segments[$i]};

    my ($start,$stop) = ($left + $self->map_pt($segments[$i]->start),
			 $left + $self->map_pt($segments[$i]->end));

    # probably unnecessary, but we do it out of paranaoia
    ($start,$stop) = ($stop,$start) if $start > $stop;

    push @boxes,[$start,$stop,$color];

    if (my $next_segment = $segments[$i+1]) {
      my ($next_start,$next_stop) = ($left + $self->map_pt($next_segment->start),
				     $left + $self->map_pt($next_segment->end));
      # probably unnecessary, but we do it out of paranaoia
      ($next_start,$next_stop) = ($next_stop,$next_start) if $next_start > $next_stop;
      push @skips,[$stop+1,$next_start-1];
    }
  }

  my $fg     = $self->fgcolor;
  my $center = ($y1 + $y2)/2;

  # each skip becomes a simple line
  for my $i (@skips) {
    next unless $i->[1] - $i->[0] >= 1;
    $gd->line($i->[0],$center,$i->[1],$center,$fg);
  }

  # each segment becomes a box
  for my $e (@boxes) {
    my @rect = ($e->[0],$y1,$e->[1],$y2);
    my $color = $e->[2];
    $gd->filledRectangle(@rect,$color);
  }

  # draw label
  $self->draw_label($gd,@_) if $self->option('label');
}
1;

__END__

=head1 NAME

Ace::Graphics::Glyph::graded_segments - The "color-coded segments" glyph

=head1 SYNOPSIS

  See L<Ace::Graphics::Glyph::segments>, L<Ace::Graphics::Panel> and L<Ace::Graphics::Glyph>.

=head1 DESCRIPTION

This is identical to the segments glyph, except that the intensity of
each segment is proportional to the score of the segment.  The maximum
score is taken from the configuration variable max_score.  If not
provided, the maximum-scoring segment will be used.

=head2 OPTIONS

In addition to the common options, this glyph recognizes the
b<-max_score> argument.

=head1 BUGS

Although descended from the segments glyph, this glyph cannot show the
orientation of the segment.

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
