package Ace::Graphics::Glyph::dot;
# DAS-compatible package to use for drawing a ring or filled circle

use strict;
use vars '@ISA';
@ISA = 'Ace::Graphics::Glyph';

sub draw {
  my $self = shift;
#  $self->SUPER::draw(@_);
  my $gd = shift;
  my $fg = $self->fgcolor;

  # now draw a circle
  my ($x1,$y1,$x2,$y2) = $self->calculate_boundaries(@_);
  my $fg = $self->fgcolor;
  my $xmid   = (($x1+$x2)/2);  my $width  = abs($x2-$x1);
  my $ymid   = (($y1+$y2)/2);  my $height = abs($y2-$y1);

  if ($self->option('point')){
    my $p = $self->option('point');
    $gd->arc($xmid,$ymid,$p*2,$p*2,0,360,$fg);
  } else {
    $gd->arc($xmid,$ymid,$width,$height,0,360,$fg);
  }



  if ($self->option('fillcolor')){
    my $c = $self->color('fillcolor');
    $gd->fill($xmid,$ymid,$c);
  }

  $self->draw_label($gd,@_) if $self->option('label');
}

1;

__END__

=head1 NAME

Ace::Graphics::Glyph::dot - The "ellipse" glyph

=head1 SYNOPSIS

  See L<Ace::Graphics::Panel> and L<Ace::Graphics::Glyph>.

=head1 DESCRIPTION

This glyph draws an ellipse the width of the scaled feature passed,
and height a possibly configured height (See Ace::Graphics::Glyph).

=head2 OPTIONS

In addition to the common options, the following glyph-specific
options are recognized:
  Option      Description                  Default
  ------      -----------                  -------

  -point      Whether to draw an ellipse   feature width
              the scaled width of the
              feature or with radius
              point.

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

Allen Day <day@cshl.org>.

Copyright (c) 2001 Cold Spring Harbor Laboratory

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut
