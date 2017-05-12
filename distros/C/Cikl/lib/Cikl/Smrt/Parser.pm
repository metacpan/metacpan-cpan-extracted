package Cikl::Smrt::Parser;

use strict;
use warnings;
use Scalar::Util qw(blessed);
use Cikl::Models::Event;
use Mouse;

use namespace::autoclean;

has 'config' => (
  is => 'ro',
  required => 1
);

sub name {
  my $class = shift;
  die("$class has not implemented the name() method!");
}

sub parse {
  my $self = shift;

  return(blessed($self) . " has not implemented the parser() method!");
}

__PACKAGE__->meta->make_immutable;

1;
