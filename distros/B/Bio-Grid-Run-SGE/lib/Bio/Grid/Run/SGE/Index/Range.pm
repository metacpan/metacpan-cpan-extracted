package Bio::Grid::Run::SGE::Index::Range;

use Mouse;

use warnings;
use strict;
use Carp;
use Storable qw/retrieve/;
use List::MoreUtils qw/uniq/;

extends 'Bio::Grid::Run::SGE::Index::List';

our $VERSION = '0.042'; # VERSION

around 'create' => sub {
  my $orig  = shift;
  my $self  = shift;
  my $range = shift;

  confess "range has ony 2 numbers" unless ( @$range == 2 );

  my @elements;
  for ( my $i = $range->[0]; $i <= $range->[1]; $i++ ) {
    push @elements, $i;
  }

  return $self->$orig( \@elements );
};

__PACKAGE__->meta->make_immutable;
1;
