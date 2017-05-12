# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-Range-Compare-Stream.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 224;

BEGIN { use_ok('Data::Range::Compare::Stream') };
BEGIN { use_ok('Data::Range::Compare::Stream::Sort') };
BEGIN { use_ok('Data::Range::Compare::Stream::Iterator::Array') };
BEGIN { use_ok('Data::Range::Compare::Stream::Iterator::Consolidate::Result') };
BEGIN { use_ok('Data::Range::Compare::Stream::Iterator::Consolidate') };
BEGIN { use_ok('Data::Range::Compare::Stream::Iterator::Compare::LayerCake') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

if(1){
  my $obj=new Data::Range::Compare::Stream::Iterator::Compare::LayerCake;
  ok($obj,'Object should exist');

  # instance startup behavior validation checks!
  cmp_ok($obj->get_column_count,'==',-1,'Column count with a new instance and no object should be: [-1]');
  cmp_ok($obj->get_column_count_human_readable,'==',0,'Human Readable Column count with a new instance and no object should be: [0]');
}

#
# column iterator progression start up logic single column progression tests
if(1){
  my $cmp=new Data::Range::Compare::Stream::Iterator::Compare::LayerCake;
  my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
  $obj->create_range(0,1);
  $obj->create_range(2,3);
  $obj->prepare_for_consolidate_asc;
  my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
  $cmp->add_consolidator($iterator);
  ok($cmp->has_next,'has next row 0 should work');
  ok(!$cmp->iterators_empty,'iterators should not be empty for row 0');
  {
    my $result=$cmp->get_next;
    cmp_ok($result->get_column_count,'==',1,'column count should be 1 for row 0') or diag(Dumper($result));
    cmp_ok($result->get_common_range.'','eq','0 - 1',"Iterator should return [0 - 1] as column 0 row 0");
    cmp_ok($result->get_all_containers->[0]->get_common.'','eq','0 - 1',"Iterator should return [0 - 1] as column 1 row 0");
  }

  ok($cmp->has_next,'has next row 1 should work');
  ok($cmp->iterators_empty,'iterators should be empty for row 1');
  {
    my $result=$cmp->get_next;
    cmp_ok($result->get_column_count,'==',1,'column count should be 1 for row 1') or diag(Dumper($result));
    cmp_ok($result->get_common_range.'','eq','2 - 3',"Iterator should return [0 - 1] as column 0 row 1");
    cmp_ok($result->get_all_containers->[0]->get_common.'','eq','2 - 3',"Iterator should return [2 - 3] as column 1 row 1");
  }
  ok(!$cmp->has_next,'has next should now be false');
  ok($cmp->iterators_empty,'iterators should still be empty');
}

# 
# 1 column iterator test
if(1){
  my $cmp=new Data::Range::Compare::Stream::Iterator::Compare::LayerCake;
  {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      3 11
      17 41
    );
    my @ranges;
    while(my ($start,$end)=splice(@range_set_a,0,2)) {
      $obj->create_range($start,$end);
    }
  
    $obj->prepare_for_consolidate_asc;
    my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
    cmp_ok($cmp->add_consolidator($iterator),'==',0,"Consolidator id should be 0");
  }
  cmp_ok($cmp->get_column_count,'==',0,'Column count should be: [0]');


  {
    ok($cmp->has_next);
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','3 - 11','Row 0 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','12 - 16','Row 1 check');
  }
  {
    ok($cmp->has_next,'Row 2 check should have next') or die 'cannot continue testing!';
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','17 - 41','Row 2 check');
  }
  {
    my $row=$cmp->has_next;
    ok(!$row,'iterator should be empty now!') or diag(Dumper($row));
  }
}

