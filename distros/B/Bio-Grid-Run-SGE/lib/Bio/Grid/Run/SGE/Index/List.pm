package Bio::Grid::Run::SGE::Index::List;

use Mouse;

use warnings;
use strict;
use Carp;
use Storable qw/retrieve/;
use List::MoreUtils qw/uniq/;

with 'Bio::Grid::Run::SGE::Role::Indexable';

our $VERSION = '0.064'; # VERSION

sub BUILD {
  my ($self) = @_;

  confess "index file not set"
    unless ( $self->idx_file );
  if ( -f $self->idx_file ) {
    $self->_load_index;
  }
  # always reindex list based indices. Lists can easily change
  # and it is not straight forward to check changes
  $self->_reindexing_necessary(1);

  return $self;
}

before 'create' => sub {
  my $self = shift;

  $self->log->info("SKIPPING INDEXING STEP, THE INDEX IS UP TO DATE")
    if ( $self->_is_indexed );

  $self->_check_writable;

  $self->log->info("INDEXING ....");
};

sub create {
  my ( $self, $elements ) = @_;

  return $self if ( $self->_is_indexed );

  my $chunk_size = $self->chunk_size;

  my @current_chunk;
  my $chunk_elem_count = 0;
  my @idx;

  for my $e (@$elements) {
    if ( $chunk_elem_count && $chunk_elem_count % $chunk_size == 0 ) {
      $chunk_elem_count = 0;

      push @idx, [@current_chunk];
      undef @current_chunk;
    }
    push @current_chunk, $e;
    $chunk_elem_count++;

  }

  push @idx, [@current_chunk] if ( @current_chunk && @current_chunk > 0 );

  $self->idx( \@idx );

  $self->_store;
  return $self;
}

sub _check_writable {
  my $self = shift;
  confess 'No write permission, set write_flag to write' unless ( $self->writeable );

}

sub _is_indexed {
  my ($self) = @_;

  return if ( $self->_reindexing_necessary );
  return unless ( @{ $self->idx } > 0 && -f $self->idx_file );

  return 1;
}

sub num_elem {
  my ($self) = @_;

  return scalar @{ $self->idx };
}

sub get_elem {
  my ( $self, $elem_idx ) = @_;
  my $idx = $self->idx;

  return $idx->[$elem_idx];
}

sub type {
  return 'direct';
}

sub close { }

__PACKAGE__->meta->make_immutable;
1;
