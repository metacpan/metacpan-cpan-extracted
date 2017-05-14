package Bio::Gonzales::Graphics::Glyph::colorfulBox;
# DAS-compatible package to use for drawing a box

use strict;
use base qw(Bio::Graphics::Glyph::generic);

our $VERSION = '0.0546'; # VERSION

sub my_description {
    return <<END;
This glyph draws genomic features as rectangles. If the feature
contains subfeatures, then the glyph will draw a single solid box that
spans all the subfeatures.  Features can be named with a label at the
top, and annotated with a descriptive string at the bottom.
END
}

sub fgcolor {
  my $self  = shift;

  my $fgcolor = $self->option('color') || $self->option('fgcolor');

  $fgcolor = $fgcolor->() if(ref $fgcolor eq 'CODE');

}