# 1 colum iterator test with ignore empty
if(1){
  my $cmp=new Data::Range::Compare::Stream::Iterator::Compare::LayerCake(ignore_empty=>1);
  {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      3 11
      17 41
    );
    my @ranges;
    while(my ($start,$end)=splice(@range_set_a,0,2)) {
      $obj->create_range($start,$end);
    }
  
    $obj->prepare_for_consolidate_asc;
    my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
    cmp_ok($cmp->add_consolidator($iterator),'==',0,"Consolidator id should be 0");
  }
  cmp_ok($cmp->get_column_count,'==',0,'Column count should be: [0]');


  {
    ok($cmp->has_next);
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','3 - 11','Row 0 ignore empty check');
  }
  {
    ok($cmp->has_next,'Row 2 check should have next') or die 'cannot continue testing!';
    my $row=$cmp->get_next;
    ok($row->is_full,'row should always be full!') or die diag(Dumper($cmp));
    cmp_ok($row->get_common_range.'','eq','17 - 41','Row 1 ignore empty check');
  }
  {
    my $row=$cmp->has_next;
    ok(!$row,'iterator should be empty now!') or diag(Dumper($row));
  }
}
#
# 2 column iterator sequential tests
if(1){
  my $cmp=new Data::Range::Compare::Stream::Iterator::Compare::LayerCake;
  {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      3 11
      17 41
    );
    my @ranges;
    while(my ($start,$end)=splice(@range_set_a,0,2)) {
      $obj->create_range($start,$end);
    }
  
    $obj->prepare_for_consolidate_asc;
    my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
    cmp_ok($cmp->add_consolidator($iterator),'==',0,"The consolidator id should be 0");
  }
  {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
     0 0
     1 3
     5 9
     11 15
     17 33
    );
    my @ranges;
    while(my ($start,$end)=splice(@range_set_a,0,2)) {
      $obj->create_range($start,$end);
    }
  
    $obj->prepare_for_consolidate_asc;
    my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
    ok($cmp->add_consolidator($iterator),"Should add the consolidator without error");
  }
  cmp_ok($cmp->get_column_count,'==',1,'Column count should be: [1] not [0]');


  {
    ok($cmp->has_next);
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','0 - 0','Row 0 check 2 column complex data check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','1 - 2','Row 1 check 2 column complex data check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','3 - 3','Row 2 check 2 column complex data check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','4 - 4','Row 3 check 2 column complex data check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','5 - 9','Row 4 check 2 column complex data check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','10 - 10','Row 5 check 2 column complex data check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','11 - 11','Row 6 check 2 column complex data check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','12 - 15','Row 7 check 2 column complex data check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','16 - 16','Row 8 check 2 column complex data check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','17 - 33','Row 9 check 2 column complex data check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','34 - 41','Row 10 check 2 column complex data check');
  }
  {
    my $row=$cmp->has_next;
    ok(!$row,'iterator should be empty now!') or diag(Dumper($row));
  }
}

