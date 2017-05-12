use strict;
use warnings;
use Test::More tests=>77;

use Data::Range::Compare::Stream::Iterator::Consolidate;
use Data::Range::Compare::Stream::Iterator::Array;
use Data::Range::Compare::Stream;

use_ok('Data::Range::Compare::Stream::Iterator::Consolidate');
use_ok('Data::Range::Compare::Stream::Iterator::Consolidate::FillMissing');
use_ok('Data::Range::Compare::Stream::Iterator::Consolidate::AdjacentAsc');

{
  my $array=Data::Range::Compare::Stream::Iterator::Array->new;
  $array->create_range(0,0);
  $array->create_range(1,1);
  $array->create_range(3,4);
  $array->create_range(6,7);
  $array->set_sorted(1);
  my $obj=Data::Range::Compare::Stream::Iterator::Consolidate->new($array);
  my $con=new Data::Range::Compare::Stream::Iterator::Consolidate::FillMissing($obj);
  {
    ok($con->has_next,'has_next check');
    my $result=$con->get_next;
    isa_ok($result,$con->NEW_RESULT_FROM,'Result object type check');
    cmp_ok($result->get_common.'','eq',''.'0 - 0','common range check');
    ok(!$result->is_missing,'is missing check');
    ok(!$result->is_generated,'is generated check');
  }
  {
    ok($con->has_next,'has_next check');
    my $result=$con->get_next;
    isa_ok($result,$con->NEW_RESULT_FROM,'Result object type check');
    cmp_ok($result->get_common.'','eq',''.'1 - 1','common range check');
    ok(!$result->is_missing,'is missing check');
    ok(!$result->is_generated,'is generated check');
  }
  {
    ok($con->has_next,'has_next check');
    my $result=$con->get_next;
    isa_ok($result,$con->NEW_RESULT_FROM,'Result object type check');
    cmp_ok($result->get_common.'','eq',''.'2 - 2','common range check');
    ok($result->is_missing,'is missing check');
    ok($result->is_generated,'is generated check');
  }
  {
    ok($con->has_next,'has_next check');
    my $result=$con->get_next;
    isa_ok($result,$con->NEW_RESULT_FROM,'Result object type check');
    cmp_ok($result->get_common.'','eq',''.'3 - 4','common range check');
    ok(!$result->is_missing,'is missing check');
    ok(!$result->is_generated,'is generated check');
  }
  {
    ok($con->has_next,'has_next check');
    my $result=$con->get_next;
    isa_ok($result,$con->NEW_RESULT_FROM,'Result object type check');
    cmp_ok($result->get_common.'','eq',''.'5 - 5','common range check');
    ok($result->is_missing,'is missing check');
    ok($result->is_generated,'is generated check');
  }
  {
    ok($con->has_next,'has_next check');
    my $result=$con->get_next;
    isa_ok($result,$con->NEW_RESULT_FROM,'Result object type check');
    ok(!$result->is_missing,'is missing check');
    ok(!$result->is_generated,'is generated check');
    cmp_ok($result->get_common.'','eq',''.'6 - 7','common range check');
  }
  ok(!$con->has_next,'has_next check');

}
{
  my $array=Data::Range::Compare::Stream::Iterator::Array->new;
  $array->create_range(0,0);
  $array->set_sorted(1);
  my $obj=Data::Range::Compare::Stream::Iterator::Consolidate->new($array);
  my $con=new Data::Range::Compare::Stream::Iterator::Consolidate::FillMissing($obj);
  {
    ok($con->has_next,'has_next check');
    my $result=$con->get_next;
    isa_ok($result,$con->NEW_RESULT_FROM,'Result object type check');
    cmp_ok($result->get_common.'','eq',''.'0 - 0','common range check');
    ok(!$result->is_missing,'is missing check');
    ok(!$result->is_generated,'is generated check');
  }
  ok(!$con->has_next,'has_next check');

}
{
  my $array=Data::Range::Compare::Stream::Iterator::Array->new;
  $array->create_range(0,0);
  $array->create_range(1,1);
  $array->create_range(3,4);
  $array->create_range(6,7);
  $array->set_sorted(1);
  my $obj=Data::Range::Compare::Stream::Iterator::Consolidate->new($array);
  my $obj_b=new Data::Range::Compare::Stream::Iterator::Consolidate::FillMissing($obj);
  my $con=new Data::Range::Compare::Stream::Iterator::Consolidate($obj_b);


  {
    ok($con->has_next,'has_next check');
    my $result=$con->get_next;
    isa_ok($result,$con->RESULT_CLASS,'Result object type check');
    cmp_ok($result->get_common.'','eq',''.'0 - 0','common range check');
    ok(!$result->is_missing,'is missing check');
    ok(!$result->is_generated,'is generated check');
  }
  {
    ok($con->has_next,'has_next check');
    my $result=$con->get_next;
    isa_ok($result,$con->RESULT_CLASS,'Result object type check');
    cmp_ok($result->get_common.'','eq',''.'1 - 1','common range check');
    ok(!$result->is_missing,'is missing check');
    ok(!$result->is_generated,'is generated check');
  }
  {
    ok($con->has_next,'has_next check');
    my $result=$con->get_next;
    isa_ok($result,$con->RESULT_CLASS,'Result object type check');
    cmp_ok($result->get_common.'','eq',''.'2 - 2','common range check');
    ok(!$result->is_missing,'is missing check');
    ok(!$result->is_generated,'is generated check');
  }
  {
    ok($con->has_next,'has_next check');
    my $result=$con->get_next;
    isa_ok($result,$con->RESULT_CLASS,'Result object type check');
    cmp_ok($result->get_common.'','eq',''.'3 - 4','common range check');
    ok(!$result->is_missing,'is missing check');
    ok(!$result->is_generated,'is generated check');
  }
  {
    ok($con->has_next,'has_next check');
    my $result=$con->get_next;
    isa_ok($result,$con->RESULT_CLASS,'Result object type check');
    cmp_ok($result->get_common.'','eq',''.'5 - 5','common range check');
    ok(!$result->is_missing,'is missing check');
    ok(!$result->is_generated,'is generated check');
  }
  {
    ok($con->has_next,'has_next check');
    my $result=$con->get_next;
    isa_ok($result,$con->RESULT_CLASS,'Result object type check');
    ok(!$result->is_missing,'is missing check');
    ok(!$result->is_generated,'is generated check');
    cmp_ok($result->get_common.'','eq',''.'6 - 7','common range check');
  }
  ok(!$con->has_next,'has_next check');

}
{
  my $array=Data::Range::Compare::Stream::Iterator::Array->new;
  $array->create_range(0,0);
  $array->create_range(1,1);
  $array->create_range(3,4);
  $array->create_range(6,7);
  $array->set_sorted(1);
  my $obj=Data::Range::Compare::Stream::Iterator::Consolidate->new($array);
  my $obj_b=new Data::Range::Compare::Stream::Iterator::Consolidate::FillMissing($obj);
  my $con=new Data::Range::Compare::Stream::Iterator::Consolidate::AdjacentAsc($obj_b);


  {
    ok($con->has_next,'has_next check');
    my $result=$con->get_next;
    isa_ok($result,$con->RESULT_CLASS,'Result object type check');
    cmp_ok($result->get_common.'','eq',''.'0 - 7','common range check');
    ok(!$result->is_missing,'is missing check');
    ok($result->is_generated,'is generated check');
  }
  ok(!$con->has_next,'has_next check');

}
