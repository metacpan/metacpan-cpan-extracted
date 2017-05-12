# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-Range-Compare-Stream.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 31;

BEGIN { use_ok('Data::Range::Compare::Stream') };
BEGIN { use_ok('Data::Range::Compare::Stream::Sort') };
BEGIN { use_ok('Data::Range::Compare::Stream::Iterator::Array') };
BEGIN { use_ok('Data::Range::Compare::Stream::Iterator::Consolidate::Result') };
BEGIN { use_ok('Data::Range::Compare::Stream::Iterator::Consolidate::AdjacentAsc') };

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
   0 0
   1 2
   2 3
   5 9
   5 7
   11 15
   17 29
   27 31
   30 31
   30 33
  );
  my @ranges;
  while(my ($start,$end)=splice(@range_set_a,0,2)) {
    $obj->create_range($start,$end);
  }

  $obj->prepare_for_consolidate_asc;
  my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate::AdjacentAsc->new($obj);
  {
    my $range=$iterator->get_next;
    cmp_ok($range->get_common.'','eq','0 - 3',"Consolidate ASC  Common range check 1");
    cmp_ok($range->get_start.'','eq','0 - 0',"Consolidate ASC Start range check 1");
    cmp_ok($range->get_end.'','eq','2 - 3',"Consolidate ASC End range check 1");
    ok($range->is_generated,'generated check');
  }

  {
    my $range=$iterator->get_next;
    cmp_ok($range->get_common.'','eq','5 - 9',"Consolidate ASC  Common range check 2");
    cmp_ok($range->get_start.'','eq','5 - 7',"Consolidate ASC Start range check 2");
    cmp_ok($range->get_end.'','eq','5 - 9',"Consolidate ASC End range check 2");
    ok($range->is_generated,'generated check');
  }

  {
    my $range=$iterator->get_next;
    cmp_ok($range->get_common.'','eq','11 - 15',"Consolidate ASC  Common range check 3");
    cmp_ok($range->get_start.'','eq','11 - 15',"Consolidate ASC Start range check 3");
    cmp_ok($range->get_end.'','eq','11 - 15',"Consolidate ASC End range check 3");
    ok(!$range->is_generated,'generated check');
  }

  {
    my $range=$iterator->get_next;
    cmp_ok($range->get_common.'','eq','17 - 33',"Consolidate ASC  Common range check 4");
    cmp_ok($range->get_start.'','eq','17 - 29',"Consolidate ASC Start range check 4");
    cmp_ok($range->get_end.'','eq','30 - 33',"Consolidate ASC End range check 4") or diag(Dumper($range));
    ok($range->is_generated,'generated check');
  }

  my $last_iterator=$iterator->has_next;
  ok(!$last_iterator,"Iterator should be empty!") or diag(Dumper($iterator));
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
  my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate::AdjacentAsc->new($obj);
  {
    my $range=$iterator->get_next;
    cmp_ok($range->get_common.'','eq','0 - 0',"Consolidate Single Common range check 1");
    cmp_ok($range->get_start.'','eq','0 - 0',"Consolidate Single Start range check 1");
    cmp_ok($range->get_end.'','eq','0 - 0',"Consolidate Single End range check 1");
    ok(!$range->is_generated,'generated check');
  }
  my $last_iterator=$iterator->get_next;
  ok(!$last_iterator,"Iterator should be empty!") or diag(Dumper($last_iterator));
  ok(!$obj->get_next,"Collection should be empty!");

}

