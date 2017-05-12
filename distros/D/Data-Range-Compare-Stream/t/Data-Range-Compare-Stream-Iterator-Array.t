# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-Range-Compare-Stream.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 75;

BEGIN { use_ok('Data::Range::Compare::Stream') };
BEGIN { use_ok('Data::Range::Compare::Stream::Sort') };
BEGIN { use_ok('Data::Range::Compare::Stream::Iterator::Array') };

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
# Consolidate order desc
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
  ok(!$obj->sorted,'object should currently not be sorted!');
  ok(!$obj->has_next,'Should not have next when no sort action has been taken');
  $obj->prepare_for_consolidate_desc;
  ok($obj->has_next,'After sorting should have next');


  cmp_ok($obj->get_next.'','eq','30 - 33',"Consolidate DESC sort 1");
  ok($obj->has_next,'Consolidate has_next test 1');

  cmp_ok($obj->get_next.'','eq','27 - 31',"Consolidate DESC sort 2");
  ok($obj->has_next,'Consolidate has_next test 2');

  cmp_ok($obj->get_next.'','eq','30 - 31',"Consolidate DESC sort 3");
  ok($obj->has_next,'Consolidate has_next test 3');

  cmp_ok($obj->get_next.'','eq','17 - 29',"Consolidate DESC sort 4");
  ok($obj->has_next,'Consolidate has_next test 4');

  cmp_ok($obj->get_next.'','eq','11 - 15',"Consolidate DESC sort 5");
  ok($obj->has_next,'Consolidate has_next test 5');

  cmp_ok($obj->get_next.'','eq','5 - 9',"Consolidate DESC sort 6");
  ok($obj->has_next,'Consolidate has_next test 6');

  cmp_ok($obj->get_next.'','eq','5 - 7',"Consolidate DESC sort 7");
  ok($obj->has_next,'Consolidate has_next test 7');

  cmp_ok($obj->get_next.'','eq','2 - 3',"Consolidate DESC sort 8");
  ok($obj->has_next,'Consolidate has_next test 8');

  cmp_ok($obj->get_next.'','eq','1 - 2',"Consolidate DESC sort 9");
  ok($obj->has_next,'Consolidate has_next test 9');

  cmp_ok($obj->get_next.'','eq','0 - 0',"Consolidate DESC sort 10");
  ok(!$obj->has_next,'has_next should now return false');

  ok(!$obj->get_next,"Iterator should be empty!");

}

# Consolidate order asc 
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
  cmp_ok($obj->get_next.'','eq','0 - 0',"Consolidate ASC sort 1");
  cmp_ok($obj->get_next.'','eq','1 - 2',"Consolidate ASC sort 2");
  cmp_ok($obj->get_next.'','eq','2 - 3',"Consolidate ASC sort 3");
  cmp_ok($obj->get_next.'','eq','5 - 9',"Consolidate ASC sort 4");
  cmp_ok($obj->get_next.'','eq','5 - 7',"Consolidate ASC sort 5");
  cmp_ok($obj->get_next.'','eq','11 - 15',"Consolidate ASC sort 6");
  cmp_ok($obj->get_next.'','eq','17 - 29',"Consolidate ASC sort 7");
  cmp_ok($obj->get_next.'','eq','27 - 31',"Consolidate ASC sort 8");
  cmp_ok($obj->get_next.'','eq','30 - 33',"Consolidate ASC sort 9");
  cmp_ok($obj->get_next.'','eq','30 - 31',"Consolidate ASC sort 10");
  ok(!$obj->get_next,"Iterator should be empty!");
}

{
  my $obj=Data::Range::Compare::Stream::Iterator::Array->new(autosort=>'prepare_for_consolidate_asc');
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
  ok($obj->has_next,'should have next');
  cmp_ok($obj->get_next.'','eq','0 - 0',"Consolidate ASC sort 1");
  cmp_ok($obj->get_next.'','eq','1 - 2',"Consolidate ASC sort 2");
  cmp_ok($obj->get_next.'','eq','2 - 3',"Consolidate ASC sort 3");
  cmp_ok($obj->get_next.'','eq','5 - 9',"Consolidate ASC sort 4");
  cmp_ok($obj->get_next.'','eq','5 - 7',"Consolidate ASC sort 5");
  cmp_ok($obj->get_next.'','eq','11 - 15',"Consolidate ASC sort 6");
  cmp_ok($obj->get_next.'','eq','17 - 29',"Consolidate ASC sort 7");
  cmp_ok($obj->get_next.'','eq','27 - 31',"Consolidate ASC sort 8");
  cmp_ok($obj->get_next.'','eq','30 - 33',"Consolidate ASC sort 9");
  cmp_ok($obj->get_next.'','eq','30 - 31',"Consolidate ASC sort 10");
  ok(!$obj->get_next,"Iterator should be empty!");
}
{
  my $obj=Data::Range::Compare::Stream::Iterator::Array->new(autosort=>'prepare_for_consolidate_desc');
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
  ok(!$obj->sorted,'object should currently not be sorted!');
  ok($obj->has_next,'After sorting should have next');


  cmp_ok($obj->get_next.'','eq','30 - 33',"Consolidate DESC sort 1");
  ok($obj->has_next,'Consolidate has_next test 1');

  cmp_ok($obj->get_next.'','eq','27 - 31',"Consolidate DESC sort 2");
  ok($obj->has_next,'Consolidate has_next test 2');

  cmp_ok($obj->get_next.'','eq','30 - 31',"Consolidate DESC sort 3");
  ok($obj->has_next,'Consolidate has_next test 3');

  cmp_ok($obj->get_next.'','eq','17 - 29',"Consolidate DESC sort 4");
  ok($obj->has_next,'Consolidate has_next test 4');

  cmp_ok($obj->get_next.'','eq','11 - 15',"Consolidate DESC sort 5");
  ok($obj->has_next,'Consolidate has_next test 5');

  cmp_ok($obj->get_next.'','eq','5 - 9',"Consolidate DESC sort 6");
  ok($obj->has_next,'Consolidate has_next test 6');

  cmp_ok($obj->get_next.'','eq','5 - 7',"Consolidate DESC sort 7");
  ok($obj->has_next,'Consolidate has_next test 7');

  cmp_ok($obj->get_next.'','eq','2 - 3',"Consolidate DESC sort 8");
  ok($obj->has_next,'Consolidate has_next test 8');

  cmp_ok($obj->get_next.'','eq','1 - 2',"Consolidate DESC sort 9");
  ok($obj->has_next,'Consolidate has_next test 9');

  cmp_ok($obj->get_next.'','eq','0 - 0',"Consolidate DESC sort 10");
  ok(!$obj->has_next,'has_next should now return false');

  ok(!$obj->get_next,"Iterator should be empty!");

}
