use lib qw(t);
use strict;
use Class::AutoClass;
use Test::More;
use Test::Deep;
use autoclassUtil;

# test all attributes initialied before any calls to _init_self
our @attr_groups=qw(auto other class syn dflt);
sub cmp_attribute_order {
#  my($actual,$correct,$label)=@_;
#  my($actual,$correct_state,$correct_history,$label)=@_;
  my($actual,$correct_history,$label)=@_;
  my($package,$file,$line)=caller; # for fails
  my $correct_state=[([(@$correct_history)x@attr_groups])x@$correct_history];
  my $correct={init_self_state=>$correct_state,
	       init_self_history=>$correct_history};
#   my $correct={init_self_state=>[($correct_history)x@$correct_history],
# 	       init_self_history=>$correct_history};
  # add attributes to $correct: auto, other, dflt (not class, syn)
  for my $group (@attr_groups) {
    next unless $group=~/auto|other|dflt/;
    map {$correct->{$group.'_'.$_}=$_} @{$correct_state->[0]};
  }
  # get complete list of attrs and values
  my @attrs;
  for my $group (@attr_groups) {
    push(@attrs,map {$group.'_'.$_} @$correct_history);
  }
  my @correct_vals=(@$correct_history)x@attr_groups;
  
  my $ok=1;
  $ok&&=cmp_keys($actual,$correct,$label,$file,$line);
  $ok&&=cmp_lists($actual->{init_self_state},$correct->{init_self_state},
		  "$label init_self_state",$file,$line);
  $ok&&=cmp_lists([$actual->get(@attrs)],\@correct_vals,
		  "$label attribute values",$file,$line);
  $ok&&=cmp_layers($actual->{init_self_history},$correct->{init_self_history},
		   "$label init_self_history",$file,$line);
  report_pass($ok,$label);
}

# convert list of attrs to format needed by 'new'
sub attrs {
  my %args=(attrs=>[@_]);
  for my $group (@attr_groups) {
    map {$args{$group.'_'.$_}=$_} @_;
  }
#  map {$args{"auto_$_"}=$_} @_;
  %args;
}

# sanity check
my $autoclass=new Class::AutoClass;
is(ref $autoclass,'Class::AutoClass','class is Class::AutoClass - sanity check');

# chain
use autoclass_039::chain::c1;
use autoclass_039::chain::c2;
use autoclass_039::chain::c3;
my $obj=new autoclass_039::chain::c1 attrs qw(c1);
cmp_attribute_order($obj,[qw(c1)],'c1');
my $obj=new autoclass_039::chain::c2 attrs qw(c1 c2);
cmp_attribute_order($obj,[qw(c1 c2)],'c2');
my $obj=new autoclass_039::chain::c3 attrs qw(c1 c2 c3);
cmp_attribute_order($obj,[qw(c1 c2 c3)],'c3');

# trio
use autoclass_039::trio::t10;
use autoclass_039::trio::t11;
use autoclass_039::trio::t2;
use autoclass_039::trio::t3;
my $obj=new autoclass_039::trio::t10 attrs qw(t10);
cmp_attribute_order($obj,[qw(t10)],'t10');
my $obj=new autoclass_039::trio::t11 attrs qw(t11);
cmp_attribute_order($obj,[qw(t11)],'t11');
my $obj=new autoclass_039::trio::t2 attrs qw(t10 t11 t2);
cmp_attribute_order($obj,[qw(t10 t11 t2)],'t2');
my $obj=new autoclass_039::trio::t3 attrs qw(t10 t11 t2 t3);
cmp_attribute_order($obj,[qw(t10 t11 t2 t3)],'t3');

# diamond
use autoclass_039::diamond::d1;
use autoclass_039::diamond::d20;
use autoclass_039::diamond::d21;
use autoclass_039::diamond::d3;
use autoclass_039::diamond::d4;
use autoclass_039::diamond::d50;
use autoclass_039::diamond::d51;
use autoclass_039::diamond::d6;
use autoclass_039::diamond::d7;

