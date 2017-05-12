#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

use lib qw(../lib);

use Data::Range::Compare::Stream;
use Data::Range::Compare::Stream::Iterator::Array;
use Data::Range::Compare::Stream::Iterator::Consolidate;
use Data::Range::Compare::Stream::Iterator::Compare::Asc;

# create the iterator for column_a's Consolidation iterator
my $column_a=Data::Range::Compare::Stream::Iterator::Array->new();
$column_a->create_range(3,11);
$column_a->create_range(17,19);

# create the iterator for column_b's Consolidation iterator
my $column_b=Data::Range::Compare::Stream::Iterator::Array->new();
$column_b->create_range(0,0);
$column_b->create_range(1,3);
$column_b->create_range(5,7);
$column_b->create_range(6,9);
$column_b->create_range(11,15);
$column_b->create_range(17,33);

# sort columns a and be in consolidate order
$column_a->prepare_for_consolidate_asc;
$column_b->prepare_for_consolidate_asc;

# create the consolidator object for column_a our iterator to it
my $column_a_consolidator=Data::Range::Compare::Stream::Iterator::Consolidate->new($column_a);

# create the consolidator object for column_b our iterator to it
my $column_b_consolidator=Data::Range::Compare::Stream::Iterator::Consolidate->new($column_b);

# create the object that will compare columns a and b
my $compare=new Data::Range::Compare::Stream::Iterator::Compare::Asc;

# add column a for processing
$compare->add_consolidator($column_a_consolidator);

# add column b for processing
$compare->add_consolidator($column_b_consolidator);


# now we can compute the intersections of our objects

while($compare->has_next) {

  # fetch our current result object
  my $row=$compare->get_next;

  # if no ranges overlap with this row move on
  next if $row->is_empty;

  # now we can output the current range
  my $common_range=$row->get_common;
  my $overlap_count=$row->get_overlap_count;

  print "A total of: [$overlap_count] Ranges intersected with Common range: $common_range\n";

  my $overlap_ids=$row->get_overlap_ids;
  foreach my $consolidator_id (@{$overlap_ids}) {

    if($consolidator_id==0) {

      my $result=$row->get_consolidator_result_by_id($consolidator_id);
      print "  Column a contained the following overlaps $result\n";

    } elsif($consolidator_id==1) {

      my $result=$row->get_consolidator_result_by_id($consolidator_id);
      print "  Column b contained the following overlaps $result\n";

    }

  }

  print "\n";
  
}