# 2 column iterator ignore empty check
if(1){
  my $cmp=new Data::Range::Compare::Stream::Iterator::Compare::LayerCake(ignore_empty=>1);
  {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      3 11
      17 41
    );
    my @ranges;
    while(my ($start,$end)=splice(@range_set_a,0,2)) {
      $obj->create_range($start,$end);
    }
  
    $obj->prepare_for_consolidate_asc;
    my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
    cmp_ok($cmp->add_consolidator($iterator),'==',0,"The consolidator id should be 0");
  }
  {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
     0 0
     1 3
     5 9
     11 15
     17 33
    );
    my @ranges;
    while(my ($start,$end)=splice(@range_set_a,0,2)) {
      $obj->create_range($start,$end);
    }
  
    $obj->prepare_for_consolidate_asc;
    my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
    ok($cmp->add_consolidator($iterator),"Should add the consolidator without error");
  }
  cmp_ok($cmp->get_column_count,'==',1,'Column count should be: [1] not [0]');


  {
    my $row=$cmp->get_next;
    ok(!$row->is_empty,'row should not be empty!');
    cmp_ok($row->get_common_range.'','eq','0 - 0','Row 0 check 2 column complex data check');
  }
  {
    my $row=$cmp->get_next;
    ok(!$row->is_empty,'row should not be empty!');
    cmp_ok($row->get_common_range.'','eq','1 - 2','Row 1 check 2 column complex data check');
  }
  {
    my $row=$cmp->get_next;
    ok(!$row->is_empty,'row should not be empty!');
    cmp_ok($row->get_common_range.'','eq','3 - 3','Row 2 check 2 column complex data check');
  }
  {
    my $row=$cmp->get_next;
    ok(!$row->is_empty,'row should not be empty!');
    cmp_ok($row->get_common_range.'','eq','4 - 4','Row 3 check 2 column complex data check');
  }
  {
    my $row=$cmp->get_next;
    ok(!$row->is_empty,'row should not be empty!');
    cmp_ok($row->get_common_range.'','eq','5 - 9','Row 4 check 2 column complex data check');
  }
  {
    my $row=$cmp->get_next;
    ok(!$row->is_empty,'row should not be empty!');
    cmp_ok($row->get_common_range.'','eq','10 - 10','Row 5 check 2 column complex data check');
  }
  {
    my $row=$cmp->get_next;
    ok(!$row->is_empty,'row should not be empty!');
    cmp_ok($row->get_common_range.'','eq','11 - 11','Row 6 check 2 column complex data check');
  }
  {
    my $row=$cmp->get_next;
    ok(!$row->is_empty,'row should not be empty!');
    cmp_ok($row->get_common_range.'','eq','12 - 15','Row 7 check 2 column complex data check');
  }
  {
    my $row=$cmp->get_next;
    ok(!$row->is_empty,'row should not be empty!');
    cmp_ok($row->get_common_range.'','eq','17 - 33','Row 9 check 2 column complex data check');
  }
  {
    my $row=$cmp->get_next;
    ok(!$row->is_empty,'row should not be empty!');
    cmp_ok($row->get_common_range.'','eq','34 - 41','Row 10 check 2 column complex data check');
  }
  {
    my $row=$cmp->has_next;
    ok(!$row,'iterator should be empty now!') or diag(Dumper($row));
  }
}
#
# 2 column iterator non overlap
if(1){
  my $cmp=new Data::Range::Compare::Stream::Iterator::Compare::LayerCake;
  {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      3 11
      15 17
    );
    my @ranges;
    while(my ($start,$end)=splice(@range_set_a,0,2)) {
      $obj->create_range($start,$end);
    }
  
    $obj->prepare_for_consolidate_asc;
    my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
    cmp_ok($cmp->add_consolidator($iterator),'==',0,"Consolidator id should be 0");
  }
  {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
     19 21
     25 27
    );
    my @ranges;
    while(my ($start,$end)=splice(@range_set_a,0,2)) {
      $obj->create_range($start,$end);
    }
  
    $obj->prepare_for_consolidate_asc;
    my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
    cmp_ok($cmp->add_consolidator($iterator),'==',1,"Consolidator id should be 1");
  }
  cmp_ok($cmp->get_column_count,'==',1,'Column count should be: [1] not [0]');


  {
    $cmp->has_next;
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','3 - 11','Row 0 check for non overlap');
    ok(!$row->is_full,'Row 0 check for non overlap should not show as matching every column');
    ok(!$row->is_empty,'Row 0 check for non overlap should not show as matching no columns');
    my $ids=$row->get_overlap_ids;
    cmp_ok($#$ids,'==',0,'Should have 1 column with regaurd to how many columns matched');
    cmp_ok($ids->[0],'==',0,'Should just match id 0');
    my $overlaps=$row->get_overlapping_containers;
    cmp_ok($#$overlaps,'==',0,'Overlaps should contain only one object');
    cmp_ok($overlaps->[0]->get_common_range.'','eq','3 - 11','The only common range should be [3 - 11]');

  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','12 - 14','Row 1 check for non overlap');
    ok(!$row->is_full,'Row 1 check for non overlap should not show as matching every column');
    ok($row->is_empty,'Row 1 check for non overlap should show as empty!');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','15 - 17','Row 2 check for non overlap');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','18 - 18','Row 3 check for non overlap');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','19 - 21','Row 4 check for non overlap');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','22 - 24','Row 5 check for non overlap');
  }
  {
    ok($cmp->has_next,"should have next at the last row of non overlap cheks");
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','25 - 27','Row 5 check for non overlap');
  }
  {
    my $row=$cmp->has_next;
    ok(!$row,'iterator should be empty now!') or diag(Dumper($row));
  }
}

