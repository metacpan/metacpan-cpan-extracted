package Data::Range::Compare::Stream::Iterator::Array;

use strict;
use warnings;
use Carp qw(croak);
use base qw(Data::Range::Compare::Stream::Iterator::Base);
use Data::Range::Compare::Stream::Sort;

sub new {
  my ($class,%args)=@_;

  my $self=$class->SUPER::new(qw(
    sorted            0 
    new_from          Data::Range::Compare::Stream 
    ),
    range_list=>[],%args
  );

  return $self;
}

sub set_sorted { $_[0]->{sorted}=$_[1] }

sub sorted { $_[0]->{sorted} }

sub prepared { $_[0]->{prepared} }

sub prepare {
  my ($self)=@_;
  return 1 if $self->prepared;

  $self->{prepared}=1;
  return 1 if $self->sorted;
  return 1 unless $self->{autosort};
  return unless $self->can($self->{autosort});
  my $func=$self->{autosort};
  $self->$func();
}

sub has_next { 
  my ($self)=@_;
  $self->prepare unless $self->prepared;
  return undef unless $self->sorted;
  return $#{$self->{range_list}}!=-1
}

sub add_range {
  my ($self,$range)=@_;
  croak "Object: [$self] has all ready been sorted" if $self->sorted;
  push @{$self->{range_list}},$range;
}

sub insert_range {
  my ($self,$range)=@_;
  push @{$self->{range_list}},$range;
}

sub create_range {
  my ($self,@args)=@_;
  croak "Object: [$self] has all ready been sorted" if $self->sorted;
  $self->add_range($self->create_from_factory(@args));
}

sub get_next {
  my ($self)=@_;
  croak "Object: [$self] has not been sorted" unless $self->sorted;
  shift @{$self->{range_list}}
}

sub prepare_for_consolidate_asc { 
  my ($self)=@_;
  return 0 if $self->sorted;
  $self->set_sorted(1);
  @{$self->{range_list}}=sort sort_in_consolidate_order_asc @{$self->{range_list}};
  1;
}

sub prepare_for_consolidate_desc { 
  my ($self)=@_;
  return 0 if $self->sorted;
  $self->set_sorted(1);
  @{$self->{range_list}}=sort sort_in_consolidate_order_desc @{$self->{range_list}};
  1;
}

1;
