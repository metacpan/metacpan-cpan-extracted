package Data::Range::Compare::Stream;

use strict;
use warnings;

use base qw(Data::Range::Compare::Stream::Result::Base Data::Range::Compare::Stream::Constants);

use constant NEW_FROM_CLASS=>'Data::Range::Compare::Stream';

our $VERSION='4.030';

sub factory {
  my ($self,@args)=@_;
  my $new=$self->NEW_FROM_CLASS->new(@args);
  return $new;
}

sub to_string {
  my $notation=join ' - ',$_[0]->range_start_to_string,$_[0]->range_end_to_string;
  $notation;
}

sub range_start () { $_[0]->[$_[0]->RANGE_START] }
sub range_end () { $_[0]->[$_[0]->RANGE_END] }

sub range_start_to_string () { $_[0]->range_start }
sub range_end_to_string () { $_[0]->range_end }

sub on_create_range { }

sub add_one ($) {
  my ($self,$value)=@_;
  $value + 1;
}

sub sub_one ($) {
  my ($self,$value)=@_;
  $value - 1;
}

sub cmp_values ($$) {
  my ($self,$value_a,$value_b)=@_;
  $value_a <=> $value_b
}

sub next_range_start () { $_[0]->add_one($_[0]->range_end)  }

sub previous_range_end () { $_[0]->sub_one($_[0]->range_start)  }

sub data {
  my ($self,$data)=@_;
  return $self->[$self->RANGE_DATA] unless defined($data);
  $self->[$self->RANGE_DATA]=$data;
}

sub get_common_range ($) {
  my ($class,$ranges)=@_;

  my ($range_start,$range_end)=@{$ranges}[0,0];

  for( my $x=1;$x<=$#$ranges;++$x) {
    $range_start=$ranges->[$x] if $class->cmp_values($range_start->range_start,$ranges->[$x]->range_start)==-1;
    $range_end=$ranges->[$x] if $class->cmp_values($range_end->range_end,$ranges->[$x]->range_end)==1;
  }

  my $new_range=$class->factory($range_start->range_start,$range_end->range_end);

  $new_range->on_create_range($range_start);

  $new_range;
}

sub find_smallest_outer_ranges {
  my ($self,$ref)=@_;
  my $start=$ref->[0];
  my $end=$ref->[0];

  foreach my $range (@$ref) {
    {
      my $cmp=$start->cmp_range_start($range);
      if($cmp==1) {
        $start=$range;
      } elsif($cmp==0 && $start->cmp_range_end($range)==1) {
        $start=$range;
      }
    }
    {
      my $cmp=$end->cmp_range_end($range);
      if($cmp==-1) {
        $end=$range;
      } elsif($cmp==0 && $end->cmp_range_start($range)==-1) {
        $end=$range;
      }
    }
  }
  return ($start,$end);
}

sub get_overlapping_range ($) {
  my ($class,$ranges)=@_;

  my ($range_start,$range_end)=@{$ranges}[0,0];

  for( my $x=1;$x<=$#$ranges;++$x) {
    $range_start=$ranges->[$x] if $class->cmp_values($range_start->range_start,$ranges->[$x]->range_start)==1;
    $range_end=$ranges->[$x] if $class->cmp_values($range_end->range_end,$ranges->[$x]->range_end)==-1;
  }

  my $new_range=$class->factory($range_start->range_start,$range_end->range_end);
  $new_range->on_create_range($range_start);
  $new_range;
}


sub cmp_range_start($) {
  my ($self,$cmp)=@_;
  $self->cmp_values($self->range_start,$cmp->range_start)
}

sub cmp_range_end($) {
  my ($self,$cmp)=@_;
  $self->cmp_values($self->range_end,$cmp->range_end)
}

sub cmp_range_start_to_range_end ($) {
  my ($self,$cmp)=@_;
  $self->cmp_values($self->range_start,$cmp->range_end)
}


sub contains_value ($) {
  my ($self,$cmp)=@_;
  return 0 if $self->cmp_values($self->range_start,$cmp)==1;
  return 0 if $self->cmp_values($cmp,$self->range_end)==1;
  1
}

sub contiguous_check ($) {
  my ($cmp_a,$cmp_b)=@_;
  $cmp_a->cmp_values(
   $cmp_a->next_range_start
   ,$cmp_b->range_start
  )==0
}

sub cmp_ranges ($) {
  my ($range_a,$range_b)=@_;
  my $cmp=$range_a->cmp_range_start($range_b);
  if($cmp==0) {
    return $range_a->cmp_range_end($range_b);
  }
  return $cmp;
}

sub boolean () {
  my ($self)=@_;
  my $start=$self->range_start;
  my $end=$self->range_end;
  return 0 unless defined($start);
  return 0 unless defined($end);
  return 0 if $self->cmp_values($start,$end)==1;
  1;
}

sub overlap ($) {
  my ($range_a,$range_b)=@_;

  return 1 if $range_a->contains_value($range_b->range_start);
  return 1 if $range_a->contains_value($range_b->range_end);

  return 1 if $range_b->contains_value($range_a->range_start);
  return 1 if $range_b->contains_value($range_a->range_end);

  return 0
}

1;
