package Ace::Graphics::Glyph::toomany;
# DAS-compatible package to use for drawing a box

use strict;
use vars '@ISA';
@ISA = 'Ace::Graphics::Glyph';

# draw the thing onto a canvas
# this definitely gets overridden
sub draw {
  my $self = shift;
  my $gd   = shift;
  my ($left,$top) = @_;
  my ($x1,$y1,$x2,$y2) = $self->calculate_boundaries($left,$top);

  $self->filled_oval($gd,$x1,$y1,$x2,$y2);

  # add a label if requested
  $self->draw_label($gd,@_) if $self->option('label');
}

sub label {
  return "too many to display";
}

1;

__END__

=head1 NAME

Ace::Graphics::Glyph::toomany - The "too many to show" glyph

=head1 SYNOPSIS

  See L<Ace::Graphics::Panel> and L<Ace::Graphics::Glyph>.

=head1 DESCRIPTION

This glyph is intended for features that are too dense to show
properly.  Mostly a placeholder, it currently shows a filled oval.  If
you choose a bump of 0, the ovals will overlap, to give a cloud
effect.

=head2 OPTIONS

There are no glyph-specific options.

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
