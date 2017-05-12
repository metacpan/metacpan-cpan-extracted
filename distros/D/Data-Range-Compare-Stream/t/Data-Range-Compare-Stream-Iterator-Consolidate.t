# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-Range-Compare-Stream.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 59;

BEGIN { use_ok('Data::Range::Compare::Stream') };
BEGIN { use_ok('Data::Range::Compare::Stream::Sort') };
BEGIN { use_ok('Data::Range::Compare::Stream::Iterator::Array') };
BEGIN { use_ok('Data::Range::Compare::Stream::Iterator::Consolidate::Result') };
BEGIN { use_ok('Data::Range::Compare::Stream::Iterator::Consolidate') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#
# Instance constructor test
{
  my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
  
  ok($obj,"Should construct the class object without error");
  cmp_ok($obj.'','eq','Data::Range::Compare::Stream::Iterator::Array',"The name of the class should be returned when calling the instance in a string context");
}


#
# Consolidate in asc order
{
  my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
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
   30 33
  );
  my @ranges;
  while(my ($start,$end)=splice(@range_set_a,0,2)) {
    $obj->create_range($start,$end);
  }

  $obj->prepare_for_consolidate_asc;
  my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
  {
    my $range=$iterator->get_next;
    cmp_ok($range->get_common.'','eq','0 - 0',"Consolidate ASC  Common range check 1");
    cmp_ok($range->get_start.'','eq','0 - 0',"Consolidate ASC Start range check 1");
    cmp_ok($range->get_end.'','eq','0 - 0',"Consolidate ASC End range check 1");
    ok(!$range->is_generated,'generaated check');
  }

  {
    my $range=$iterator->get_next;
    cmp_ok($range->get_common.'','eq','1 - 3',"Consolidate ASC  Common range check 2");
    cmp_ok($range->get_start.'','eq','1 - 2',"Consolidate ASC Start range check 2");
    cmp_ok($range->get_end.'','eq','2 - 3',"Consolidate ASC End range check 2");
    ok($range->is_generated,'generaated check');
  }

  {
    my $range=$iterator->get_next;
    cmp_ok($range->get_common.'','eq','5 - 9',"Consolidate ASC  Common range check 3");
    cmp_ok($range->get_start.'','eq','5 - 7',"Consolidate ASC Start range check 3");
    cmp_ok($range->get_end.'','eq','5 - 9',"Consolidate ASC End range check 3");
    ok($range->is_generated,'generaated check');
  }

  {
    my $range=$iterator->get_next;
    cmp_ok($range->get_common.'','eq','11 - 15',"Consolidate ASC  Common range check 4");
    cmp_ok($range->get_start.'','eq','11 - 15',"Consolidate ASC Start range check 4");
    cmp_ok($range->get_end.'','eq','11 - 15',"Consolidate ASC End range check 4");
    ok(!$range->is_generated,'generaated check');
  }




  {
    my $range=$iterator->get_next;
    cmp_ok($range->get_common.'','eq','17 - 33',"Consolidate ASC  Common range check 5");
    cmp_ok($range->get_start.'','eq','17 - 29',"Consolidate ASC Start range check 5");
    cmp_ok($range->get_end.'','eq','30 - 33',"Consolidate ASC End range check 5");
    ok($range->is_generated,'generaated check');
  }

  my $last_iterator=$iterator->get_next;
  ok(!$last_iterator,"Iterator should be empty!") or diag(Dumper($last_iterator));
  ok(!$obj->get_next,"Collection should be empty!");

}

# 
# Single range check
{
  my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
  my @range_set_a=qw(
   0 0
  );
  my @ranges;
  while(my ($start,$end)=splice(@range_set_a,0,2)) {
    $obj->create_range($start,$end);
  }

  $obj->prepare_for_consolidate_asc;
  my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
  {
    my $range=$iterator->get_next;
    cmp_ok($range->get_common.'','eq','0 - 0',"Consolidate Single Common range check 1");
    cmp_ok($range->get_start.'','eq','0 - 0',"Consolidate Single Start range check 1");
    cmp_ok($range->get_end.'','eq','0 - 0',"Consolidate Single End range check 1");
    ok(!$range->is_generated,'generaated check');
  }
  my $last_iterator=$iterator->get_next;
  ok(!$last_iterator,"Iterator should be empty!") or diag(Dumper($last_iterator));
  ok(!$obj->get_next,"Collection should be empty!");

}

