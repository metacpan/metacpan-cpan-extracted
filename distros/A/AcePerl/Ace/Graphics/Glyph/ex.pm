package Ace::Graphics::Glyph::ex;
# DAS-compatible package to use for drawing an "X"

use strict;
use vars '@ISA';
@ISA = 'Ace::Graphics::Glyph';

sub draw {
  my $self = shift;
  my $gd = shift;
  my $fg = $self->fgcolor;

  # now draw a cross
  my ($x1,$y1,$x2,$y2) = $self->calculate_boundaries(@_);
  my $fg = $self->fgcolor;

  if ($self->option('point')){
    my $p = $self->option('point');
    my $xmid = ($x1+$x2)/2;
    my $ymid = ($y1+$y2)/2;
    $gd->line($xmid-$p,$ymid-$p,$xmid+$p,$ymid+$p,$fg);
    $gd->line($xmid-$p,$ymid+$p,$xmid+$p,$ymid-$p,$fg);
  } else {
    $gd->line($x1,$y1,$x2,$y2,$fg);
    $gd->line($x1,$y2,$x2,$y1,$fg);
  }

  $self->draw_label($gd,@_) if $self->option('label');
}

1;

__END__

=head1 NAME

Ace::Graphics::Glyph::ex - The "X" glyph

=head1 SYNOPSIS

  See L<Ace::Graphics::Panel> and L<Ace::Graphics::Glyph>.

=head1 DESCRIPTION

This glyph draws an "X".

=head2 OPTIONS

In addition to the common options, the following glyph-specific
options are recognized:
  Option      Description                  Default
  ------      -----------                  -------

  -point      Whether to draw an "X" the   feature width
              scaled width of the feature
              or with arm length point.

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
