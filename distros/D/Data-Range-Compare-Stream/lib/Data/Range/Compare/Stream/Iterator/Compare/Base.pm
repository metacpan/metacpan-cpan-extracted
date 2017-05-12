package Data::Range::Compare::Stream::Iterator::Compare::Base;

use strict;
use warnings;
use Carp qw(croak);

use Data::Range::Compare::Stream::Iterator::Compare::Result;
use constant RESULT_CLASS=>'Data::Range::Compare::Stream::Iterator::Compare::Result';

use base qw(Data::Range::Compare::Stream::Iterator::Base);

sub new {
  my ($class,%args)=@_;
  $class->SUPER::new(column_map=>[],root_ids=>[],dead_columns=>[],last_row=>0,iterators_empty=>0,prepared=>0,consolidateors=>[],raw_row=>[],%args);
}

sub on_dead_iterator { 1 }

sub prepared { $_[0]->{prepared} }

sub add_consolidator {
  my ($self,$consolidator)=@_;

  croak "Fatal error, cannot add new objects once the consolidator has been called!!" if $self->prepared;
  push @{$self->{consolidateors}},$consolidator;
  my $id=$#{$self->{consolidateors}};

  $consolidator->set_column_id($id);
  return $id
}

sub insert_consolidator {
  my ($self,$consolidator)=@_;

  push @{$self->{consolidateors}},$consolidator;
  my $id=$#{$self->{consolidateors}};

  $consolidator->set_column_id($id);

  if($self->prepared) {
    croak "cannot insert empty consolidators!" unless $consolidator->has_next;
    $self->{raw_row}->[$id]=$consolidator->get_next;
  }

  return $id;
}

sub get_iterator_by_id {
  my ($self,$id)=@_;
  croak "id out of bounds" if !defined($id) or $id>$#{$_[0]->{consolidateors}} or $id<0;
  return $self->{consolidateors}->[$id];
}
sub get_column_count_human_readable { 1 + $_[0]->get_column_count}

sub get_column_count { $#{$_[0]->{consolidateors}} }

sub get_consolidateors { @{$_[0]->{consolidateors}} }

sub get_current_row { $_[0]->{current_row} } 

sub iterators_empty { $_[0]->{iterators_empty} }


1;
