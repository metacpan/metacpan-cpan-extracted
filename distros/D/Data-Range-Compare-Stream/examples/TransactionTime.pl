#!/usr/bin/perl

use strict;
use warnings;
use POSIX qw(mktime);
use lib qw(../lib);

use Data::Range::Compare::Stream::Iterator::File;
use Data::Range::Compare::Stream::Iterator::Compare::Asc;
use Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn;


sub parse_line {
  my ($line)=@_;
  my $ref=[$line=~ /(\d+)/g];
  foreach my $date (@$ref) {
    my @info=unpack('a4a2a2a2a2a2',$date);
    $info[0] -=1900;
    $info[1] -=1;
    $date=mktime($info[5],$info[4],$info[3],$info[2],$info[1],$info[0], 0, 0, 0);
  }
  return $ref;
}

my $cmp=new Data::Range::Compare::Stream::Iterator::Compare::Asc(factory_instance=>'Data::Range::Compare::Stream::PosixTime');

my @it_list;
foreach my $file (qw(posix_time_a.src posix_time_b.src posix_time_c.src posix_time_d.src posix_time_e.src)) {

  my $iterator=new Data::Range::Compare::Stream::Iterator::File(
    parse_line=>\&parse_line,
    filename=>$file,
    factory_instance=>'Data::Range::Compare::Stream::PosixTime',
  );

  # save our file iterator so we can figure out how many lines were in each file
  push @it_list,$iterator;

  my $con=new Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn($iterator,$cmp,factory_instance=>'Data::Range::Compare::Stream::PosixTime');
  $cmp->add_consolidator($con);
}


my $total=0;
my $time=0;
my $non_overlaps=0;
my $non_time=0;
my $min_overlap=undef;
my $max_overlap=0;
my $max_overlap_count=0;
my $min_overlap_count=undef;

while($cmp->has_next) {

  my $result=$cmp->get_next;
  next if $result->is_empty;

  if($result->get_overlap_count>1) {

    my $overlap_time=$result->get_common->time_count;

    $max_overlap_count=$result->get_overlap_count if $max_overlap_count < $result->get_overlap_count;
    if(defined($min_overlap_count)) {
      $min_overlap_count=$result->get_overlap_count if $min_overlap_count > $result->get_overlap_count;
    } else {
      $min_overlap_count=$result->get_overlap_count;
    }

    $total +=$result->get_overlap_count;
    $time +=$overlap_time;


    $max_overlap=$overlap_time if $max_overlap < $overlap_time;

    if(defined($min_overlap)) {
      $min_overlap=$overlap_time if $min_overlap > $overlap_time;
    } else {
      $min_overlap=$overlap_time;
    }

  } else {
    $non_overlaps++;
    $non_time +=$result->get_common->time_count;
  }
  
}

my $total_trades=0;
foreach my $it (@it_list) {
  $total_trades +=$it->get_pos;
}

print "Total Number of Trades: $total_trades\n";
print "Total Trade Overlaps: $total\n";
print "Average Trade Overlap time in seconds: ",int($time/$total),"\n";
print "Min Tade overlap time in seconds: $min_overlap\n";
print "Max Tade overlap time in seconds: $max_overlap\n";
print "Min number of overlapping trades: $min_overlap_count\n";
print "Max number of overlapping trades: $max_overlap_count\n";

print "Number of trades that did not overlap: $non_overlaps\n";
print "Average trade time for ranges that did not overlap: ",int($non_time/$non_overlaps),"\n";

{
  package Data::Range::Compare::Stream::PosixTime;
  
  use strict;
  use warnings;
  use POSIX qw(strftime);
  
  use base qw(Data::Range::Compare::Stream);
  
  use constant NEW_FROM_CLASS=>'Data::Range::Compare::Stream::PosixTime';
  sub format_range_value {
    my ($self,$value)=@_;
    strftime('%Y%m%d%H%M%S',localtime($value));
  }
  
  sub range_start_to_string {
    my ($self)=@_;
    $self->format_range_value($self->range_start);
  }
  
  sub time_count {
    my ($self)=@_;
    $self->range_end - $self->range_start
  }
  
  
  sub range_end_to_string {
    my ($self)=@_;
    $self->format_range_value($self->range_end);
  }
  
  1;
}
