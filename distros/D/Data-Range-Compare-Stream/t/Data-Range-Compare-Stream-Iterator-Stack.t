use strict;
use warnings;
use Test::More qw(no_plan);

use Data::Range::Compare::Stream::Iterator::Array;
use Data::Range::Compare::Stream;

use File::Temp qw(tempdir);
use File::Basename;


use_ok('Data::Range::Compare::Stream::Iterator::Stack');

{
  my $stack=new Data::Range::Compare::Stream::Iterator::Stack;
  ok($stack,'object should exists');
  ok(!$stack->has_next,'object should be empty');
  my $array=new Data::Range::Compare::Stream::Iterator::Array(sorted=>1);
  $stack->stack_push($array);
  ok(!$stack->has_next,'object should be empty');
  $array->insert_range(Data::Range::Compare::Stream->new(0,0));
  $array->insert_range(Data::Range::Compare::Stream->new(1,2));
  my $array_b=new Data::Range::Compare::Stream::Iterator::Array(sorted=>1);
  $array_b->insert_range(Data::Range::Compare::Stream->new(2,3));
  $stack->stack_push($array);
  $stack->stack_push($array_b);
  
  ok($stack->has_next,'object should not be empty');
  my $list=[
    '0 - 0',
    '1 - 2',
    '2 - 3',
  ];

  my $total=0;
  while($stack->has_next) {
    my $result=$stack->get_next;
    my $string=$result->to_string;
    my $cmp=shift @$list;

    cmp_ok($string,'eq',$cmp,'compare rows');
    ++$total;
  }
  cmp_ok($total,'==',3,'total stack result count');
}

