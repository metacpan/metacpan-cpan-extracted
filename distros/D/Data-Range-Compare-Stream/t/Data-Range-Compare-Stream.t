# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-Range-Compare-Stream.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 39;

BEGIN { use_ok('Data::Range::Compare::Stream') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#
# Basic Constructor tests
{
  my $range=new Data::Range::Compare::Stream(0,0);
  ok($range,"Constructor should return a valid object without any issues");
  my $range_=$range->new(1,2);
  ok($range,"Should construct a new instance from the old instance without an error");
}


#
# Compare Interface checks
{
  my $range=new Data::Range::Compare::Stream(0,1);
  cmp_ok($range->cmp_values(0,0),'==',0,"Comparing 2 identical values should return: [0]");
  cmp_ok($range->cmp_values(1,0),'==',1,"When first value is larger test should return: [1]");
  cmp_ok($range->cmp_values(0,1),'==',-1,"When first value is smaller test should return: [-1]");
}


#
# Add one interface
{
  my $range=new Data::Range::Compare::Stream(0,1);
  cmp_ok($range->add_one(0),'==',1,"add_one 0 + 1 return: [1]");
}


#
# Sub one interface
{
  my $range=new Data::Range::Compare::Stream(0,1);
  cmp_ok($range->sub_one(0),'==',-1,"sub_one 0 - 1 return: [-1]");
}

#
# Getter/Setter interface checks
{
  my $range=new Data::Range::Compare::Stream(0,1,"SOME_STRING");
  cmp_ok($range->range_start,'==',0,"range_start should return: [0]");
  cmp_ok($range->range_end,'==',1,"range_end should return: [1]");
  cmp_ok($range->data.'','eq','SOME_STRING','data should return: [SOME_STRING]');
  $range->data('NEW_STRING');
  cmp_ok($range->data.'','eq','NEW_STRING','data should return: [NEW_STRING]');
}


#
# Next and previos checks
{
  my $range=new Data::Range::Compare::Stream(0,1);
  cmp_ok($range->next_range_start,'==',2,'next_range_start should return [2]');
  cmp_ok($range->previous_range_end,'==',-1,'next_range_start should return [-1]');
}


#
# Range start and end compare tests
{
  
  my $range_a=new Data::Range::Compare::Stream(0,1);
  my $range_b=new Data::Range::Compare::Stream(1,2);
  cmp_ok($range_a->cmp_range_start($range_a),'==',0,'range_a->cmp_range_start($range_a) should return [0]');
  cmp_ok($range_b->cmp_range_start($range_a),'==',1,'range_b->cmp_range_start($range_a) should return [1]');
  cmp_ok($range_a->cmp_range_start($range_b),'==',-1,'range_a->cmp_range_start($range_b) should return [-1]');

  cmp_ok($range_a->cmp_range_end($range_a),'==',0,'range_a->cmp_range_end($range_a) should return [0]');
  cmp_ok($range_b->cmp_range_end($range_a),'==',1,'range_b->cmp_range_end($range_a) should return [1]');
  cmp_ok($range_a->cmp_range_end($range_b),'==',-1,'range_a->cmp_range_end($range_b) should return [-1]');
}

#
# Full Range Compare tests
{
  my $range_a=new Data::Range::Compare::Stream(0,1);
  my $range_b=new Data::Range::Compare::Stream(2,2);
  my $range_c=new Data::Range::Compare::Stream(2,3);

  # contiguous checks boolean
  cmp_ok($range_a->contiguous_check($range_b),'==',1,"range_b should imediatly follow range_a") or diag(Dumper($range_a,$range_b));
  cmp_ok($range_b->contiguous_check($range_a),'==',0,"range_a should not follow range_b") or diag(Dumper($range_a,$range_b));

  # compare checks <=>
  cmp_ok($range_a->cmp_ranges($range_b),'==',-1,'range_a is before range_b should return [-1]');
  cmp_ok($range_b->cmp_ranges($range_a),'==',1,'range_b is after range_a and should return [1]');
  cmp_ok($range_b->cmp_ranges($range_b),'==',0,'range_b is range_b and should return [0]');

  # overlap checks boolean
  ok(!$range_a->overlap($range_b),'range_a and range_b do not overlap and should return [0]');
  cmp_ok($range_b->overlap($range_c),'==',1,'range_b and range_c overlap and should return [1]');


  my $range_all=$range_a->get_overlapping_range([$range_a,$range_b,$range_c]);
  cmp_ok($range_all.'','eq','0 - 3','The overlapping range for all 3 ranges is [0 - 3]');

  my $range_common=Data::Range::Compare::Stream->get_common_range([$range_b,$range_c]);
  cmp_ok($range_common.'','eq','2 - 2','The overlapping range for all [2 - 2 and 2 - 3] is [2 - 2]');
}

{
  my $ranges=[];
  my @ranges=qw(0 1 0 2 3 5 2 5 1 5);
  while(my ($start,$end)=splice(@ranges,0,2)) {
    my $range=Data::Range::Compare::Stream->new($start,$end);
    push @$ranges,$range;
  }
  my ($start,$end)=Data::Range::Compare::Stream->find_smallest_outer_ranges($ranges);

  cmp_ok($start.'','eq','0 - 1',"find_smallest_outer_ranges start");
  cmp_ok($end.'','eq','3 - 5',"find_smallest_outer_ranges end");
}

# range validation checks
{
  my $c='Data::Range::Compare::Stream';
  {
    my $check=$c->new();
    ok(!$check->boolean,'bad range check');
  }
  {
    my $check=$c->new(undef,0);
    ok(!$check->boolean,'bad range check');
  }
  {
    my $check=$c->new(0,undef);
    ok(!$check->boolean,'bad range check');
  }
  {
    my $check=$c->new(0,undef,'data');
    ok(!$check->boolean,'bad range check');
  }
  {
    my $check=$c->new(0,-1,'data');
    ok(!$check->boolean,'bad range check');
  }
  {
    my $check=$c->new(0,1,'data');
    ok($check->boolean,'good range check');
  }
  {
    my $check=$c->new(0,0,'data');
    ok($check->boolean,'good range check');
  }
  {
    my $check=$c->new(1,2,'data');
    ok($check->boolean,'good range check');
  }
}
