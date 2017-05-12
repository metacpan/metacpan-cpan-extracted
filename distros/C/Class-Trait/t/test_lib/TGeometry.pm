
use strict;
use warnings;

package TGeometry;

use Class::Trait 'base';

our @REQUIRES = qw(
  getCenter
  setCenter
  getRadius
  setRadius
);

sub area {
    my ($self) = @_;

    # ...
}

sub bounds {
    my ($self) = @_;

    # ...
}

sub diameter {
    my ($self) = @_;

    # ...
}

sub scaleBy {
    my ( $self, $magnitude ) = @_;

    # ...
}

1;

__DATA__