my $obj=new autoclass_039::diamond::d1 attrs qw(d1);
cmp_attribute_order($obj,[qw(d1)],'d1');
my $obj=new autoclass_039::diamond::d20 attrs qw(d1 d20);
cmp_attribute_order($obj,[qw(d1 d20)],'d20');
my $obj=new autoclass_039::diamond::d21 attrs qw(d1 d21);
cmp_attribute_order($obj,[qw(d1 d21)],'d21');
my $obj=new autoclass_039::diamond::d3 attrs qw(d1 d20 d21 d3);
cmp_attribute_order($obj,[qw(d1 d20 d21 d3)],'d3');
my $obj=new autoclass_039::diamond::d4 attrs qw(d1 d20 d21 d3 d4);
cmp_attribute_order($obj,[qw(d1 d20 d21 d3 d4)],'d4');
my $obj=new autoclass_039::diamond::d50 attrs qw(d1 d20 d21 d3 d4 d50);
cmp_attribute_order($obj,[qw(d1 d20 d21 d3 d4 d50)],'d50');
my $obj=new autoclass_039::diamond::d51 attrs qw(d1 d20 d21 d3 d4 d51);
cmp_attribute_order($obj,[qw(d1 d20 d21 d3 d4 d51)],'d51');
my $obj=new autoclass_039::diamond::d6 attrs qw(d1 d20 d21 d3 d4 d50 d51 d6);
cmp_attribute_order($obj,[qw(d1 d20 d21 d3 d4 d50 d51 d6)],'d6');
my $obj=new autoclass_039::diamond::d7 attrs qw(d1 d20 d21 d3 d4 d50 d51 d6 d7);
cmp_attribute_order($obj,[qw(d1 d20 d21 d3 d4 d50 d51 d6 d7)],'d7');

# ragged DAG
use autoclass_039::ragged::r1;
use autoclass_039::ragged::r20;
use autoclass_039::ragged::r21;
use autoclass_039::ragged::r22;
use autoclass_039::ragged::r31;
use autoclass_039::ragged::r32;
use autoclass_039::ragged::r4;
use autoclass_039::ragged::r5;

my $obj=new autoclass_039::ragged::r1 attrs qw(r1);
cmp_attribute_order($obj,[qw(r1)],'r1');
my $obj=new autoclass_039::ragged::r20 attrs qw(r1 r20);
cmp_attribute_order($obj,[qw(r1 r20)],'r20');
my $obj=new autoclass_039::ragged::r21 attrs qw(r1 r21);
cmp_attribute_order($obj,[qw(r1 r21)],'r21');
my $obj=new autoclass_039::ragged::r22 attrs qw(r1 r22);
cmp_attribute_order($obj,[qw(r1 r22)],'r22');
my $obj=new autoclass_039::ragged::r30 attrs qw(r1 r20 r30);
cmp_attribute_order($obj,[qw(r1 r20 r30)],'r30');
my $obj=new autoclass_039::ragged::r31 attrs qw(r1 r21 r31);
cmp_attribute_order($obj,[qw(r1 r21 r31)],'r31');
my $obj=new autoclass_039::ragged::r32 attrs qw(r1 r22 r32);
cmp_attribute_order($obj,[qw(r1 r22 r32)],'r32');
my $obj=new autoclass_039::ragged::r4 attrs qw(r1 r20 r21 r22 r30 r31 r32 r4);
cmp_attribute_order($obj,[qw(r1 r20 r21 r22 r30 r31 r32 r4)],'r4');
my $obj=new autoclass_039::ragged::r5 attrs qw(r1 r20 r21 r22 r30 r31 r32 r4 r5);
cmp_attribute_order($obj,[qw(r1 r20 r21 r22 r30 r31 r32 r4 r5)],'r5');

done_testing();
