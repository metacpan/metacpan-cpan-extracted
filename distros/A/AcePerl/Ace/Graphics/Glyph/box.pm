package Ace::Graphics::Glyph::box;
# DAS-compatible package to use for drawing a box

use strict;
use vars '@ISA';
@ISA = 'Ace::Graphics::Glyph';

1;

__END__

=head1 NAME

Ace::Graphics::Glyph::box - The "box" glyph

=head1 SYNOPSIS

  See L<Ace::Graphics::Panel> and L<Ace::Graphics::Glyph>.

=head1 DESCRIPTION

This is the most basic glyph.  It draws a filled box and optionally a
label.

=head2 OPTIONS

The following options are standard among all Glyphs.  See individual
glyph pages for more options.

  Option      Description               Default
  ------      -----------               -------

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
