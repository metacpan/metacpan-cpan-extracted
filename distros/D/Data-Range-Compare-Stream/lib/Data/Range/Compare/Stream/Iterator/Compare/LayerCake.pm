package Data::Range::Compare::Stream::Iterator::Compare::LayerCake;


use strict;
use warnings;

use base qw(Data::Range::Compare::Stream::Iterator::Compare::Asc);

sub new {
  my ($class,%args)=@_;
  %args=(ignore_empty=>0,,%args);
  my $self=$class->SUPER::new(%args);

  return $self;
}

sub get_next {
  my ($self)=@_;

  if(defined($self->{filter})) {
    my $result=$self->{next_result};
    delete $self->{next_result};
    return $result;
  }

  if($self->{ignore_full}) {
    my $result=$self->{next_result};
    delete $self->{next_result};
    return $result;
  }

  return $self->SUPER::get_next unless $self->{ignore_empty} or $self->{empty_only};



  my $result=$self->SUPER::get_next;

  while($result->is_empty and $self->has_next) {
    $result=$self->SUPER::get_next;
  }

  return $result;

}

sub prepare  { 
  my ($self)=@_;

  return if $self->prepared;

  $self->SUPER::prepare;
  if(defined($self->{filter})) {
    my $filter=$self->{filter};


    while($self->SUPER::has_next) {
      my $result=$self->SUPER::get_next;
      if($filter->($result)) {
        $self->{next_result}=$result;
	return 1;
      }
    }
    delete $self->{next_result};
    return 0;

  }

}

sub has_next {
  my ($self)=@_;

  $self->prepare;
  
  if(defined($self->{filter})) {
    my $filter=$self->{filter};

    return 1 if defined($self->{next_result});


    while($self->SUPER::has_next) {
      my $result=$self->SUPER::get_next;
      if($filter->($result)) {
        $self->{next_result}=$result;
	return 1;
      }
    }
    delete $self->{next_result};
    return 0;

  } elsif($self->{ignore_full}) {
    return 1 if defined($self->{next_result});

    return 0 unless $self->SUPER::has_next;

    my $result=$self->SUPER::get_next;
    while($result->is_full) {

      return 0 unless $self->SUPER::has_next;
      $result=$self->SUPER::get_next;

    }

    $self->{next_result}=$result;
    return defined($result) ? 1 : 0;

  } else {
    
    # back off and use the parrent class internals
    return $self->SUPER::has_next;
  }


}

1;
