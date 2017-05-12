package Bio::Grid::Run::SGE::Iterator::None;

use Mouse;

use warnings;
use strict;

our $VERSION = '0.042'; # VERSION

has cur_comb     => ( is => 'rw', lazy_build => 1 );
has cur_comb_idx => ( is => 'rw', lazy_build => 1 );

with 'Bio::Grid::Run::SGE::Role::Iterable';

sub BUILD {
  my ($self) = @_;

  confess __PACKAGE__ . " can not take any indices"
    if ( $self->indices && @{ $self->indices } > 0 );

  $self->indices( [] );
}

sub next_comb {
  my ($self) = @_;
  

  return if ( $self->cur_comb_idx );
  $self->cur_comb_idx(1);

  return [];

}

sub num_comb { return 1 }

sub start {
  my ($self) = @_;

  $self->cur_comb_idx(0);

  return;
}

sub peek_comb_idx {

  return if ( shift->cur_comb_idx );
  return 0;

}

__PACKAGE__->meta->make_immutable;

1;
