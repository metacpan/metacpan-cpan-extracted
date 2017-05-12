# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-Range-Compare-Stream.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 68;


# uncomment to enable compatibility with perl versions prior to 5.8
#use sort '_quicksort';  

BEGIN { use_ok('Data::Range::Compare::Stream') };
BEGIN { use_ok('Data::Range::Compare::Stream::Sort') };

use Data::Range::Compare::Stream::Sort;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


# 
# Consolidation order check asc
{
  my @range_set_a=qw(
   0 0
   1 2
   2 3
   5 7
   5 9
   11 15
   17 29
   30 31
   30 33
  );
  my @ranges;
  while(my ($start,$end)=splice(@range_set_a,0,2)) {
    push @ranges,new Data::Range::Compare::Stream($start,$end);
  }
  my @sorted=sort sort_in_consolidate_order_asc @ranges;
  cmp_ok($sorted[0].'','eq','0 - 0',"Consolidate sort 1");
  cmp_ok($sorted[1].'','eq','1 - 2',"Consolidate sort 2");
  cmp_ok($sorted[2].'','eq','2 - 3',"Consolidate sort 3");
  cmp_ok($sorted[3].'','eq','5 - 9',"Consolidate sort 4");
  cmp_ok($sorted[4].'','eq','5 - 7',"Consolidate sort 5");
  cmp_ok($sorted[5].'','eq','11 - 15',"Consolidate sort 6");
  cmp_ok($sorted[6].'','eq','17 - 29',"Consolidate sort 7");
  cmp_ok($sorted[7].'','eq','30 - 33',"Consolidate sort 8");
  cmp_ok($sorted[8].'','eq','30 - 31',"Consolidate sort 9");

}


#
# Sort in presentation order
{
  my @range_set_a=qw(
   0 0
   1 2
   2 3
   5 7
   5 9
   11 15
   17 29
   30 31
   30 33
  );
  my @ranges;
  while(my ($start,$end)=splice(@range_set_a,0,2)) {
    push @ranges,new Data::Range::Compare::Stream($start,$end);
  }
  my @sorted=sort sort_in_presentation_order @ranges;
  cmp_ok($sorted[0].'','eq','0 - 0',"Present sort 1");
  cmp_ok($sorted[1].'','eq','1 - 2',"Present sort 2");
  cmp_ok($sorted[2].'','eq','2 - 3',"Present sort 3");
  cmp_ok($sorted[3].'','eq','5 - 7',"Present sort 4");
  cmp_ok($sorted[4].'','eq','5 - 9',"Present sort 5");
  cmp_ok($sorted[5].'','eq','11 - 15',"Present sort 6");
  cmp_ok($sorted[6].'','eq','17 - 29',"Present sort 7");
  cmp_ok($sorted[7].'','eq','30 - 31',"Present sort 8");
  cmp_ok($sorted[8].'','eq','30 - 33',"Present sort 9");
}

#
# Sort by smallest range_start first
{
  my @range_set_a=qw(
   0 0
   1 2
   2 3
   5 7
   5 9
   11 15
   17 29
   30 31
   30 33
  );
  my @ranges;
  while(my ($start,$end)=splice(@range_set_a,0,2)) {
    push @ranges,new Data::Range::Compare::Stream($start,$end);
  }
  my @sorted=sort sort_smallest_range_start_first @ranges;
  cmp_ok($sorted[0].'','eq','0 - 0',"Smallest Start Range sort 1");
  cmp_ok($sorted[1].'','eq','1 - 2',"Smallest Start Range sort 2");
  cmp_ok($sorted[2].'','eq','2 - 3',"Smallest Start Range sort 3");
  cmp_ok($sorted[3].'','eq','5 - 7',"Smallest Start Range sort 4");
  cmp_ok($sorted[4].'','eq','5 - 9',"Smallest Start Range sort 5");
  cmp_ok($sorted[5].'','eq','11 - 15',"Smallest Start Range sort 6");
  cmp_ok($sorted[6].'','eq','17 - 29',"Smallest Start Range sort 7");
  cmp_ok($sorted[7].'','eq','30 - 31',"Smallest Start Range sort 8");
  cmp_ok($sorted[8].'','eq','30 - 33',"Smallest Start Range sort 9");
}

