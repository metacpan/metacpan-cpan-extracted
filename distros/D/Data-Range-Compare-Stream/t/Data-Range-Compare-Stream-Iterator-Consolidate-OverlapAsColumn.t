
use strict;
use warnings;
use Test::More tests=>358;
use Data::Dumper;

use Data::Range::Compare::Stream::Iterator::Compare::Asc;
use Data::Range::Compare::Stream::Iterator::Consolidate;
use Data::Range::Compare::Stream;

use_ok('Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn');
if(1){
  my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
  my @range_set_a=qw(

   0 0
   0 0

   1 4
   2 3
   4 5

   10 20
   11 19
   12 18

   25 31

   33 34

   34 36
   34 36

   35 35
   35 35
   35 35

  );
  my @ranges;
  while(my ($start,$end)=splice(@range_set_a,0,2)) {
    $obj->create_range($start,$end);
  }
  $obj->prepare_for_consolidate_asc;
  my $cmp=new Data::Range::Compare::Stream::Iterator::Compare::Asc;
  my $column_a=Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn->new($obj,$cmp);
  $cmp->add_consolidator($column_a);

  cmp_ok($cmp->get_column_count_human_readable,'==',1,'Default setup shoudl have 1 column');
  {
    ok($column_a->has_next,"column_a should have next");
    my $result=$column_a->get_next;
    cmp_ok($cmp->get_column_count_human_readable,'==',2,'column count ');
    cmp_ok($result->get_common.'','eq',''.'0 - 0','column_a check');
  }
  my $column_b=$cmp->get_iterator_by_id(1);
  {
    ok($column_b->has_next,"column_b should have next");
    my $result=$column_b->get_next;
    cmp_ok($cmp->get_column_count_human_readable,'==',2,'column count ');
    cmp_ok($result->get_common.'','eq',''.'0 - 0','column_a check');
  }
  {
    ok($column_a->has_next,"column_a should have next");
    my $result=$column_a->get_next;
    cmp_ok($cmp->get_column_count_human_readable,'==',2,'column count');
    cmp_ok($result->get_common.'','eq',''.'1 - 4','column_a check');
  }
  {
    ok($column_b->has_next,"column_b should have next");
    my $result=$column_b->get_next;
    cmp_ok($cmp->get_column_count_human_readable,'==',2,'column count ');
    cmp_ok($result->get_common.'','eq',''.'2 - 3','column_a check');
  }
  {
    ok($column_b->has_next,"column_b should have next");
    my $result=$column_b->get_next;
    cmp_ok($cmp->get_column_count_human_readable,'==',2,'column count ');
    cmp_ok($result->get_common.'','eq',''.'4 - 5','column_a check');
  }


  {
    ok($column_a->has_next,"column_a should have next");
    my $result=$column_a->get_next;
    cmp_ok($cmp->get_column_count_human_readable,'==',3,'column count');
    cmp_ok($result->get_common.'','eq',''.'10 - 20','column_a check');
  }
  {
    ok($column_b->has_next,"column_b should have next");
    my $result=$column_b->get_next;
    cmp_ok($cmp->get_column_count_human_readable,'==',3,'column count ');
    cmp_ok($result->get_common.'','eq',''.'11 - 19','column_a check');
  }

  {
    ok($column_a->has_next,"column_a should have next");
    my $result=$column_a->get_next;
    cmp_ok($result->get_common.'','eq',''.'25 - 31','column_a check');
    cmp_ok($cmp->get_column_count_human_readable,'==',3,'column count ');
  }
  my $column_c=$cmp->get_iterator_by_id(2);
  {
    ok($column_c->has_next,"column_c should have next");
    my $result=$column_c->get_next;
    cmp_ok($cmp->get_column_count_human_readable,'==',3,'column count ');
    cmp_ok($result->get_common.'','eq',''.'12 - 18','column_a check');
  }
  {
    ok($column_a->has_next,"column_a should have next");
    my $result=$column_a->get_next;
    cmp_ok($result->get_common.'','eq',''.'33 - 34','column_a check');
    ok(!$column_a->has_next,"column_a should be empty now");
    cmp_ok($cmp->get_column_count_human_readable,'==',6,'Final Column Count');
  }



}
if(1){
  my $cmp=new Data::Range::Compare::Stream::Iterator::Compare::Asc;
  my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
  my @range_set_a=qw(
   0 0
   0 0
   0 0

   0 0
   0 0
   0 0

  );
  my @ranges;
  while(my ($start,$end)=splice(@range_set_a,0,2)) {
    $obj->create_range($start,$end);
  }

  $obj->prepare_for_consolidate_asc;

  my $column_a=Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn->new($obj,$cmp);

  $cmp->add_consolidator($column_a);
  # expecting 1 column
  cmp_ok($cmp->get_column_count_human_readable,'==',1,'Default setup shoudl have 1 column');

  # expecting 6 columns
  {
    ok($column_a->has_next,'column_a should have next');
    my $result=$column_a->get_next;
    cmp_ok($result->get_common.'','eq',''.'0 - 0',"Comon range should be [0 - 0]");
    ok(!$column_a->has_next,'column_a should be empty!');
    cmp_ok($cmp->get_column_count_human_readable,'==',6,'should now have 6 columns');


  }

}
if(1){
  my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
  my @range_set_a=qw(
   0 0
   0 0


   1 4
   2 3
   4 5

   10 20
   11 19
   12 18
  

  );
  my @ranges;
  while(my ($start,$end)=splice(@range_set_a,0,2)) {
    $obj->create_range($start,$end);
  }

  $obj->prepare_for_consolidate_asc;

  my $cmp=new Data::Range::Compare::Stream::Iterator::Compare::Asc;
  my $consolidator=Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn->new($obj,$cmp);
  $cmp->add_consolidator($consolidator);


  cmp_ok($cmp->get_column_count_human_readable,'==',1,'Default setup shoudl have 1 column');

  {
    my $column_a=$cmp->get_iterator_by_id(0);
    ok($column_a->has_next,'iterator should have next');
    {
      my $result=$column_a->get_next;
      cmp_ok($cmp->get_column_count_human_readable,'==',2,'should now have 2 iterators!');
      cmp_ok($result->get_common.'','eq',''.'0 - 0','column_a should be [0 - 0]');
    }
    cmp_ok($column_a->buffer_count,'==',0,'Buffer count should be 1 for column_a');

    my $column_b=$cmp->get_iterator_by_id(1);
    ok($column_a->has_next,'column_b iterator should have next');
    {
      my $result=$column_b->get_next;
      cmp_ok($result->get_common.'','eq',''.'0 - 0','column_a should be [0 - 0]');
      cmp_ok($cmp->get_column_count_human_readable,'==',2,'should now have 2 iterators!');
    }
    cmp_ok($column_a->buffer_count,'==',0,'Buffer count should be 1 for column_a');
    cmp_ok($column_a->buffer_count,'==',0,'Buffer count should be 1 for column_b');
    ok($column_a->has_next,'column_a iterator should have next');
    ok($column_b->has_next,'column_b iterator should have next');

    {
      my $result=$column_a->get_next;
      cmp_ok($cmp->get_column_count_human_readable,'==',2,'should now have 2 iterators!');
      cmp_ok($result->get_common.'','eq',''.'1 - 4','column_a should be [1 - 4]');
    }
    cmp_ok($column_a->buffer_count,'==',0,'Buffer count');
    ok($column_b->has_next,'column_b iterator should now have_next');
    {
      my $result=$column_b->get_next;
      cmp_ok($cmp->get_column_count_human_readable,'==',2,'should now have 2 iterators!');
      cmp_ok($result->get_common.'','eq',''.'2 - 3','column_a should be [2 - 3]');
    }
    cmp_ok($column_a->buffer_count,'==',0,'Buffer count should be 0 for column_a');
    ok($column_a->has_next,'column_a iterator should have next');
    ok($column_b->has_next,'column_b iterator should have next');
    {
      my $result=$column_a->get_next;
      cmp_ok($cmp->get_column_count_human_readable,'==',2,'should now have 2 iterators!');
      cmp_ok($result->get_common.'','eq',''.'10 - 20','column_a should be [10 - 20]');
    }
    ok(!$column_a->has_next,'column_a iterator should not have next');
    cmp_ok($column_a->buffer_count,'==',0,'Buffer count should be 0 for column_a') or diag(Dumper($column_a->{buffer}));
    cmp_ok($column_a->buffer_count,'==',0,'Buffer count should be 0 for column_b');
    {
      my $result=$column_b->get_next;
      cmp_ok($cmp->get_column_count_human_readable,'==',2,'should now have 3 iterators!');
      cmp_ok($result->get_common.'','eq',''.'4 - 5','column_a should be [4 - 5]');
    }
    cmp_ok($column_a->buffer_count,'==',0,'Buffer count should be 0 for column_b');
    ok($column_b->has_next,'column_b iterator should have next');

    {
      my $result=$column_b->get_next;
      cmp_ok($cmp->get_column_count_human_readable,'==',3,'should now have 3 iterators!');
      cmp_ok($result->get_common.'','eq',''.'11 - 19','column_b should be [11 - 19]');
    }
    
    my $column_c=$cmp->get_iterator_by_id(2);
    ok($column_c->has_next,'column_c iterator should have next');
    {
      my $result=$column_c->get_next;
      cmp_ok($cmp->get_column_count_human_readable,'==',3,'should now have 3 iterators!');
      cmp_ok($result->get_common.'','eq',''.'12 - 18','column_c should be [12 - 18]');
    }
    ok(!$column_c->has_next,'column_c is empty');
    ok(!$column_b->has_next,'column_b is empty');
    ok(!$column_a->has_next,'column_a is empty');

  }

}
if(1){
  my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
  my @range_set_a=qw(
   0 0
   0 0


   1 4
   2 3
   4 5

   10 20
   11 19
   12 18

   25 31

   33 34

   34 36
   34 36

   35 35
   35 35
   35 35
  

  );
  my @ranges;
  while(my ($start,$end)=splice(@range_set_a,0,2)) {
    $obj->create_range($start,$end);
  }
  $obj->prepare_for_consolidate_asc;
  my $cmp=new Data::Range::Compare::Stream::Iterator::Compare::Asc;
  my $consolidator=Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn->new($obj,$cmp);

  $cmp->add_consolidator($consolidator);
  cmp_ok($cmp->get_column_count_human_readable,'==',1,'Default setup shoudl have 1 column');

  $cmp->prepare;
  cmp_ok($cmp->get_column_count_human_readable,'==',2,'post prepare should have 2 columns');
  my $column_a=$cmp->get_iterator_by_id(0);
  my $column_b=$cmp->get_iterator_by_id(1);
  {
    ok($column_a->buffer_count,'buffer count check');
    ok($column_b->buffer_count,'buffer count check');
    ok($column_a->has_next,"Column has next check");
    ok($column_b->has_next,"Column has next check");
    cmp_ok($column_a->get_current_result->get_common.'','eq',''.'0 - 0','current iterator column check');
    cmp_ok($column_b->get_current_result->get_common.'','eq',''.'0 - 0','current iterator column check');
    cmp_ok($column_a->get_buffer->[0]->get_common.'','eq',''.'1 - 4','buffer value check');
    cmp_ok($column_b->get_buffer->[0]->get_common.'','eq',''.'2 - 3','buffer value check');
  }
  ok($cmp->has_next,'should have next');# or diag(Dumper($cmp));
  {
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq',''.'0 - 0','First row should be [0 - 0]');
    cmp_ok($result->get_column_by_id(0)->get_common.'','eq',''.'0 - 0',"Column 0 should be [0 - 0]");
    cmp_ok($result->get_column_by_id(1)->get_common.'','eq',''.'0 - 0',"Column 1 should be [0 - 0]");
  }
  ok($cmp->has_next,'should have row 2');
  {
    my $result=$cmp->get_next;
    cmp_ok($cmp->get_column_count_human_readable,'==',2,'has_next should still have 2 columns on row 3');

    cmp_ok($result->get_common.'','eq',''.'1 - 1','2nd row should be [1 - 1]') or die;

    cmp_ok(join(',',@{$result->get_overlap_ids}).'','eq',''.'0',"column overlap id checks");
    cmp_ok($result->get_overlap_count,'==',1,'only 1 column should overlap with [1 - 1]');
    cmp_ok($result->get_column_by_id(0)->get_common.'','eq',''.'1 - 4',"Column 0 should be [1 - 4]");
  }
  ok($cmp->has_next,'should have row 3');
  {
    my $result=$cmp->get_next;
    cmp_ok($cmp->get_column_count_human_readable,'==',3,'has_next should still have 3 columns on row 4');
    cmp_ok($result->get_common.'','eq',''.'2 - 3','3rd row should be [2 - 3]');
    cmp_ok($result->get_overlap_count,'==',2,'2 columns should overlap with [2 - 3]') or diag(Dumper($result));
    cmp_ok($result->get_column_by_id(0)->get_common.'','eq',''.'1 - 4',"Column 0 should be [1 - 4]");
    cmp_ok($result->get_column_by_id(1)->get_common.'','eq',''.'2 - 3',"Column 1 should be [2 - 3]");
  }

  ok($cmp->has_next,'should have row 4');
  {
    my $result=$cmp->get_next;
    cmp_ok($cmp->get_column_count_human_readable,'==',3,'has_next should still have 3 columns on row 5');
    cmp_ok($result->get_common.'','eq',''.'4 - 4','4th row should be [4 - 4]');
    cmp_ok($result->get_overlap_count,'==',2,'2 columns should overlap with [2 - 3]') or diag(Dumper($result));
    cmp_ok($result->get_column_by_id(0)->get_common.'','eq',''.'1 - 4',"Column 0 should be [1 - 4]");
    cmp_ok($result->get_column_by_id(1)->get_common.'','eq',''.'4 - 5',"Column 1 should be [4 - 5]");
  }

  ok($cmp->has_next,'should have row 5');
  {
    my $result=$cmp->get_next;
    cmp_ok($cmp->get_column_count_human_readable,'==',3,'has_next should still have 6 columns on row 6');
    cmp_ok($result->get_common.'','eq',''.'5 - 5','4th row should be [5 - 5]');
    cmp_ok($result->get_overlap_count,'==',1,'1 column should overlaps with [5 - 5]') or diag($result->get_column_by_id(0),$result->get_column_by_id(1));
    cmp_ok($result->get_column_by_id(1)->get_common.'','eq',''.'4 - 5',"Column 1 should be [4 - 5]");
  }
  ok($cmp->has_next,'should have row 6');
  {
    my $result=$cmp->get_next;
    ok($result->is_empty,'row six should be an empty set!');
    cmp_ok($cmp->get_column_count_human_readable,'==',6,'has_next should still have 6 columns on row 7');
    cmp_ok($result->get_common.'','eq',''.'6 - 9',"empty set should be [6 - 9]");
  }
  ok($cmp->has_next,'should have row 7');
  {
    my $result=$cmp->get_next;
    cmp_ok($cmp->get_column_count_human_readable,'==',6,'has_next should have 6 columns on row 8');
    cmp_ok($result->get_overlap_count,'==',1,'1 column should overlaps with [10 - 10]') or diag($result->get_column_by_id(0),$result->get_column_by_id(1));
    cmp_ok($result->get_common.'','eq',''.'10 - 10',"Common range should be [10 - 10]");
  }
  ok($cmp->has_next,'should have row 8');
  {
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq',''.'11 - 11','row 8 should be [11 - 11]');
    cmp_ok($cmp->get_column_count_human_readable,'==',6,'should have 6 columns');
    ok($cmp->get_iterator_by_id(0)->has_next,"iterator sanity check column 0");
    ok($cmp->get_iterator_by_id(1)->has_next,"iterator sanity check column 1");
    ok($cmp->get_iterator_by_id(2)->has_next,"iterator sanity check column 2");
  }
  ok($cmp->has_next,'should have row 9');
  {
    my $result=$cmp->get_next;
    cmp_ok($cmp->get_column_count_human_readable,'==',6,'should have 6 columns');
    cmp_ok($result->get_common.'','eq',''.'12 - 18','row 9 should be [12 - 18]');
  }
  ok($cmp->has_next,'should have row 10');
  {
    my $result=$cmp->get_next;
    cmp_ok($cmp->get_column_count_human_readable,'==',6,'should have 6 columns');
    cmp_ok($result->get_common.'','eq',''.'19 - 19','row 10 should be [19 - 19]');
  }

  ok($cmp->has_next,'should have row 11');
  {
    my $result=$cmp->get_next;
    cmp_ok($cmp->get_column_count_human_readable,'==',6,'should have 6 columns');
    cmp_ok($result->get_common.'','eq',''.'20 - 20','row 10 should be [20 - 20]');
  }
  ok($cmp->has_next,'should have row 12');
  {
    my $result=$cmp->get_next;
    cmp_ok($cmp->get_column_count_human_readable,'==',6,'should have 6 columns');
    cmp_ok($result->get_common.'','eq',''.'21 - 24','row 11 should be [21 - 24]');
  }

  ok($cmp->has_next,'should have row 13');
  {
    my $result=$cmp->get_next;
    cmp_ok($cmp->get_column_count_human_readable,'==',6,'should have 6 columns');
    cmp_ok($result->get_common.'','eq',''.'25 - 31','row 13 should be [25 - 31]');
  }

  ok($cmp->has_next,'should have row 14');
  {
    my $result=$cmp->get_next;
    cmp_ok($cmp->get_column_count_human_readable,'==',6,'should have 6 columns');
    cmp_ok($result->get_common.'','eq',''.'32 - 32','row 14 should be [32 - 32]');
  }
  ok($cmp->has_next,'should have row 15');
  {
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq',''.'33 - 33','row 15 should be [33 - 33]');

    my $result_a=$cmp->get_iterator_by_id(0)->get_current_result;
    my $result_b=$cmp->get_iterator_by_id(1)->get_current_result;
    my $result_c=$cmp->get_iterator_by_id(2)->get_current_result;

    cmp_ok($result_a->get_common.'','eq',''.'33 - 34','Current column should be 33 - 34');
    cmp_ok($result_b->get_common.'','eq',''.'34 - 36','Current column should be 34 - 36');
    cmp_ok($result_c->get_common.'','eq',''.'34 - 36','Current column should be 34 - 36');

    cmp_ok($cmp->get_column_count_human_readable,'==',6,'should have 6 columns');
  }

  ok($cmp->has_next,'should have row 16');
  {
    my $result=$cmp->get_next;
    cmp_ok($cmp->get_column_count_human_readable,'==',6,'should have 6 columns');
    cmp_ok($result->get_common.'','eq',''.'34 - 34','row 16 should be [34 - 34]');
    cmp_ok(join(',',@{$result->get_overlap_ids}).'','eq',''.'0,1,2',"column overlap id checks");
  }

  ok($cmp->has_next,'should have row 17');
  {
    my $result=$cmp->get_next;
    cmp_ok($cmp->get_column_count_human_readable,'==',6,'should have 6 columns');
    cmp_ok($result->get_common.'','eq',''.'35 - 35','row 17 should be [35 - 35]');
  }
  {
    my $result=$cmp->get_next;
    cmp_ok($cmp->get_column_count_human_readable,'==',6,'should have 6 columns');
    cmp_ok($result->get_common.'','eq',''.'36 - 36','row 17 should be [36 - 36]');
  }
  ok(!$cmp->has_next,'compare object should be empty') or (diag(Dumper($cmp->get_next)));
}