{
  my $cmp=new Data::Range::Compare::Stream::Iterator::Compare::LayerCake;
  {
    for(0 .. 1) {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      3 11
      17 41
    );
    my @ranges;
    while(my ($start,$end)=splice(@range_set_a,0,2)) {
      $obj->create_range($start,$end);
    }
  
    $obj->prepare_for_consolidate_asc;
    my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
      cmp_ok($cmp->add_consolidator($iterator),'==',$_,"Iterator column id should be: $_");
    }
  }
  ok($cmp->has_next,'should have next');
  cmp_ok($cmp->get_column_count,'==',1,'Column count should be: [1]');


  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','3 - 11','Parallel Row 0 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','12 - 16','Parallel Row 1 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','17 - 41','Parallel Row 2 check');
  }
  {
    my $row=$cmp->has_next;
    ok(!$row,'iterator should be empty now!') or diag(Dumper($row));
  }
}

# 3 column all ranges identical
{
  my $cmp=new Data::Range::Compare::Stream::Iterator::Compare::LayerCake;
  {
    for(0 .. 2) {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      3 11
      17 41
    );
    my @ranges;
    while(my ($start,$end)=splice(@range_set_a,0,2)) {
      $obj->create_range($start,$end);
    }
  
    $obj->prepare_for_consolidate_asc;
    my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
      cmp_ok($cmp->add_consolidator($iterator),'==',$_,"iterator column id should be: $_");
    }
  }
  ok($cmp->has_next,'should have next');
  cmp_ok($cmp->get_column_count,'==',2,'Column count should be: [2]');


  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','3 - 11','Parallel Row 0 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','12 - 16','Parallel Row 1 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','17 - 41','Parallel Row 2 check');
  }
  {
    my $row=$cmp->has_next;
    ok(!$row,'iterator should be empty now!') or diag(Dumper($row));
  }
}

# 3 columns all sequential
{
  my $cmp=new Data::Range::Compare::Stream::Iterator::Compare::LayerCake;
  {
    {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      0 0
      3 3
    );
    while(my ($start,$end)=splice(@range_set_a,0,2)) { $obj->create_range($start,$end); }
  
    $obj->prepare_for_consolidate_asc;
    my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
      cmp_ok($cmp->add_consolidator($iterator),'==',0,"Should add consolidator 0 without error");
    }
    {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      1 1
      4 4
    );
    while(my ($start,$end)=splice(@range_set_a,0,2)) { $obj->create_range($start,$end); }
  
    $obj->prepare_for_consolidate_asc;
    my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
      cmp_ok($cmp->add_consolidator($iterator),'==',1,"Should add consolidator 1 without error");
    }
    {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      2 2
      5 5
    );
    while(my ($start,$end)=splice(@range_set_a,0,2)) { $obj->create_range($start,$end); }
  
    $obj->prepare_for_consolidate_asc;
    my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
      cmp_ok($cmp->add_consolidator($iterator),'==',2,"Should add consolidator 2 without error");
    }
  }
  ok($cmp->has_next,'should have next');
  cmp_ok($cmp->get_column_count,'==',2,'Column count should be: [2]');


  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','0 - 0','3 column sequetial Row 0 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','1 - 1','3 column sequetial Row 1 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','2 - 2','3 column sequetial Row 2 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','3 - 3','3 column sequetial Row 3 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','4 - 4','3 column sequetial Row 4 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','5 - 5','3 column sequetial Row 5 check');
  }
  {
    my $row=$cmp->has_next;
    ok(!$row,'iterator should be empty now!') or diag(Dumper($row));
  }
}

# 3 columns gaps between all 3 columns
{
  my $cmp=new Data::Range::Compare::Stream::Iterator::Compare::LayerCake;
  {
    {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      0 0
      11 12
    );
    while(my ($start,$end)=splice(@range_set_a,0,2)) { $obj->create_range($start,$end); }
  
    $obj->prepare_for_consolidate_asc;
    my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
      cmp_ok($cmp->add_consolidator($iterator),'==',0,"Should add consolidator 0 without error");
    }
    {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      4 4
    );
    while(my ($start,$end)=splice(@range_set_a,0,2)) { $obj->create_range($start,$end); }
  
    $obj->prepare_for_consolidate_asc;
    my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
      cmp_ok($cmp->add_consolidator($iterator),'==',1,"Should add consolidator 1 without error");
    }
    {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      8 8
    );
    while(my ($start,$end)=splice(@range_set_a,0,2)) { $obj->create_range($start,$end); }
  
    $obj->prepare_for_consolidate_asc;
    my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
      cmp_ok($cmp->add_consolidator($iterator),'==',2,"Should add consolidator 2 without error");
    }
  }
  ok($cmp->has_next,'should have next');
  cmp_ok($cmp->get_column_count,'==',2,'Column count should be: [2]');


  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','0 - 0','3 column  non sequetial Row 0 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','1 - 3','3 column  non sequetial Row 1 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','4 - 4','4 column  non sequetial Row 2 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','5 - 7','5 column  non sequetial Row 3 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','8 - 8','6 column  non sequetial Row 4 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','9 - 10','7 column non  sequetial Row 5 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','11 - 12','8 column non sequetial Row 6 check');
  }
  {
    my $row=$cmp->has_next;
    ok(!$row,'iterator should be empty now!') or diag(Dumper($row));
  }
}