#
# Create our subclass for extending the data.
{
  our $CONSOLIDATE=0;
  our $UNIQUE=0;
  our %VALIDATE;
  {
    package ConsolidateSubClass;
    use base qw(Data::Range::Compare::Stream::Iterator::Consolidate);
    sub on_consolidate {
      my ($self,$new_range,$last_range,$next_range)=@_;
     ++$CONSOLIDATE;
      if(my $id=$last_range->data) {
        $UNIQUE++ unless $VALIDATE{$id}++;
      } 
      if(my $id=$next_range->data) {
        $UNIQUE++ unless $VALIDATE{$id}++;
      } 
    }
    1;
  }

  my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
  my @range_set_a=qw(
   0 0
   0 0

   3 4
   4 7
   5 7

   9 10 

   11 12

   13 14

   15 16

   17 18
   
   19 19


   20 21
   21 22
   20 23
  );
  my @ranges;
  my $id=0;
  while(my ($start,$end)=splice(@range_set_a,0,2)) {
    my $range=new Data::Range::Compare::Stream($start,$end,++$id);
    $obj->add_range($range);
  }
  $obj->prepare_for_consolidate_asc;

  my $cons=new ConsolidateSubClass($obj);
  while($cons->has_next) {
    $cons->get_next;
  }
  cmp_ok($CONSOLIDATE,'==',5,"Should be 5 Consolidations");
  cmp_ok($UNIQUE,'==',scalar(keys %VALIDATE),"Should have 8 unique ranges passing through the call back");
}
{
  my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
  my @range_set_a=qw(
   5 7
   0 0
   0 0
   0 0
   1 2
   2 3
   11 15
   5 9
   27 31
   17 29
   30 31
   30 33
  );
  my @ranges;
  while(my ($start,$end)=splice(@range_set_a,0,2)) {
    $obj->create_range($start,$end);
  }

  $obj->prepare_for_consolidate_asc;
  my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
  {
    my $range=$iterator->get_next;
    cmp_ok($range->get_common.'','eq','0 - 0',"Consolidate ASC  Common range check 1");
    cmp_ok($range->get_start.'','eq','0 - 0',"Consolidate ASC Start range check 1");
    cmp_ok($range->get_end.'','eq','0 - 0',"Consolidate ASC End range check 1");
    ok($range->is_generated,'generaated check');
  }

  {
    my $range=$iterator->get_next;
    cmp_ok($range->get_common.'','eq','1 - 3',"Consolidate ASC  Common range check 2");
    cmp_ok($range->get_start.'','eq','1 - 2',"Consolidate ASC Start range check 2");
    cmp_ok($range->get_end.'','eq','2 - 3',"Consolidate ASC End range check 2");
    ok($range->is_generated,'generaated check');
  }

  {
    my $range=$iterator->get_next;
    cmp_ok($range->get_common.'','eq','5 - 9',"Consolidate ASC  Common range check 3");
    cmp_ok($range->get_start.'','eq','5 - 7',"Consolidate ASC Start range check 3");
    cmp_ok($range->get_end.'','eq','5 - 9',"Consolidate ASC End range check 3");
    ok($range->is_generated,'generaated check');
  }

  {
    my $range=$iterator->get_next;
    cmp_ok($range->get_common.'','eq','11 - 15',"Consolidate ASC  Common range check 4");
    cmp_ok($range->get_start.'','eq','11 - 15',"Consolidate ASC Start range check 4");
    cmp_ok($range->get_end.'','eq','11 - 15',"Consolidate ASC End range check 4");
    ok(!$range->is_generated,'generaated check');
  }




  {
    my $range=$iterator->get_next;
    cmp_ok($range->get_common.'','eq','17 - 33',"Consolidate ASC  Common range check 5");
    cmp_ok($range->get_start.'','eq','17 - 29',"Consolidate ASC Start range check 5");
    cmp_ok($range->get_end.'','eq','30 - 33',"Consolidate ASC End range check 5");
    ok($range->is_generated,'generaated check');
  }

  my $last_iterator=$iterator->get_next;
  ok(!$last_iterator,"Iterator should be empty!") or diag(Dumper($last_iterator));
  ok(!$obj->get_next,"Collection should be empty!");

}