#
# Sort by largest range_start first
{
  my @range_set_a=qw(
   0 0
   1 2
   2 3
   5 7
   5 9
   11 15
   17 29
   30 31
   30 33
  );
  my @ranges;
  while(my ($start,$end)=splice(@range_set_a,0,2)) {
    push @ranges,new Data::Range::Compare::Stream($start,$end);
  }
  my @sorted=sort sort_largest_range_start_first @ranges;
  cmp_ok($#sorted,'==',8,'Should have 8 ranges to compare last index == 8');
  cmp_ok($sorted[0]->range_start,'==','30',"Largest Start Range sort 1");
  cmp_ok($sorted[1]->range_start,'==','30',"Largest Start Range sort 2");
  cmp_ok($sorted[2]->range_start,'==','17',"Largest Start Range sort 3");
  cmp_ok($sorted[3]->range_start,'==','11',"Largest Start Range sort 4");
  cmp_ok($sorted[4]->range_start,'==','5',"Largest Start Range sort 5");
  cmp_ok($sorted[5]->range_start,'==','5',"Largest Start Range sort 6");
  cmp_ok($sorted[6]->range_start,'==','2',"Largest Start Range sort 7");
  cmp_ok($sorted[7]->range_start,'==','1',"Largest Start Range sort 8");
  cmp_ok($sorted[8]->range_start,'==','0',"Largest Start Range sort 9");
}


#
# Sort by Largest Range End
{
  my @range_set_a=qw(
   0 0
   1 2
   30 33
   2 3
   5 7
   5 9
   11 15
   30 31
   17 29
  );
  my @ranges;
  while(my ($start,$end)=splice(@range_set_a,0,2)) {
    push @ranges,new Data::Range::Compare::Stream($start,$end);
  }
  my @sorted=sort sort_largest_range_end_first @ranges;
  cmp_ok($sorted[0].'','eq','30 - 33',"Largest End Range sort 1");
  cmp_ok($sorted[1].'','eq','30 - 31',"Largest End Range sort 2");
  cmp_ok($sorted[2].'','eq','17 - 29',"Largest End Range sort 3");
  cmp_ok($sorted[3].'','eq','11 - 15',"Largest End Range sort 4");
  cmp_ok($sorted[4].'','eq','5 - 9',"Largest End Range sort 5");
  cmp_ok($sorted[5].'','eq','5 - 7',"Largest End Range sort 6");
  cmp_ok($sorted[6].'','eq','2 - 3',"Largest End Range sort 7");
  cmp_ok($sorted[7].'','eq','1 - 2',"Largest End Range sort 8");
  cmp_ok($sorted[8].'','eq','0 - 0',"Largest End Range sort 9");
}

#
# Sort by Smallest Range End
{
  my @range_set_a=qw(
   0 0
   1 2
   2 3
   5 7
   5 9
   11 15
   17 29
   30 31
   30 33
  );
  my @ranges;
  while(my ($start,$end)=splice(@range_set_a,0,2)) {
    push @ranges,new Data::Range::Compare::Stream($start,$end);
  }
  my @sorted=sort sort_smallest_range_end_first @ranges;
  cmp_ok($sorted[0].'','eq','0 - 0',"Smallest Range End sort 1");
  cmp_ok($sorted[1].'','eq','1 - 2',"Smallest Range End sort 2");
  cmp_ok($sorted[2].'','eq','2 - 3',"Smallest Range End sort 3");
  cmp_ok($sorted[3].'','eq','5 - 7',"Smallest Range End sort 5");
  cmp_ok($sorted[4].'','eq','5 - 9',"Smallest Range End sort 4");
  cmp_ok($sorted[5].'','eq','11 - 15',"Smallest Range End sort 6");
  cmp_ok($sorted[6].'','eq','17 - 29',"Smallest Range End sort 7");
  cmp_ok($sorted[7].'','eq','30 - 31',"Smallest Range End sort 9");
  cmp_ok($sorted[8].'','eq','30 - 33',"Smallest Range End sort 8");

}



#
# Consolidate order desc
{
  my @range_set_a=qw(
   5 7
   0 0
   1 2
   2 3
   11 15
   5 9
   27 31
   17 29
   30 31
   4 9
   30 33
  );
  my @ranges;
  while(my ($start,$end)=splice(@range_set_a,0,2)) {
    push @ranges,new Data::Range::Compare::Stream($start,$end);
  }
  my @sorted=sort sort_in_consolidate_order_desc @ranges;
  cmp_ok($sorted[0].'','eq','30 - 33',"Consolidate DESC sort 1");
  cmp_ok($sorted[1].'','eq','27 - 31',"Consolidate DESC sort 2");
  cmp_ok($sorted[2].'','eq','30 - 31',"Consolidate DESC sort 3");
  cmp_ok($sorted[3].'','eq','17 - 29',"Consolidate DESC sort 4");
  cmp_ok($sorted[4].'','eq','11 - 15',"Consolidate DESC sort 5");
  cmp_ok($sorted[5].'','eq','4 - 9',"Consolidate DESC sort 6");
  cmp_ok($sorted[6].'','eq','5 - 9',"Consolidate DESC sort 7");
  cmp_ok($sorted[7].'','eq','5 - 7',"Consolidate DESC sort 8");
  cmp_ok($sorted[8].'','eq','2 - 3',"Consolidate DESC sort 9");
  cmp_ok($sorted[9].'','eq','1 - 2',"Consolidate DESC sort 10");
  cmp_ok($sorted[10].'','eq','0 - 0',"Consolidate DESC sort 11");

}
