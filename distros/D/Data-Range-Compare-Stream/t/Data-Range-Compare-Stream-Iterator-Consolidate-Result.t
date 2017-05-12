# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-Range-Compare-Stream.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 42;

BEGIN { use_ok('Data::Range::Compare::Stream') };
BEGIN { use_ok('Data::Range::Compare::Stream::Iterator::Consolidate::Result') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#
# Basic Constructor tests
{
  my $obj=new Data::Range::Compare::Stream::Iterator::Consolidate::Result;
  ok(defined($obj),'Should get an object back from the constructor!');
}
{
  my $obj=Data::Range::Compare::Stream::Iterator::Consolidate::Result->new;
  ok(defined($obj),'Should get an object back from the constructor with the ->new syntax!');
}
{
  my $common=Data::Range::Compare::Stream->new(1,1);
  my $start=Data::Range::Compare::Stream->new(0,1);
  my $end=Data::Range::Compare::Stream->new(1,2);

  my $obj=new Data::Range::Compare::Stream::Iterator::Consolidate::Result($common,$start,$end);
  isa_ok($obj,'Data::Range::Compare::Stream::Iterator::Consolidate::Result');
  $obj=bless $obj,'Data::Range::Compare::Stream::Iterator::Consolidate::Result';
  isa_ok($obj,'Data::Range::Compare::Stream::Iterator::Consolidate::Result');
  ok(defined($obj),'Should get an object back from the constructor when passing arguments in..!');

  cmp_ok($obj->get_common.'','eq',''.$common,'the common range is 1 - 1');
  cmp_ok($obj->get_common_range.'','eq',''.$common,'the common_range');
  cmp_ok($obj->get_start.'','eq',''.$start,'the start range is 0 - 1');
  cmp_ok($obj->get_start_range.'','eq',''.$start,'the start_range');
  cmp_ok($obj->get_end.'','eq',''.$end,'the end range is 1 - 2');
  cmp_ok($obj->get_end_range.'','eq',''.$end,'the end_range');
  ok(!$obj->is_missing,'missing check');
  ok(!$obj->is_generated,'generated check');
}
{
  my $common=Data::Range::Compare::Stream->new(1,1);
  my $start=Data::Range::Compare::Stream->new(0,1);
  my $end=Data::Range::Compare::Stream->new(1,2);

  my $obj=new Data::Range::Compare::Stream::Iterator::Consolidate::Result($common,$start,$end);
  ok(defined($obj),'Should get an object back from the constructor when passing arguments in..!');

  cmp_ok($obj->get_common.'','eq',''.$common,'the common range is 1 - 1');
  cmp_ok($obj->get_common_range.'','eq',''.$common,'the common_range');
  cmp_ok($obj->get_start.'','eq',''.$start,'the start range is 0 - 1');
  cmp_ok($obj->get_start_range.'','eq',''.$start,'the start_range');
  cmp_ok($obj->get_end.'','eq',''.$end,'the end range is 1 - 2');
  cmp_ok($obj->get_end_range.'','eq',''.$end,'the end_range');
  ok(!$obj->is_missing,'missing check');
  ok(!$obj->is_generated,'generated check');
}
{
  my $common=Data::Range::Compare::Stream->new(1,1);
  my $start=Data::Range::Compare::Stream->new(0,1);
  my $end=Data::Range::Compare::Stream->new(1,2);

  my $obj=new Data::Range::Compare::Stream::Iterator::Consolidate::Result($common,$start,$end,1);
  ok(defined($obj),'Should get an object back from the constructor when passing arguments in..!');

  cmp_ok($obj->get_common.'','eq',''.$common,'the common range is 1 - 1');
  cmp_ok($obj->get_common_range.'','eq',''.$common,'the common_range');
  cmp_ok($obj->get_start.'','eq',''.$start,'the start range is 0 - 1');
  cmp_ok($obj->get_start_range.'','eq',''.$start,'the start_range');
  cmp_ok($obj->get_end.'','eq',''.$end,'the end range is 1 - 2');
  cmp_ok($obj->get_end_range.'','eq',''.$end,'the end_range');
  ok($obj->is_missing,'missing check');
  ok(!$obj->is_generated,'generated check');
}
{
  my $common=Data::Range::Compare::Stream->new(1,1);
  my $start=Data::Range::Compare::Stream->new(0,1);
  my $end=Data::Range::Compare::Stream->new(1,2);

  my $obj=new Data::Range::Compare::Stream::Iterator::Consolidate::Result($common,$start,$end,0,1);
  ok(defined($obj),'Should get an object back from the constructor when passing arguments in..!');

  cmp_ok($obj->get_common.'','eq',''.$common,'the common range is 1 - 1');
  cmp_ok($obj->get_common_range.'','eq',''.$common,'the common_range');
  cmp_ok($obj->get_start.'','eq',''.$start,'the start range is 0 - 1');
  cmp_ok($obj->get_start_range.'','eq',''.$start,'the start_range');
  cmp_ok($obj->get_end.'','eq',''.$end,'the end range is 1 - 2');
  cmp_ok($obj->get_end_range.'','eq',''.$end,'the end_range');
  ok(!$obj->is_missing,'missing check');
  ok($obj->is_generated,'generated check');
}
