package Data::Range::Compare::Stream::Iterator::Compare::Asc;

use strict;
use warnings;
use base qw(Data::Range::Compare::Stream::Iterator::Compare::Base);
use Carp qw(croak);

sub has_next {
  my ($self)=@_;
  $self->prepare unless $self->prepared;
  $self->{has_next};
}

sub prepare {
  my ($self,%args)=@_;
  return undef if $self->prepared;
  
  my $min_range_start;
  my $min_range_end;
  my $iterators_has_next_count;
  my $min_range_start_column_id=0;

  for(my $id=0;$id<$self->get_column_count_human_readable;++$id)  {

    my $iterator=$self->{consolidateors}->[$id];

    unless($iterator->has_next) {
      $self->{has_next}=0;
      return undef;
    }
    my $raw_range=$iterator->get_next;

    push @{$self->{raw_row}},$raw_range;
    push @{$self->{last_column_value}},$raw_range->get_common;
    if(defined($min_range_start)) {
      my $common_raw=$raw_range->get_common;
      my $common_start=$min_range_start->get_common;
      my $common_end=$min_range_end->get_common;
      if($common_raw->cmp_range_start($common_start)==-1) {
        $min_range_start=$raw_range;
        $min_range_start_column_id=$id;
      }
      if($common_raw->cmp_range_end($common_end)==-1) {
       $min_range_end=$raw_range;
        $min_range_start_column_id=$id;
      }
    } else {
     $min_range_start=$raw_range;
     $min_range_end=$raw_range;
    }
    ++$iterators_has_next_count if $iterator->has_next;
  }

  $self->{iterators_empty}=!$iterators_has_next_count;

  my $next_range=$self->create_from_factory($min_range_start->get_common->range_start,$min_range_end->get_common->range_end);
  $next_range->on_create_range($min_range_start->get_common->range_start);

  for(my $id=0;$id<$self->get_column_count_human_readable;++$id)  {
    # stop here if this is the column started on
    
    my $cmp=$self->{raw_row}->[$id]->get_common;
    my $cmp_end=$cmp->previous_range_end;

    if($next_range->contains_value($cmp_end)) {
      if($next_range->cmp_values($next_range->range_end,$cmp_end)==1){
        my $old_next_range=$next_range;
        $next_range=$self->create_from_factory($next_range->range_start,$cmp_end);
	$next_range->on_create_range($old_next_range);
      }
    }

  }

  $self->{has_next}=1;
  $self->{current_row}=$next_range;
  $self->{processed_ranges}=1;

  $self->{prepared}=1;
  1;
}

sub iterator_in_use {
  my ($self,$id)=@_;
  croak "id lt 0" if $id<0;
  croak "id gt max" if $id>$self->get_column_count; 
  my $raw=$self->{raw_row}->[$id]->get_common;
  my $current=$self->get_current_row;

  return 1 if $raw->overlap($current);
  return $raw->cmp_range_end($current)!=-1;
}

sub iterator_is_dead {
  my ($self,$id)=@_;
  croak 'column id out of bounds' if !defined($id) or $id < 0 or $id > $#{$self->{raw_row}};
  $self->{dead_columns}->[$id]
}

sub delete_iterator {
  my ($self,$id)=@_;
  
  croak 'cannot delete an iterator while its results are in use' if $self->iterator_in_use($id);

  # odds are these objects are in use, so we need to create new ones
  $self->{column_map}=[];
  $self->{root_ids}=[];

  my $con=$self->get_iterator_by_id($id);

  splice(@{$self->{dead_columns}},$id,1);
  splice(@{$self->{raw_row}},$id,1);
  splice(@{$self->{consolidateors}},$id,1);

  $con->delete_from_root;
  
}

sub get_raw_result {
  my ($self,$id)=@_;
  croak 'column id out of bounds' if !defined($id) or $id < 0 or $id > $#{$self->{raw_row}};
  $self->{raw_row}->[$id]
}

sub set_raw_result {
  my ($self,$id,$raw_result)=@_;
  croak 'column id out of bounds' if !defined($id) or $id < 0 or $id > $#{$self->{raw_row}};
  croak 'raw_result not defined' unless defined($raw_result);
  $self->{raw_row}->[$id]=$raw_result;
}