# 
# 3 column complex data check
{
  my $cmp=new Data::Range::Compare::Stream::Iterator::Compare::LayerCake;
  {
    {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      0 0
      7 9
      11 12
    );
    while(my ($start,$end)=splice(@range_set_a,0,2)) { $obj->create_range($start,$end); }
  
    $obj->prepare_for_consolidate_asc;
    my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
      cmp_ok($cmp->add_consolidator($iterator),'==',0,"Should add consolidator 0 without error");
    }
    {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      1 4
      5 9 
      18 29
      30 31
    );
    while(my ($start,$end)=splice(@range_set_a,0,2)) { $obj->create_range($start,$end); }
  
    $obj->prepare_for_consolidate_asc;
    my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
      ok($cmp->add_consolidator($iterator),"Should add the second consolidator without error");
    }
    {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      10 10
      12 17
    );
    while(my ($start,$end)=splice(@range_set_a,0,2)) { $obj->create_range($start,$end); }
  
    $obj->prepare_for_consolidate_asc;
    my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
      ok($cmp->add_consolidator($iterator),"Should add the second consolidator without error");
    }
  }
  ok($cmp->has_next,'should have next');
  cmp_ok($cmp->get_column_count,'==',2,'Column count should be: [2]');


  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','0 - 0','3 column  complex Row 0 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','1 - 4','3 column  complex Row 1 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','5 - 6','3 column  complex Row 2 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','7 - 9','3 column  complex Row 3 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','10 - 10','3 column  complex Row 4 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','11 - 11','3 column  complex Row 5 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','12 - 12','3 column  complex Row 6 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','13 - 17','3 column  complex Row 7 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','18 - 29','3 column  complex Row 8 check');
  }
  {
    ok($cmp->has_next,"next row should be set corretly") or die 'cannot continue testing!';
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','30 - 31','3 column  complex Row 10 check');
  }
  {
    my $row=$cmp->has_next;
    ok(!$row,'iterator should be empty now!') or diag(Dumper($row));
  }
}
{
  my $cmp=new Data::Range::Compare::Stream::Iterator::Compare::LayerCake;
  {
    {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      0 6
    );
    while(my ($start,$end)=splice(@range_set_a,0,2)) { $obj->create_range($start,$end); }
  
    $obj->prepare_for_consolidate_asc;
    my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
      cmp_ok($cmp->add_consolidator($iterator),'==',0,"Should add consolidator 0 without error");
    }
    {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      0 1
    );
    while(my ($start,$end)=splice(@range_set_a,0,2)) { $obj->create_range($start,$end); }
  
    $obj->prepare_for_consolidate_asc;
    my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
      cmp_ok($cmp->add_consolidator($iterator),'==',1,"Should add consolidator 1 without error");
    }
    {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      0 1
      2 3
    );
    while(my ($start,$end)=splice(@range_set_a,0,2)) { $obj->create_range($start,$end); }
  
    $obj->prepare_for_consolidate_asc;
    my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
      ok($cmp->add_consolidator($iterator),"Should add the second consolidator without error");
    }
    {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      5 6
    );
    while(my ($start,$end)=splice(@range_set_a,0,2)) { $obj->create_range($start,$end); }
  
    $obj->prepare_for_consolidate_asc;
    my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
      ok($cmp->add_consolidator($iterator),"Should add the second consolidator without error");
    }
  }
  ok($cmp->has_next,'should have next');
  cmp_ok($cmp->get_column_count,'==',3,'Column count should be: [3]');


  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','0 - 1','4 column  complex Row 0 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','2 - 3','4 column  complex Row 1 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','4 - 4','4 column  complex Row 2 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','5 - 6','4 column  complex Row 3 check');
  }
  {
    my $row=$cmp->has_next;
    ok(!$row,'iterator should be empty now!') or diag(Dumper($row));
  }
}
{
  my $cmp=new Data::Range::Compare::Stream::Iterator::Compare::LayerCake;
  {
    {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      0 1
      4 5
    );
    while(my ($start,$end)=splice(@range_set_a,0,2)) { $obj->create_range($start,$end); }
  
    $obj->prepare_for_consolidate_asc;
    my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
      cmp_ok($cmp->add_consolidator($iterator),'==',0,"Should add consolidator 0 without error");
    }
    {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      0 1
      4 5
    );
    while(my ($start,$end)=splice(@range_set_a,0,2)) { $obj->create_range($start,$end); }
  
    $obj->prepare_for_consolidate_asc;
    my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
      cmp_ok($cmp->add_consolidator($iterator),'==',1,"Should add consolidator 1 without error");
    }
    {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      0 1
      4 5
    );
    while(my ($start,$end)=splice(@range_set_a,0,2)) { $obj->create_range($start,$end); }
  
    $obj->prepare_for_consolidate_asc;
    my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
      ok($cmp->add_consolidator($iterator),"Should add the second consolidator without error");
    }
  }
  ok($cmp->has_next,'should have next');
  cmp_ok($cmp->get_column_count,'==',2,'Column count should be: [2]');


  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','0 - 1','3 identical colum Row 0 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','2 - 3','3 identical colum Row 1 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','4 - 5','3 identical colum Row 2 check');
  }
  {
    my $row=$cmp->has_next;
    ok(!$row,'iterator should be empty now!') or diag(Dumper($row));
  }
}

