package Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn;

use strict;
use warnings;
use Carp qw(croak);

use base qw(Data::Range::Compare::Stream::Iterator::Consolidate);
use Data::Range::Compare::Stream::Iterator::Array;

use constant NEW_ARRAY_ITERATOR_FROM=>'Data::Range::Compare::Stream::Iterator::Array';
use constant NEW_CHILD_CONSOLIDATOR_FROM=>'Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn';

sub new {
  my ($class,$it,$cmp,%args)=@_;
  croak('Required Arguments are: $iterator,$compare') unless defined($cmp);
  my $self=$class->SUPER::new($it,compare=>$cmp,buffer=>[],%args);
  return $self;
}

sub get_child { $_[0]->{consolidator} }

sub delete_from_root {
  my ($self)=@_;
  if($self->has_child) {
    my $child=$self->get_child;
    delete $child->{root_iterator};
  }
  if($self->is_child) {
    my $root=$self->get_root;
    delete @{$root}{qw(iterator_array consolidator)};
  }
}

sub get_child_column_id {
  my ($self)=@_;
  return undef unless $self->has_child;
  $self->get_child->get_column_id;
}

sub on_consolidate {
  my ($self,$new_range,$last_range,$next_range)=@_;

  my $cmp=$self->{compare};
  my $iterator;

  if(defined($self->{iterator_array})) { 
     $iterator=$self->{iterator_array};
     $iterator->insert_range($next_range);
  } else {
     $iterator=$self->{iterator_array}=$self->NEW_ARRAY_ITERATOR_FROM->new(sorted=>1);
     $iterator->insert_range($next_range);
     my $consolidator=$self->{consolidator}=$self->NEW_CHILD_CONSOLIDATOR_FROM->new($iterator,$cmp);
     $consolidator->{root_iterator}=$self;
  }

}

sub get_root_column_id {
  my ($self)=@_;
  return $self->get_root->get_column_id if $self->is_child;
  $self->get_column_id
}

sub is_child { defined($_[0]->{root_iterator}) }

sub is_root { !$_[0]->is_child }
sub has_child { defined($_[0]->{iterator_array}) }
sub has_root { defined($_[0]->get_root)}

sub get_compare { $_[0]->{compare} }

sub get_root { 
  my ($self)=@_;
  $self->{root_iterator};
}

sub has_next {
  my ($self)=@_;

  return 1 if $#{$self->{buffer}}!=-1;
  return 1 if $self->SUPER::has_next;

  if($self->is_child) {
    my $cmp=$self->get_compare;
    my $root=$self->get_root;
    if($root->SUPER::has_next) {
      $root->push_to_buffer;
      return 1 if $#{$self->{buffer}}!=-1;
    }
  }
  return 0;
}

sub get_current_result { $_[0]->{current_result} }

sub get_next {
  my ($self)=@_;

  if($#{$self->{buffer}}==-1 and $self->SUPER::has_next) {
    $self->push_to_buffer;
  }
  my $result=shift @{$self->{buffer}};
  $self->{current_result}=$result;
  return $result;

}

sub buffer_count { 1 + $#{$_[0]->{buffer}} } 

sub get_buffer { $_[0]->{buffer} }

sub iterator_has_next { $_[0]->{iterator}->has_next }

sub push_to_buffer {
  my ($self)=@_;

  my $overlapping_range;
  if(defined($self->{last_range})) {
    $overlapping_range=$self->{last_range};
    $self->{last_range}=undef;
  } else {
    $overlapping_range=$self->{iterator}->get_next;
    $self->{last_range}=$overlapping_range;
  }
  return 0 unless defined($overlapping_range);

  my $result=$overlapping_range;
  my $pushed_to_child=0;
  if($self->iterator_has_next) {
    OVERLAP_CHECK: while($self->iterator_has_next) {
  
      my $next_range=$self->{iterator}->get_next;
  
      if($overlapping_range->overlap($next_range)) {
  
        $overlapping_range=$overlapping_range->get_overlapping_range([$overlapping_range,$next_range]);
        $self->on_consolidate($overlapping_range,$result,$next_range);
        $pushed_to_child++;
        $self->{last_range}=undef;
  
      } else {
  
        $self->{last_range}=$next_range;
        last OVERLAP_CHECK;
  
      }
    }
  } else {
      $self->{last_range}=undef;
  }

  if($pushed_to_child) {
    my $child=$self->get_child;
    $child->push_to_buffer;
    $self->{compare}->insert_consolidator($child) unless defined($child->get_column_id);
  }


  push @{$self->{buffer}},$self->RESULT_CLASS->new($result,$result,$result); 
  return 1;
}

1;
