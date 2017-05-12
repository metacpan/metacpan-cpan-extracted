package Data::Range::Compare::Stream::Iterator::Consolidate::FillMissing;

use strict;
use warnings;

use base qw(Data::Range::Compare::Stream::Iterator::Base);
use Data::Range::Compare::Stream::Iterator::Consolidate::Result;
use Carp qw(croak);

use constant NEW_RESULT_FROM=>'Data::Range::Compare::Stream::Iterator::Consolidate::Result';

sub new {
  my ($class,$con,%args)=@_;
  croak 'Consolidator object must be defined' unless defined($con);
  
  $class->SUPER::new(con=>$con,%args);
}

sub has_next {
  my ($self)=@_;
  return 1 if $self->{con}->has_next;
  return 1 if defined($self->{missing_result});
  return 1 if defined($self->{last_result_obj});
  return 0;
}

sub get_next {
  my ($self)=@_;
  my $it=$self->{con};
  
  my $last_result;
  if(defined($self->{missing_result})) {
    my $result=$self->{missing_result};
    $self->{missing_result}=undef;
    return $result;
  } elsif(defined($self->{last_result_obj})) {
    $last_result=$self->{last_result_obj};
    $self->{last_result_obj}=undef;
  } else {
    if($it->has_next) {
      $last_result=$it->get_next;
    } else {
      croak 'iterator called when has_next is false!';
    }
  }

  if($it->has_next) {
    my $result=$it->get_next;
    if($last_result->get_common->contiguous_check($result->get_common)) {
      $self->{last_result_obj}=$result;
      return $last_result;
    } else {
      $self->{last_result_obj}=$result;
      my $new_result=$self->create_from_factory($last_result->get_common->next_range_start,$result->get_common->previous_range_end);
      $new_result->get_common->on_create_range($last_result->get_common);
      $self->{missing_result}=$self->NEW_RESULT_FROM->new($new_result,$new_result,$new_result,1,1);

      return $last_result;
    }
  } else {
    return $last_result;
  }
}


1;
