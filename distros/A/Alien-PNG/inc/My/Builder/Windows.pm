package My::Builder::Windows;

use strict;
use warnings;
use base 'My::Builder';

sub can_build_binaries_from_sources {
  my $self = shift;
  return 0; # no
}

sub build_binaries {
  my( $self, $build_out, $build_src ) = @_;
  die "###ERROR### Building from sources not supported on MS Windows platform";
}

sub get_path {
  my ( $self, $path ) = @_;
  $path = '"' . $path . '"';
  return $path;
}

1;
