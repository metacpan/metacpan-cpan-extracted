#########################

#######################

package test;
use lib qw(../lib lib .);
use strict;
use warnings;
use Data::Dumper;
require Exporter;
use vars qw(@ISA @list %ids %helper);
@ISA=qw(Data::Range::Compare);
use Data::Range::Compare;

@list=('a' .. 'z');
{my $id=-1; %ids=map { ($_,++$id) } @list; }

$helper{add_one}=\&add_one;
sub add_one {
  my $here=$ids{$_[0]};
  ++$here;
  return 'z' if $#list<$here;
  $list[$here]
}

$helper{sub_one}=\&sub_one;
sub sub_one {
  my $here=$ids{$_[0]};
  --$here;
  return 'a' if $here<0;
  $list[$here]
}
sub cmp_values { $_[0] cmp $_[1] }
$helper{cmp_values}=\&cmp_values;

sub new{
  my ($class,$start,$end,$generated,$missing)=@_;
  $class->SUPER::new(\%helper,$start,$end,$generated,$missing);
}

sub range_compare { 
   my ($s,@args)=@_;
   $s->SUPER::range_compare(\%helper,@args) 
}

1;

package main;
# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(blessed);

my $obj_a=test->new(qw(c f));
my $obj_b=test->new(qw(a z));
my $obj_c=test->new(qw(g j));
ok('f' eq $obj_c->previous_range_end,'previous_range_end');
ok('k' eq $obj_c->next_range_start,'next_range_start');
ok($obj_a,'constructor test');
ok($obj_a->cmp_range_start($obj_a)==0,'compare range start');
ok($obj_a->cmp_range_end($obj_a)==0,'compare range start');
ok($obj_a->cmp_ranges($obj_b)==1,'cmp_ranges $cmp_a $cmp_b');
ok($obj_b->cmp_ranges($obj_a)==-1,'cmp_ranges $cmp_b $cmp_a ');

my $list=[ [$obj_a] ,[$obj_b] ];
my $sub=test->range_compare($list);

my $count=0;
while(my @row=$sub->()) { ++$count }
ok($count==3,'compare_range 1');

$count=0;
$list=[ [$obj_a] ,[$obj_b] ,[$obj_c] ];
$sub=test->range_compare($list);
while(my @row=$sub->()) { ++$count }
ok($count==4,'compare_range 2');
1;