# 3 column all ranges overlap at some level
{
  my $cmp=new Data::Range::Compare::Stream::Iterator::Compare::LayerCake;
  {
    {
      my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
      my @range_set_a=qw(
        7 12
        19 24
        49 54
      );
      while(my ($start,$end)=splice(@range_set_a,0,2)) { $obj->create_range($start,$end); }
  
      $obj->prepare_for_consolidate_asc;
      my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
      cmp_ok($cmp->add_consolidator($iterator),'==',0,"Should add consolidator 0 without error");
    }
    {
      my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
      my @range_set_a=qw(
        3 8
        15 20
        39 44
      );
      while(my ($start,$end)=splice(@range_set_a,0,2)) { $obj->create_range($start,$end); }
  
      $obj->prepare_for_consolidate_asc;
      my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
      ok($cmp->add_consolidator($iterator),"Should add the second consolidator without error");
    }
    {
      my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
      my @range_set_a=qw(
        0 4
        11 16
        29 34
    );
      while(my ($start,$end)=splice(@range_set_a,0,2)) { $obj->create_range($start,$end); }
  
      $obj->prepare_for_consolidate_asc;
      my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
      ok($cmp->add_consolidator($iterator),"Should add the second consolidator without error");
    }
  }
  ok($cmp->has_next,'should have next');
  cmp_ok($cmp->get_column_count,'==',2,'Column count should be: [2]');


  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','0 - 2','1 3 column 2 ranges always overlap Row 0 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','3 - 4','1 3 column 2 ranges always overlap Row 1 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','5 - 6','1 3 column 2 ranges always overlap Row 2 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','7 - 8','1 3 column 2 ranges always overlap Row 3 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','9 - 10','1 3 column 2 ranges always overlap Row 4 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','11 - 12','1 3 column 2 ranges always overlap Row 5 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','13 - 14','1 3 column 2 ranges always overlap Row 6 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','15 - 16','1 3 column 2 ranges always overlap Row 7 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','17 - 18','1 3 column 2 ranges always overlap Row 8 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','19 - 20','1 3 column 2 ranges always overlap Row 9 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','21 - 24','1 3 column 2 ranges always overlap Row 10 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','25 - 28','1 3 column 2 ranges always overlap Row 11 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','29 - 34','1 3 column 2 ranges always overlap Row 12 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','35 - 38','1 3 column 2 ranges always overlap Row 13 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','39 - 44','1 3 column 2 ranges always overlap Row 14 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','45 - 48','1 3 column 2 ranges always overlap Row 15 check');
  }
  {
    my $row=$cmp->get_next;
    cmp_ok($row->get_common_range.'','eq','49 - 54','1 3 column 2 ranges always overlap Row 16 check');
  }
  {
    my $row=$cmp->has_next;
    ok(!$row,'iterator should be empty now!');
  }
}
{
  my $cmp=new Data::Range::Compare::Stream::Iterator::Compare::LayerCake(ignore_full=>1);
  #my $cmp=new Data::Range::Compare::Stream::Iterator::Compare::LayerCake;
  my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
  $obj->create_range(0,1);
  $obj->create_range(3,4);
  $obj->prepare_for_consolidate_asc;
  my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);

  cmp_ok($cmp->add_consolidator($iterator),'==',0,'should just have 1 column when creating our ignore_full set');
  #$DB::single=1;
  ok($cmp->has_next,"Should have only 1 row") or diag(Dumper($cmp));
  my $result=$cmp->get_next;
  ok($result,"Should have a result");
  ok(!$cmp->has_next,"Iterator should  be empty now!");
}
{
  my $cmp=new Data::Range::Compare::Stream::Iterator::Compare::LayerCake(ignore_full=>1);
  #my $cmp=new Data::Range::Compare::Stream::Iterator::Compare::LayerCake;
  {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    $obj->create_range(0,1);
    $obj->create_range(3,4);
    $obj->prepare_for_consolidate_asc;
    my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
    cmp_ok($cmp->add_consolidator($iterator),'==',0,'should just have 1 column when creating our ignore_full2 set');
  }
  {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    $obj->create_range(0,1);
    $obj->create_range(3,4);
    $obj->create_range(7,7);
    $obj->prepare_for_consolidate_asc;
    my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
    cmp_ok($cmp->add_consolidator($iterator),'==',1,'should have 2 columns when creating our ignore_full2 set');
  }

  #$DB::single=1;
  {
    ok($cmp->has_next,"ignore full row: 0") or diag(Dumper($cmp));
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq','2 - 2','first row should be: 2 - 2');
    ok($result,"Should have a result");
  }
  {
    ok($cmp->has_next,"ignore full row: 1") or diag(Dumper($cmp));
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq','5 - 6','second row should be: 5 - 6');
    ok($result,"Should have a result");
  }
  {
    ok($cmp->has_next,"ignore full row: 2") or diag(Dumper($cmp));
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq','7 - 7','last row should be: 7 - 7');
    ok($result,"Should have a result");
  }
  ok(!$cmp->has_next,'ignore full row test should be empty now');
}
{

  my $filter=sub { $_[0]->is_full };
  my $cmp=new Data::Range::Compare::Stream::Iterator::Compare::LayerCake(filter=>$filter);
  {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    $obj->create_range(0,1);
    $obj->create_range(3,4);
    $obj->prepare_for_consolidate_asc;
    my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
    cmp_ok($cmp->add_consolidator($iterator),'==',0,'should just have 1 column when creating our ignore_full2 set');
  }
  {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    $obj->create_range(0,1);
    $obj->create_range(3,4);
    $obj->create_range(7,7);
    $obj->prepare_for_consolidate_asc;
    my $iterator=Data::Range::Compare::Stream::Iterator::Consolidate->new($obj);
    cmp_ok($cmp->add_consolidator($iterator),'==',1,'should have 2 columns when creating our ignore_full2 set');
  }

  #$DB::single=1;
  {
    ok($cmp->has_next,"should have row") or diag(Dumper($cmp));
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq','0 - 1','first row should be: 0 - 1') or diag(Dumper($cmp));
    ok($result,"Should have a result");
  }
  {
    ok($cmp->has_next,"should have row");
    my $result=$cmp->get_next;
    ok($result,"Should have a result");
    cmp_ok($result->get_common.'','eq','3 - 4','last row should be: 3 - 4') or diag(Dumper($cmp));
  }
  ok(!$cmp->has_next,'ignore full row test should be empty now');
}
