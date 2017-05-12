package Ace::Graphics::Glyph::crossbox;

use strict;
use vars '@ISA';
@ISA = 'Ace::Graphics::Glyph';

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

1;
