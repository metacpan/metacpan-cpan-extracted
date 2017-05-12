package Data::Range::Compare::Stream::Iterator::Consolidate;

use strict;
use warnings;

use base qw(Data::Range::Compare::Stream::Iterator::Base);
use constant RESULT_CLASS=>'Data::Range::Compare::Stream::Iterator::Consolidate::Result';
use Data::Range::Compare::Stream::Iterator::Consolidate::Result;

sub new {
  my ($class,$iterator,%args)=@_;
  my $self=$class->SUPER::new(iterator=>$iterator,%args);
  return $self;
}

sub has_next {
  my ($self)=@_;
  return 1 if $self->{iterator}->has_next;
  return 1 if defined($self->{last_range});
  return undef;
}


sub get_next {
  my ($self)=@_;

  unless(defined($self->{last_range})) {
    return undef unless $self->{iterator}->has_next;
    $self->{last_range}=$self->{iterator}->get_next;
  }

  my $start_range=$self->{last_range};
  return undef unless defined($start_range);

  my $overlapping_range=$start_range;
  my $end_range=$start_range;
  my $did_overlap=0;

  while($self->{iterator}->has_next) {
    my $next_range=$self->{iterator}->get_next;
    if($overlapping_range->get_common->overlap($next_range->get_common)) {

      $did_overlap=1;
      my $new_range=$overlapping_range->get_overlapping_range([$overlapping_range->get_common,$next_range->get_common]);
      $self->on_consolidate($new_range->get_common,$overlapping_range->get_common,$next_range->get_common);
      $overlapping_range=$new_range->get_common;


      ($start_range,$end_range)=$overlapping_range->get_common->find_smallest_outer_ranges([$start_range->get_common,$end_range->get_common,$next_range->get_common]);
    } else {
      $self->{last_range}=$next_range;
      my ($start,$end)=$start_range->get_common->find_smallest_outer_ranges([$start_range->get_common,$end_range->get_common]);
      return $self->RESULT_CLASS->new($overlapping_range->get_common,$start->get_common,$end->get_common,0,$did_overlap);
    }

    
  }
  $self->{last_range}=undef;
  my ($start,$end)=$start_range->get_common->find_smallest_outer_ranges([$start_range->get_common,$end_range->get_common]);
  return $self->RESULT_CLASS->new($overlapping_range->get_common,$start->get_common,$end->get_common,0,$did_overlap);
}

1;

