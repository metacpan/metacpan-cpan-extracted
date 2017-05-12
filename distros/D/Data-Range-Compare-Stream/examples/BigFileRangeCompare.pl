#!/usr/bin/perl

use strict;
use warnings;
use lib qw(../lib);

use Data::Range::Compare::Stream;
use Data::Range::Compare::Stream::Iterator::File::MergeSortAsc;
use Data::Range::Compare::Stream::Iterator::Compare::Asc;
use Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn;

my $cmp=new Data::Range::Compare::Stream::Iterator::Compare::Asc;

sub parse_file_one {
  my ($line)=@_;
  my @list=split /\s+/,$line;
  return [@list[4,5],$line]
}

sub parse_file_two {
  my ($line)=@_;
  my @list=split /\s+/,$line;
  return [@list[2,3],$line]
}

sub range_to_line {
  my ($range)=@_;
  return $range->data;
}

my $file_one=new Data::Range::Compare::Stream::Iterator::File::MergeSortAsc(
  result_to_line=>\&range_to_line,
  parse_line=>\&parse_file_one,
  filename=>'custom_file_1.src',
);

my $file_two=new Data::Range::Compare::Stream::Iterator::File::MergeSortAsc(
  result_to_line=>\&range_to_line,
  parse_line=>\&parse_file_two,
  filename=>'custom_file_2.src',
);

my $set_one=new Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn($file_one,$cmp);
my $set_two=new Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn($file_two,$cmp);

$cmp->add_consolidator($set_one);
$cmp->add_consolidator($set_two);

while($cmp->has_next) {
  my $result=$cmp->get_next;
  next if $result->is_empty;

  my $ref=$result->get_root_results;
  next if $#{$ref->[0]}==-1;
  next if $#{$ref->[1]}==-1;

  foreach my $overlap (@{$ref->[0]}) {
    print $overlap->get_common->data;
  }

}