if(1){
  my $cmp=new Data::Range::Compare::Stream::Iterator::Compare::Asc;
  my ($column_a,$column_b,$column_c,$column_d);
  {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      1 11
      13 44
      17 24
      55 66
    );
    my @ranges;
    while(my ($start,$end)=splice(@range_set_a,0,2)) {
      $obj->create_range($start,$end);
    }
    $obj->prepare_for_consolidate_asc;
    $column_a=new Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn($obj,$cmp);
    $cmp->add_consolidator($column_a);
  }
  {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      0 1
      2 29
      88 133
    );
    my @ranges;
    while(my ($start,$end)=splice(@range_set_a,0,2)) {
      $obj->create_range($start,$end);
    }
    $obj->prepare_for_consolidate_asc;
    $column_b=new Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn($obj,$cmp);
    $cmp->add_consolidator($column_b);
  }
  {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      17 29
      220 240
      241 250

    );
    my @ranges;
    while(my ($start,$end)=splice(@range_set_a,0,2)) {
      $obj->create_range($start,$end);
    }
    $obj->prepare_for_consolidate_asc;
    $column_c=new Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn($obj,$cmp);
    $cmp->add_consolidator($column_c);
  }
  {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      0 1
      0 0
      1 1
      5 7
      7 9
      11 19
      12 18
      17 29
      220 240
      241 250
    );
    my @ranges;
    while(my ($start,$end)=splice(@range_set_a,0,2)) {
      $obj->create_range($start,$end);
    }
    $obj->prepare_for_consolidate_asc;
    $column_d=new Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn($obj,$cmp);
    $cmp->add_consolidator($column_d);
  }
  cmp_ok($cmp->get_column_count_human_readable,'==',4,'Column count before prepare should be 4');

  {
    ok($column_a->has_next,'column has_next');
    my $result=$column_a->get_next;
    cmp_ok($result->get_common.'','eq',''.'1 - 11','Column check');
    cmp_ok($column_a->buffer_count,'==',0,'buffer count check');
    cmp_ok($cmp->get_column_count_human_readable,'==',4,'Column count check');

    ok($column_a->has_next,'column has_next');
  }
  {
    ok($column_b->has_next,'column has_next');
    my $result=$column_b->get_next;
    cmp_ok($result->get_common.'','eq',''.'0 - 1','Column check');
    cmp_ok($column_b->buffer_count,'==',0,'buffer count check');
    cmp_ok($cmp->get_column_count_human_readable,'==',4,'Column count check');

    ok($column_b->has_next,'column has_next');
  }
  {
    ok($column_c->has_next,'column has_next');
    my $result=$column_c->get_next;
    cmp_ok($result->get_common.'','eq',''.'17 - 29','Column check');
    cmp_ok($column_c->buffer_count,'==',0,'buffer count check');
    cmp_ok($cmp->get_column_count_human_readable,'==',4,'Column count check');

    ok($column_c->has_next,'column has_next');
  }

}
if(1){
  my $cmp=new Data::Range::Compare::Stream::Iterator::Compare::Asc;
  my ($column_a,$column_b,$column_c,$column_d);
  {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      1 11
      13 44
      17 24
      55 66
    );
    my @ranges;
    while(my ($start,$end)=splice(@range_set_a,0,2)) {
      $obj->create_range($start,$end);
    }
    $obj->prepare_for_consolidate_asc;
    $column_a=new Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn($obj,$cmp);
    $cmp->add_consolidator($column_a);
  }
  {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      0 1
      2 29
      88 133
    );
    my @ranges;
    while(my ($start,$end)=splice(@range_set_a,0,2)) {
      $obj->create_range($start,$end);
    }
    $obj->prepare_for_consolidate_asc;
    $column_b=new Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn($obj,$cmp);
    $cmp->add_consolidator($column_b);
  }
  {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      17 29
      220 240
      241 250

    );
    my @ranges;
    while(my ($start,$end)=splice(@range_set_a,0,2)) {
      $obj->create_range($start,$end);
    }
    $obj->prepare_for_consolidate_asc;
    $column_c=new Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn($obj,$cmp);
    $cmp->add_consolidator($column_c);
  }
  {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      0 1
      0 0
      1 1
      5 7
      7 9
      11 19
      12 18
      17 29
      220 240
      241 250
    );
    my @ranges;
    while(my ($start,$end)=splice(@range_set_a,0,2)) {
      $obj->create_range($start,$end);
    }
    $obj->prepare_for_consolidate_asc;
    $column_d=new Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn($obj,$cmp);
    $cmp->add_consolidator($column_d);
  }
  cmp_ok($cmp->get_column_count_human_readable,'==',4,'Column count before prepare should be 4');
  $cmp->prepare;
  {
    ok($cmp->has_next,'compare get_next check');
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq',''.'0 - 0','common row value check');
    cmp_ok($cmp->get_column_count_human_readable,'==',5,'Compare column count');
    cmp_ok(join(',',@{$result->get_overlap_ids}).'','eq',''.'1,3,4',"column overlap id checks");
  }
  {
    ok($cmp->has_next,'compare get_next check');
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq',''.'1 - 1','common row value check');
    cmp_ok($cmp->get_column_count_human_readable,'==',6,'Compare column count');
    cmp_ok(join(',',@{$result->get_overlap_ids}).'','eq',''.'0,1,3,4',"column overlap id checks");
  }
  {
    ok($cmp->has_next,'compare get_next check');
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq',''.'2 - 4','common row value check');
    cmp_ok($cmp->get_column_count_human_readable,'==',6,'Compare column count');
    cmp_ok(join(',',@{$result->get_overlap_ids}).'','eq',''.'0,1',"row 2 - 4 column overlap id checks");
  }
  {
    ok($cmp->has_next,'compare get_next check');
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq',''.'5 - 6','common row value check');
    cmp_ok($cmp->get_column_count_human_readable,'==',6,'Compare column count');
    cmp_ok(join(',',@{$result->get_overlap_ids}).'','eq',''.'0,1,3',"row 5 - 6 column overlap id checks");
  }
  {
    ok($cmp->has_next,'compare get_next check');
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq',''.'7 - 7','common row value check');
    cmp_ok($cmp->get_column_count_human_readable,'==',6,'Compare column count');
    cmp_ok(join(',',@{$result->get_overlap_ids}).'','eq',''.'0,1,3,4',"row 7 - 7 column overlap id checks");
  }
  {
    ok($cmp->has_next,'compare get_next check');
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq',''.'8 - 9','common row value check');
    cmp_ok(join(',',@{$result->get_overlap_ids}).'','eq',''.'0,1,4',"row 8 - 9 column overlap id checks");
    cmp_ok($cmp->get_column_count_human_readable,'==',6,'Compare column count');
  }
  {
    ok($cmp->has_next,'compare get_next check');
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq',''.'10 - 10','common row value check');
    cmp_ok($cmp->get_column_count_human_readable,'==',6,'Compare column count');
    cmp_ok(join(',',@{$result->get_overlap_ids}).'','eq',''.'0,1',"column overlap id checks");
  }
  {
    ok($cmp->has_next,'compare get_next check');
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq',''.'11 - 11','common row value check');
    cmp_ok($cmp->get_column_count_human_readable,'==',7,'Compare column count');
    cmp_ok(join(',',@{$result->get_overlap_ids}).'','eq',''.'0,1,3',"column overlap id checks");
  }
  {
    ok($cmp->has_next,'compare get_next check');
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq',''.'12 - 12','common row value check');
    cmp_ok($cmp->get_column_count_human_readable,'==',7,'Compare column count');
    cmp_ok(join(',',@{$result->get_overlap_ids}).'','eq',''.'1,3,4',"column overlap id checks");
  }
  {
    ok($cmp->has_next,'compare get_next check');
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq',''.'13 - 16','common row value check');
    cmp_ok($cmp->get_column_count_human_readable,'==',7,'Compare column count');
    cmp_ok(join(',',@{$result->get_overlap_ids}).'','eq',''.'0,1,3,4',"column overlap id checks");
  }
  {
    ok($cmp->has_next,'compare get_next check');
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq',''.'17 - 18','common row value check');
    cmp_ok($cmp->get_column_count_human_readable,'==',7,'Compare column count');
    cmp_ok(join(',',@{$result->get_overlap_ids}).'','eq',''.'0,1,2,3,4,5,6',"column overlap id checks");
  }
  {
    ok($cmp->has_next,'compare get_next check');
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq',''.'19 - 19','common row value check');
    cmp_ok($cmp->get_column_count_human_readable,'==',7,'Compare column count');
    cmp_ok(join(',',@{$result->get_overlap_ids}).'','eq',''.'0,1,2,3,5,6',"column overlap id checks");
  }
  {
    ok($cmp->has_next,'compare get_next check');
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq',''.'20 - 24','common row value check');
    cmp_ok($cmp->get_column_count_human_readable,'==',7,'Compare column count');
    cmp_ok(join(',',@{$result->get_overlap_ids}).'','eq',''.'0,1,2,5,6',"column overlap id checks");
  }
  {
    ok($cmp->has_next,'compare get_next check');
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq',''.'25 - 29','common row value check');
    cmp_ok($cmp->get_column_count_human_readable,'==',7,'Compare column count');
    cmp_ok(join(',',@{$result->get_overlap_ids}).'','eq',''.'0,1,2,5',"column overlap id checks");
  }
  {
    ok($cmp->has_next,'compare get_next check');
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq',''.'30 - 44','common row value check');
    cmp_ok($cmp->get_column_count_human_readable,'==',7,'Compare column count');
    cmp_ok(join(',',@{$result->get_overlap_ids}).'','eq',''.'0',"column overlap id checks");
  }
  {
    ok($cmp->has_next,'compare get_next check');
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq',''.'45 - 54','common row value check');
    cmp_ok($cmp->get_column_count_human_readable,'==',7,'Compare column count');
    cmp_ok(join(',',@{$result->get_overlap_ids}).'','eq',''.'',"column overlap id checks");
  }
  {
    ok($cmp->has_next,'compare get_next check');
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq',''.'55 - 66','common row value check');
    cmp_ok($cmp->get_column_count_human_readable,'==',7,'Compare column count');
    cmp_ok(join(',',@{$result->get_overlap_ids}).'','eq',''.'0',"row 55 - 66 column overlap id checks");
  }
  {
    ok($cmp->has_next,'compare get_next check');
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq',''.'67 - 87','common row value check');
    cmp_ok($cmp->get_column_count_human_readable,'==',7,'Compare column count');
    cmp_ok(join(',',@{$result->get_overlap_ids}).'','eq',''.'',"column overlap id checks");
  }
  {
    ok($cmp->has_next,'compare get_next check');
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq',''.'88 - 133','common row value check');
    cmp_ok($cmp->get_column_count_human_readable,'==',7,'Compare column count');
    cmp_ok(join(',',@{$result->get_overlap_ids}).'','eq',''.'1',"row 88 - 133 column overlap id checks");
  }
  {
    ok($cmp->has_next,'compare get_next check');
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq',''.'134 - 219','common row value check');
    cmp_ok($cmp->get_column_count_human_readable,'==',7,'Compare column count');
    cmp_ok(join(',',@{$result->get_overlap_ids}).'','eq',''.'',"column overlap id checks");
  }
  {
    ok($cmp->has_next,'compare get_next check');
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq',''.'220 - 240','common row value check');
    cmp_ok($cmp->get_column_count_human_readable,'==',7,'Compare column count');
    cmp_ok(join(',',@{$result->get_overlap_ids}).'','eq',''.'2,3',"column overlap id checks");
  }
  {
    ok($cmp->has_next,'compare get_next check');
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq',''.'241 - 250','common row value check');
    cmp_ok($cmp->get_column_count_human_readable,'==',7,'Compare column count');
    cmp_ok(join(',',@{$result->get_overlap_ids}).'','eq',''.'2,3',"row 241 - 250 column overlap id checks");
  }
  {
    for(my $x=0;$x<$cmp->get_column_count_human_readable;++$x) {
      my $obj=$cmp->get_iterator_by_id($x);
      #cmp_ok($obj->buffer_count,'==',0,'buffer count check') or diag(Dumper($obj->get_buffer,$obj->get_current_result->get_common.''));
      ok(!$obj->has_next,'iterator should be empty!') or diag('Column id is bad: ',$obj->get_column_id,' current range: ',$obj->get_current_result->get_common,' next range: ',$obj->get_next->get_common);
    }
  }
  ok(!$cmp->has_next,'compare object should be empty now');

}

