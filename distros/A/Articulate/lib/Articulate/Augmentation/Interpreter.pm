package Articulate::Augmentation::Interpreter;
use strict;
use warnings;

use Moo;
use Articulate::Syntax qw(instantiate instantiate_array);

has default_format => ( is => 'rw', );

has interpreters => (
  is      => 'rw',
  default => sub { {} },
  coerce  => sub {
    my $interpreters = shift;
    foreach my $type ( keys %$interpreters ) {
      $interpreters->{$type} = instantiate_array( $interpreters->{$type} );
    }
    return $interpreters;
  }
);

sub augment {
  my $self   = shift;
  my $item   = shift;
  my $format = $self->default_format;
  foreach my $f ( keys %{ $self->interpreters } ) {
    if ( ( $item->meta->{schema}->{core}->{format} // '' ) eq $f ) {
      $format = $f;
      last;
    }
  }
  foreach my $interpreter ( @{ $self->interpreters->{$format} } ) {
    $interpreter->augment($item);
  }
  return $item;
}

1;