sub get_next {
  my ($self)=@_;

  $self->prepare unless $self->prepared;
  # get the current row
  my $current_row=$self->get_current_row;
  croak "Fatal: get_next called befor has_next or after the iterator set is empty" unless defined($current_row);

  my $result=[];

  my $next_range_start=$current_row->next_range_start;
  my $iterators_has_next_count;
  my $max_range_end;

  my $overlap_count=0;
  my $overlap_ids=[];
  my $non_overlap_ids=[];
  my $created_range=0;
  my $next_range;
  my $dead_columns=$self->{dead_columns};
  my $column_map=$self->{column_map};
  my $root_ids=$self->{root_ids};

  GET_ROW_LOOP: for(my $id=0;$id<$self->get_column_count_human_readable;++$id)  {
    
    my $iterator=$self->{consolidateors}->[$id];
    if($#$column_map<$id) {
      $iterator->set_column_id($id);

      if($iterator->is_child) {
        my $walk=$iterator;
	while($walk->is_child) {
	  $walk=$self->get_iterator_by_id($walk->get_root_column_id);
	}
        $column_map->[$id]=$walk->get_column_id;
      } else {
        $column_map->[$id]=$id;
        push @$root_ids,$id;
      }
    }

    if($dead_columns->[$id] and !$iterator->has_next) {
      push @$non_overlap_ids,$id;
      push @$result,undef;
      next GET_ROW_LOOP;
    }

    # Objects we will use throught the loop
    my $raw_range=$self->{raw_row}->[$id];
    my $cmp=$raw_range->get_common;

    my $is_dead=0;


    # current row computations
    if($current_row->overlap($cmp)) {
      push @$result,$raw_range;
      ++$overlap_count;
      push @$overlap_ids,$id;
    } else {
      push @$result,undef;
      if($current_row->cmp_range_end($cmp)==1) {
        ++$is_dead 
      }
      push @$non_overlap_ids,$id;
    }

    if($cmp->cmp_ranges($current_row)==0 or $cmp->cmp_range_end($current_row)==0) {
      if($iterator->has_next) {
        my $next_range=$iterator->get_next;

        $raw_range=$next_range;
	$cmp=$raw_range->get_common;
        $self->{raw_row}->[$id]=$next_range;
      }
    } 

    if($iterator->has_next) {
      ++$iterators_has_next_count;
    } else {
      ++$is_dead;
    }

    if(defined($next_range)) {
      my $cmp_end=$cmp->previous_range_end;

      if($next_range->contains_value($cmp_end)) {

        if($next_range->cmp_values($next_range->range_end,$cmp_end)!=-1){
	  
          my $old_next_range=$next_range;
          $next_range=$self->create_from_factory($next_range->range_start,$cmp_end);
	  $next_range->on_create_range($old_next_range);

        }

      } elsif($next_range->cmp_range_end($cmp)==1 and $cmp->cmp_values($next_range_start,$cmp->range_end)!=1) {

          my $old_next_range=$next_range;
      
          $next_range=$self->create_from_factory($next_range->range_start,$cmp->range_end);
	  $next_range->on_create_range($old_next_range);

      }
    } else {

      my $cmp_end=$cmp->previous_range_end;

      if($cmp->cmp_values($next_range_start,$cmp_end)!=1) {

          my $old_next_range=$next_range;

          $next_range=$self->create_from_factory($next_range_start,$cmp_end);
	  $next_range->on_create_range($old_next_range);

      } elsif($cmp->cmp_values($next_range_start,$cmp->range_end)!=1) {

          my $old_next_range=$next_range;

          $next_range=$self->create_from_factory($next_range_start,$cmp->range_end);
	  $next_range->on_create_range($old_next_range);

      }
    
    }
    
    if(defined($max_range_end)) {
      $max_range_end=$cmp if $max_range_end->cmp_range_end($cmp)==-1;
    } else {
      $max_range_end=$cmp;
    }
    if($is_dead==2) {
      $dead_columns->[$id]=$self->on_dead_iterator($id);
    } else {
      $dead_columns->[$id]=0;
    }
  }

  $self->{iterators_empty}=!$iterators_has_next_count;

  if($self->{last_row}) {
    $self->{has_next}=0;
  } else {

    unless(defined($next_range)) {
      $next_range=$self->create_from_factory($next_range_start,$next_range_start);
      $next_range->on_create_range($current_row);
    }

    $self->{current_row}=$next_range;
    $self->{last_row}=($self->{iterators_empty} and $next_range->cmp_range_end($max_range_end)!=-1);
  }

  my $obj=$self->RESULT_CLASS->new(
    $current_row,
    $result,
    $overlap_count,
    $overlap_ids,
    $non_overlap_ids,
    $column_map,
    $root_ids,
  );
  return $obj;
}

1;
