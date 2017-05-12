package Ace::Graphics::Glyph::line;
# an arrow without the arrowheads

use strict;
use vars '@ISA';
@ISA = 'Ace::Graphics::Glyph';

sub bottom {
  my $self = shift;
  my $val = $self->SUPER::bottom(@_);
  $val += $self->font->height if $self->option('tick');
  $val += $self->labelheight if $self->option('label');
  $val;
}

sub draw {
  my $self = shift;
  my $gd = shift;
  my ($x1,$y1,$x2,$y2) = $self->calculate_boundaries(@_);

  my $fg = $self->fgcolor;
  my $a2 = $self->SUPER::height/2;
  my $center = $y1+$a2;

  $gd->line($x1,$center,$x2,$center,$fg);
  # add a label if requested
  $self->draw_label($gd,@_) if $self->option('label');

}

1;

__END__

=head1 NAME

Ace::Graphics::Glyph::line - The "line" glyph

=head1 SYNOPSIS

  See L<Ace::Graphics::Panel> and L<Ace::Graphics::Glyph>.

=head1 DESCRIPTION

This glyph draws a line parallel to the sequence segment.

=head2 OPTIONS

This glyph takes only the standard options.

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
