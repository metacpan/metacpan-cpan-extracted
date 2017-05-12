use lib qw(t);
use strict;
use Class::AutoClass;
use Test::More;
use Test::Deep;
use autoclassUtil;

# test classes w/ new method that calls SUPER::new when all classes have Class::AutoClass in base
sub cmp_super_new {
  my($actual,$correct,$label)=@_;
  my($package,$file,$line)=caller; # for fails
  my $ok=1;
  $ok&&=cmp_keys($actual,$correct,$label,$file,$line);
  $ok&&=cmp_lists($actual->{new_history},$correct->{new_history},
		       "$label new_history",$file,$line);
  $ok&&=cmp_layers($actual->{init_self_history},$correct->{init_self_history},
		       "$label init_self_history",$file,$line);
  report_pass($ok,$label);
}

# sanity check
my $autoclass=new Class::AutoClass;
is(ref $autoclass,'Class::AutoClass','class is Class::AutoClass - sanity check');

# chain
use autoclass_033::chain::c1;
use autoclass_033::chain::c2;
use autoclass_033::chain::c3;
my $obj=new autoclass_033::chain::c1;
cmp_super_new($obj,{new_history=>[qw(c1)],init_self_history=>[qw(c1)]},'c1');
my $obj=new autoclass_033::chain::c2;
cmp_super_new($obj,{new_history=>[qw(c2)],init_self_history=>[qw(c1 c2)]},'c2');
my $obj=new autoclass_033::chain::c3;
cmp_super_new($obj,{new_history=>[qw(c3)],init_self_history=>[qw(c1 c2 c3)]},'c3');

# trio
use autoclass_033::trio::t10;
use autoclass_033::trio::t11;
use autoclass_033::trio::t2;
use autoclass_033::trio::t3;
my $obj=new autoclass_033::trio::t10;
cmp_super_new($obj,{new_history=>[qw(t10)],init_self_history=>[qw(t10)]},'t10');
my $obj=new autoclass_033::trio::t11;
cmp_super_new($obj,{new_history=>[qw(t11)],init_self_history=>[qw(t11)]},'t11');
my $obj=new autoclass_033::trio::t2;
cmp_super_new($obj,{new_history=>[qw(t2)],init_self_history=>[qw(t10 t11 t2)]},'t2');
my $obj=new autoclass_033::trio::t3;
cmp_super_new($obj,{new_history=>[qw(t3)],init_self_history=>[qw(t10 t11 t2 t3)]},'t3');

# diamond
use autoclass_033::diamond::d1;
use autoclass_033::diamond::d20;
use autoclass_033::diamond::d21;
use autoclass_033::diamond::d3;
use autoclass_033::diamond::d4;
use autoclass_033::diamond::d50;
use autoclass_033::diamond::d51;
use autoclass_033::diamond::d6;
use autoclass_033::diamond::d7;

my $obj=new autoclass_033::diamond::d1;
cmp_super_new($obj,{new_history=>[qw(d1)],init_self_history=>[qw(d1)]},'d1');
my $obj=new autoclass_033::diamond::d20;
cmp_super_new($obj,{new_history=>[qw(d20)],init_self_history=>[qw(d1 d20)]},'d20');
my $obj=new autoclass_033::diamond::d21;
cmp_super_new($obj,{new_history=>[qw(d21)],init_self_history=>[qw(d1 d21)]},'d21');
my $obj=new autoclass_033::diamond::d3;
cmp_super_new($obj,{new_history=>[qw(d3)],init_self_history=>[qw(d1 d20 d21 d3)]},'d3');
my $obj=new autoclass_033::diamond::d4;
cmp_super_new($obj,{new_history=>[qw(d4)],init_self_history=>[qw(d1 d20 d21 d3 d4)]},'d4');
my $obj=new autoclass_033::diamond::d50;
cmp_super_new($obj,{new_history=>[qw(d50)],init_self_history=>[qw(d1 d20 d21 d3 d4 d50)]},'d50');
my $obj=new autoclass_033::diamond::d51;
cmp_super_new($obj,{new_history=>[qw(d51)],init_self_history=>[qw(d1 d20 d21 d3 d4 d51)]},'d51');
my $obj=new autoclass_033::diamond::d6;
cmp_super_new($obj,{new_history=>[qw(d6)],init_self_history=>[qw(d1 d20 d21 d3 d4 d50 d51 d6)]},'d6');
my $obj=new autoclass_033::diamond::d7;
cmp_super_new($obj,{new_history=>[qw(d7)],init_self_history=>[qw(d1 d20 d21 d3 d4 d50 d51 d6 d7)]},'d7');

# ragged DAG
use autoclass_033::ragged::r1;
use autoclass_033::ragged::r20;
use autoclass_033::ragged::r21;
use autoclass_033::ragged::r22;
use autoclass_033::ragged::r31;
use autoclass_033::ragged::r32;
use autoclass_033::ragged::r4;
use autoclass_033::ragged::r5;

my $obj=new autoclass_033::ragged::r1;
cmp_super_new($obj,{new_history=>[qw(r1)],init_self_history=>[qw(r1)]},'r1');
my $obj=new autoclass_033::ragged::r20;
cmp_super_new($obj,{new_history=>[qw(r20)],init_self_history=>[qw(r1 r20)]},'r20');
my $obj=new autoclass_033::ragged::r21;
cmp_super_new($obj,{new_history=>[qw(r21)],init_self_history=>[qw(r1 r21)]},'r21');
my $obj=new autoclass_033::ragged::r22;
cmp_super_new($obj,{new_history=>[qw(r22)],init_self_history=>[qw(r1 r22)]},'r22');
my $obj=new autoclass_033::ragged::r30;
cmp_super_new($obj,{new_history=>[qw(r30)],init_self_history=>[qw(r1 r20 r30)]},'r30');
my $obj=new autoclass_033::ragged::r31;
cmp_super_new($obj,{new_history=>[qw(r31)],init_self_history=>[qw(r1 r21 r31)]},'r31');
my $obj=new autoclass_033::ragged::r32;
cmp_super_new($obj,{new_history=>[qw(r32)],init_self_history=>[qw(r1 r22 r32)]},'r32');
my $obj=new autoclass_033::ragged::r4;
cmp_super_new($obj,{new_history=>[qw(r4)],init_self_history=>[qw(r1 r20 r21 r22 r30 r31 r32 r4)]},'r4');
my $obj=new autoclass_033::ragged::r5;
cmp_super_new($obj,{new_history=>[qw(r5)],init_self_history=>[qw(r1 r20 r21 r22 r30 r31 r32 r4 r5)]},'r5');

done_testing();