{
  my $cmp=new Data::Range::Compare::Stream::Iterator::Compare::Asc;
  {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      0 0
      0 0
      0 0

      1 1
      1 1

      2 2
      2 2
      
      4 4
      4 4

    );
    my @ranges;
    while(my ($start,$end)=splice(@range_set_a,0,2)) {
      $obj->create_range($start,$end);
    }
    $obj->prepare_for_consolidate_asc;
    my $column=new Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn($obj,$cmp);
    $cmp->add_consolidator($column);
  }
  {
    ok($cmp->has_next,'cmp has next check');
    my $column_a=$cmp->get_iterator_by_id(0);
    my $column_b=$cmp->get_iterator_by_id(1);
    my $column_c=$cmp->get_iterator_by_id(2);

    cmp_ok($cmp->{raw_row}->[0]->get_common.'','eq',''.'0 - 0','internal raw_row check');
    cmp_ok($cmp->{raw_row}->[1]->get_common.'','eq',''.'0 - 0','internal raw_row check');
    cmp_ok($cmp->{raw_row}->[2]->get_common.'','eq',''.'0 - 0','internal raw_row check');

    my $result=$cmp->get_next;
    cmp_ok($column_a->get_child_column_id,'==',2,'child column_id check');
    cmp_ok($column_c->get_child_column_id,'==',1,'child column_id check');
    cmp_ok($column_b->get_root_column_id,'==',2,'root column_id check');
    cmp_ok($column_c->get_root_column_id,'==',0,'root column_id check');
    cmp_ok($result->get_common.'','eq',''.'0 - 0','column value check');
    cmp_ok($result->get_overlap_count,'==',3,'overlap count check');


  }
  {
    ok($cmp->has_next,'cmp has next check');

    cmp_ok($cmp->{raw_row}->[0]->get_common.'','eq',''.'1 - 1','internal raw_row check');
    cmp_ok($cmp->{raw_row}->[1]->get_common.'','eq',''.'0 - 0','internal raw_row check');
    cmp_ok($cmp->{raw_row}->[2]->get_common.'','eq',''.'1 - 1','internal raw_row check');
    $cmp->delete_iterator(1);

    my $result=$cmp->get_next;

    cmp_ok($cmp->get_iterator_by_id(0)->get_column_id,'==',0,'iterator column_id check');
    cmp_ok($cmp->get_iterator_by_id(1)->get_column_id,'==',1,'iterator column_id check');
    cmp_ok($cmp->get_column_count,'==',1,'column count check');

    cmp_ok($result->get_common.'','eq',''.'1 - 1','column value check');
    cmp_ok($result->get_overlap_count,'==',2,'overlap count check');

  }
  {
    ok($cmp->has_next,'cmp has next check');
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq',''.'2 - 2','column value check');
    cmp_ok($result->get_overlap_count,'==',2,'overlap count check');

    cmp_ok($cmp->get_iterator_by_id(0)->get_column_id,'==',0,'iterator column_id check');
    cmp_ok($cmp->get_iterator_by_id(1)->get_column_id,'==',1,'iterator column_id check');
    cmp_ok($cmp->get_column_count,'==',1,'column count check');

  }
  {
    ok($cmp->has_next,'cmp has next check');
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq',''.'3 - 3','column value check');
    cmp_ok($result->get_overlap_count,'==',0,'overlap count check');

    cmp_ok($cmp->get_iterator_by_id(0)->get_column_id,'==',0,'iterator column_id check');
    cmp_ok($cmp->get_iterator_by_id(1)->get_column_id,'==',1,'iterator column_id check');
    cmp_ok($cmp->get_column_count,'==',1,'column count check');

  }
  {
    ok($cmp->has_next,'cmp has next check');
    cmp_ok($cmp->{raw_row}->[0]->get_common.'','eq',''.'4 - 4','internal raw_row check');
    cmp_ok($cmp->{raw_row}->[1]->get_common.'','eq',''.'4 - 4','internal raw_row check');

    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq',''.'4 - 4','column value check');
    cmp_ok($result->get_overlap_count,'==',2,'overlap count check');
  }
  ok(!$cmp->has_next,'cmp should be empty');

}
{
  my $cmp=new Data::Range::Compare::Stream::Iterator::Compare::Asc;
  {
    my $obj=Data::Range::Compare::Stream::Iterator::Array->new();
    my @range_set_a=qw(
      0 0
      0 0
      0 0

      1 1

      2 2
      
      4 4

    );
    my @ranges;
    while(my ($start,$end)=splice(@range_set_a,0,2)) {
      $obj->create_range($start,$end);
    }
    $obj->prepare_for_consolidate_asc;
    my $column=new Data::Range::Compare::Stream::Iterator::Consolidate::OverlapAsColumn($obj,$cmp);
    $cmp->add_consolidator($column);
  }
  {
    ok($cmp->has_next,'cmp has next check');
    my $column_a=$cmp->get_iterator_by_id(0);
    my $column_b=$cmp->get_iterator_by_id(1);
    my $column_c=$cmp->get_iterator_by_id(2);

    cmp_ok($cmp->{raw_row}->[0]->get_common.'','eq',''.'0 - 0','internal raw_row check');
    cmp_ok($cmp->{raw_row}->[1]->get_common.'','eq',''.'0 - 0','internal raw_row check');
    cmp_ok($cmp->{raw_row}->[2]->get_common.'','eq',''.'0 - 0','internal raw_row check');

    my $result=$cmp->get_next;
    cmp_ok($column_a->get_child_column_id,'==',2,'child column_id check');
    cmp_ok($column_c->get_child_column_id,'==',1,'child column_id check');
    cmp_ok($column_b->get_root_column_id,'==',2,'root column_id check');
    cmp_ok($column_c->get_root_column_id,'==',0,'root column_id check');
    cmp_ok($result->get_common.'','eq',''.'0 - 0','column value check');
    cmp_ok($result->get_overlap_count,'==',3,'overlap count check');


  }
  {
    ok($cmp->has_next,'cmp has next check');

    cmp_ok($cmp->get_iterator_by_id(0)->has_child,'==',1,'iterator has child check');
    cmp_ok($cmp->get_iterator_by_id(0)->is_root,'==',1,'iterator is_root check');
    cmp_ok($cmp->get_iterator_by_id(1)->has_child,'==',0,'iterator has child check');
    cmp_ok($cmp->get_iterator_by_id(1)->has_root,'==',1,'iterator has child check');
    cmp_ok($cmp->get_iterator_by_id(2)->has_root,'==',1,'iterator has child check');
    cmp_ok($cmp->get_iterator_by_id(2)->has_child,'==',1,'iterator has child check');
    cmp_ok($cmp->get_iterator_by_id(2)->is_child,'==',1,'iterator has child check');

    cmp_ok($cmp->{raw_row}->[0]->get_common.'','eq',''.'1 - 1','internal raw_row check');
    cmp_ok($cmp->{raw_row}->[1]->get_common.'','eq',''.'0 - 0','internal raw_row check');
    cmp_ok($cmp->{raw_row}->[2]->get_common.'','eq',''.'0 - 0','internal raw_row check');
    $cmp->delete_iterator(2);
    cmp_ok($cmp->get_iterator_by_id(0)->has_child,'==',0,'iterator has child check');
    cmp_ok($cmp->get_iterator_by_id(1)->has_child,'==',0,'iterator has child check');
    cmp_ok($cmp->get_iterator_by_id(1)->has_root,'==',0,'iterator has_root check');

    my $result=$cmp->get_next;

    cmp_ok($cmp->get_iterator_by_id(0)->get_column_id,'==',0,'iterator column_id check');
    cmp_ok($cmp->get_iterator_by_id(1)->get_column_id,'==',1,'iterator column_id check');
    cmp_ok($cmp->get_column_count,'==',1,'column count check');

    cmp_ok($result->get_common.'','eq',''.'1 - 1','column value check');
    cmp_ok($result->get_overlap_count,'==',1,'overlap count check');

  }
  {
    ok($cmp->has_next,'cmp has next check');
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq',''.'2 - 2','column value check');
    cmp_ok($result->get_overlap_count,'==',1,'overlap count check');

    cmp_ok($cmp->get_iterator_by_id(0)->get_column_id,'==',0,'iterator column_id check');
    cmp_ok($cmp->get_iterator_by_id(1)->get_column_id,'==',1,'iterator column_id check');
    cmp_ok($cmp->get_column_count,'==',1,'column count check');

  }
  {
    ok($cmp->has_next,'cmp has next check');
    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq',''.'3 - 3','column value check');
    cmp_ok($result->get_overlap_count,'==',0,'overlap count check');

    cmp_ok($cmp->get_iterator_by_id(0)->get_column_id,'==',0,'iterator column_id check');
    cmp_ok($cmp->get_iterator_by_id(1)->get_column_id,'==',1,'iterator column_id check');
    cmp_ok($cmp->get_column_count,'==',1,'column count check');

  }
  {
    ok($cmp->has_next,'cmp has next check');
    cmp_ok($cmp->{raw_row}->[0]->get_common.'','eq',''.'4 - 4','internal raw_row check');
    cmp_ok($cmp->{raw_row}->[1]->get_common.'','eq',''.'0 - 0','internal raw_row check');

    my $result=$cmp->get_next;
    cmp_ok($result->get_common.'','eq',''.'4 - 4','column value check');
    cmp_ok($result->get_overlap_count,'==',1,'overlap count check');
  }
  ok(!$cmp->has_next,'cmp should be empty');

}
