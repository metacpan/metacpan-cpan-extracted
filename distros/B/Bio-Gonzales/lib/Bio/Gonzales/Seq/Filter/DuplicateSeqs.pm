#Copyright (c) 2010 Joachim Bargsten <code at bargsten dot org>. All rights reserved.

package Bio::Gonzales::Seq::Filter::DuplicateSeqs;

use Mouse;

use warnings;
use strict;
use Carp;
use List::MoreUtils;
use List::Util qw/reduce/;

use 5.010;
our $VERSION = '0.0546'; # VERSION

has namespace => ( is => 'rw' );

has normalizer => ( is => 'rw', default => sub { \&_default_normalizer } );

has _sequence_groups => ( is => 'rw', default => sub { {} } );

=head2 my $is_duplicate = $dseq->add_seq($sequence_object)

Returns 1 if duplicate, else 0

=cut

sub add_seq {
  my ( $self, $so ) = @_;

  my $key = $self->normalizer->($so);

  $self->_sequence_groups->{$key} //= [];
  $so->info->{namespace} = $self->namespace if ( $self->namespace );
  push @{ $self->_sequence_groups->{$key} }, $so;

  return @{ $self->_sequence_groups->{$key} } < 2;
}

sub add_seqs {
  my ( $self, @seq_objs ) = @_;

  return [ map { $self->add_seq($_) } @seq_objs ];
}

sub add_is_unique {
  return shift->add_seq(@_);
}

sub _default_normalizer {
  my ($so) = @_;

  return $so->seq;
}

sub filter_seq {
  my ( $self, $so ) = @_;

  return $self->add_seq($so);
}

sub seq_groups_wo_duplicates {
  my ($self) = @_;

  my @g1 = grep { @{$_} == 1 } values %{ $self->_sequence_groups };

  return \@g1;
}

sub seq_groups_w_duplicates {
  my ($self) = @_;

  my @gn = grep { @{$_} > 1 } values %{ $self->_sequence_groups };

  return \@gn;
}

sub unique_seqs {
  my ($self) = @_;

  my @uniq = map { $_->[0] } values %{ $self->_sequence_groups };

  return \@uniq;
}

sub num_groups_w_duplicates {
  my ($self) = @_;

  return scalar @{ $self->seq_groups_w_duplicates };

}

sub num_duplicate_seqs {
  my ($self) = @_;

  return reduce { $a + @{$b} } ( 0, @{ $self->seq_groups_w_duplicates } );
}

sub all_seqs {
  my ($self) = @_;

  my @seqs;
  map { push @seqs, @{$_} } values %{ $self->_sequence_groups };

  return \@seqs;
}

sub all_seq_groups {
  my ($self) = @_;

  return [ values %{ $self->_sequence_groups } ];
}

1;
