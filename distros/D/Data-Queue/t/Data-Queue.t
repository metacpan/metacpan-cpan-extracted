use Modern::Perl;
use Test::More qw(no_plan);
use Data::Dumper;
use Carp qw(confess);
use Data::Dumper;
BEGIN { $SIG{__DIE__} = sub { confess @_ }; }

require_ok('Data::Queue');
use_ok('Data::Queue');


{
  my $stack=new Data::Queue;
  isa_ok($stack,'Data::Queue');
  my @list=$stack->add(1,2,3,4);
  is_deeply(\@list,[1,2,3,4],'ids should match data set');
  ok($stack->has_next,'Should have next');
  isa_ok($stack->has_next,'Data::Result');

  cmp_ok($stack->total,'==',4,"has a total of 4 elements right now") or diag Dumper($stack);
  $stack->remove(3);
  cmp_ok($stack->total,'==',3,"has a total of 3 elements right now") or diag Dumper($stack);

  foreach (1,2,4) {
    my ($id,$value)=$stack->get_next;
    cmp_ok($id,'==',$_,"Next vi is $_") or diag Dumper($stack);
    cmp_ok($value,'==',$_,"Next value is $_") or diag Dumper($stack);
  }
  cmp_ok($stack->total,'==',0,"has a total of 0 elements right now") or diag Dumper($stack);

  cmp_ok(($stack->add(1))[0],'==',5,'next stack element is 5');
  cmp_ok($stack->total,'==',1,"has a total of 1 elements right now") or diag Dumper($stack);

  $stack->add_by_id(3,6);
  {
    my $result=$stack->has_id(3);
    isa_ok($result,$stack->RESULT_CLASS);
    ok($result,'Stack Should have id 3');
  }
  cmp_ok($stack->total,'==',2,"has a total of 2 elements right now") or diag Dumper($stack);
  
  {
    ok($stack->has_next,'Should have another element');
    my ($id,$value)=$stack->get_next;
    cmp_ok($id,'==','3','id should be 3');
    ok(!$stack->has_id($id),"Stack Should no longer have: $id");
    cmp_ok($value,'==',6,'value should be 6');
 }
  {
    ok($stack->has_next,'Should have another element');
    my ($id,$value)=$stack->get_next;
    cmp_ok($id,'==','5','id should be 5');
    cmp_ok($value,'==',1,'value should be 1');
 }
 cmp_ok($stack->total,'==',0,"has a total of 0 elements right now") or diag Dumper($stack);
 cmp_ok($stack->add_by_id(20,1),'==',20,'id should jump to 20');
}
{
  my $stack=new Data::Queue;
  my $id=$stack->add_by_id(11,'testing');
  cmp_ok($id,'==',11,'new id should be 11');
  my @ids=$stack->add(undef);
  cmp_ok($ids[0],'==',12,'new id should be 12') or diag(Dumper $stack);
}


done_testing;
