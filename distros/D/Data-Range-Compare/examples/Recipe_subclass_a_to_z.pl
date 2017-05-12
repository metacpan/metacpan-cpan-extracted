
use lib qw(../lib lib .);
use a_to_z;

my $obj_a=a_to_z->new(qw(c f));
my $obj_b=a_to_z->new(qw(a z));
my $obj_c=a_to_z->new(qw(g j));

$list=[ [$obj_a] ,[$obj_b] ,[$obj_c] ];
$sub=a_to_z->range_compare($list);
while(my @row=$sub->()) { 
  my ($obj_a,$obj_b,$obj_c)=@row;
  my $common_range=a_to_z->get_common_range(\@row);
  print "\n";
  print "Common Range: $common_range\n";
  my ($obj_a,$obj_b,$obj_c)=@row;
  my $range_a_state=$obj_a->missing ?
    'Not in set a'
    :
    'in set a';
  my $range_b_state=$obj_b->missing ?
    'Not in set b'
    :
    'in set b';
  my $range_c_state=$obj_c->missing ?
    'Not in set c'
    :
    'in set c';

  print "Range_a: $obj_a is $range_a_state\n";
  print "Range_b: $obj_b is $range_b_state\n";
  print "Range_c: $obj_c is $range_c_state\n";
}
