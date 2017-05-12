package Data::Range::Compare::Stream::Iterator::Compare::Result;

use strict;
use warnings;
use overload
 '""'=>\&to_string,
 fallback=>1;


use constant COMMON_RANGE=>0;
use constant OVERLAP_RESULTS=>1;
use constant OVERLAP_COUNT=>2;
use constant OVERLAP_IDS=>3;
use constant NON_OVERLAP_IDS=>4;
use constant COLUMN_MAP=>5;
use constant ROOT_IDS=>6;

use constant PRINT_FORMAT=>'Common Range: [%s] Column id(s) that Overlap: [%s]';

use base qw(Data::Range::Compare::Stream::Result::Base);

sub get_common_range {
  my ($self)=@_;
  $self->[$self->COMMON_RANGE]
}

*get_common=\&get_common_range;

sub get_root_ids { [@{$_[0]->[$_[0]->ROOT_IDS]}] }

sub get_column_map { [@{$_[0]->[$_[0]->COLUMN_MAP]}] }

sub get_overlap_count {
  my ($self)=@_;
  $self->[$self->OVERLAP_COUNT]
}

sub get_column_count {
  my ($self)=@_;
  $#{$self->[$self->OVERLAP_RESULTS]} + 1;
}

sub get_overlap_ids {
  my ($self)=@_;
  [@{$self->[$self->OVERLAP_IDS]}]
}

sub get_non_overlap_ids {
  my ($self)=@_;
  [@{$self->[$self->NON_OVERLAP_IDS]}]
}
sub get_non_overlap_count {
  $_[0]->get_column_count - $_[0]->get_overlap_count
}

sub get_consolidator_result_by_id {
  my ($self,$id)=@_;
  $self->[$self->OVERLAP_RESULTS]->[$id]
}

*get_result_by_id=\&get_consolidator_result_by_id;
*get_column_by_id=\&get_consolidator_result_by_id;


sub is_empty { $_[0]->get_overlap_count==0 }
*none_overlap=\&is_empty;

sub is_full { $_[0]->get_overlap_count==$_[0]->get_column_count }
*all_overlap=\&is_full;


sub get_overlapping_containers {
  my ($self)=@_;
  [@{$self->[$self->OVERLAP_RESULTS]}[@{$self->get_overlap_ids}]]
}


sub get_all_containers {
  my ($self)=@_;
  [@{$self->[$self->OVERLAP_RESULTS]}]
}

sub get_non_overlapping_containers {
  my ($self)=@_;
  [@{$self->[$self->OVERLAP_RESULTS]}[@{$self->get_non_overlap_ids}]]
}

sub to_string {
  my ($self)=@_;
  return sprintf $self->PRINT_FORMAT,$self->get_common,join(',',@{$self->get_overlap_ids});
}

sub get_root_result_ids {
  my ($self)=@_;

  my $result=[];

  my $map=$self->[$self->COLUMN_MAP];

  for(my $id=0;$id<$self->get_column_count;++$id ) {
    my $target=$map->[$id];
    $result->[$target]=[] unless defined($result->[$target]);

    my $ref=$result->[$target];
    my $obj=$self->get_result_by_id($id);

    push @$ref,$id if defined($obj);
  }

  return $result;
}

sub get_root_results {
  my ($self)=@_;

  my $result=[];

  my $map=$self->[$self->COLUMN_MAP];

  for(my $id=0;$id<$self->get_column_count;++$id ) {
    my $target=$map->[$id];
    $result->[$target]=[] unless defined($result->[$target]);

    my $ref=$result->[$target];
    my $obj=$self->get_result_by_id($id);
    next unless defined($obj);

    push @$ref,$obj;
  }

  return $result;
}



1;
