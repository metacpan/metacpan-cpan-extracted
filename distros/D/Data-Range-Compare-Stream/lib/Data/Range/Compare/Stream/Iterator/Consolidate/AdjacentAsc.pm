package Data::Range::Compare::Stream::Iterator::Consolidate::AdjacentAsc;

use strict;
use warnings;
use base qw(Data::Range::Compare::Stream::Iterator::Consolidate);


sub has_next {
  my ($self)=@_;
  return 1 if $self->SUPER::has_next;
  return 1 if defined($self->{last_result});
  return 0;
}

sub get_next {
  my ($self)=@_;
  return undef unless $self->has_next;
  
  my $result;
  if(defined($self->{last_result})) {
    $result=$self->{last_result};
  } elsif($self->SUPER::has_next) {
    $result=$self->SUPER::get_next;
  }

  while($self->has_next) {
    my $last_result;
    if($self->SUPER::has_next) {
      $last_result=$self->SUPER::get_next;
    } else {
      $self->{last_result}=undef;
      return $result;
    }

    
    # get our common result range
    my $common=$result->get_common;
    my $next=$last_result->get_common;

    # stop here if the contiguous check turns up nothing
    
    unless($common->contiguous_check($next)) {
      $self->{last_result}=$last_result;
      return $result 
    }

    # if we got here then we need to get the starting range

    # compute the overlap
    my $overlap=$common->get_overlapping_range([$common,$next]);
    $self->on_consolidate($overlap,$common,$next);

    my ($start,$end)=$common->find_smallest_outer_ranges([$result->get_start->get_common,$result->get_end->get_common,$last_result->get_start->get_common,$last_result->get_end->get_common]);

    # get our new result
    $result=$self->RESULT_CLASS->new($overlap,$start->get_common,$end->get_common,0,1);

    # update the internals
    $self->{last_result}=undef;


  }
  
  $self->{last_result}=undef;
  return $result;
}

1;
