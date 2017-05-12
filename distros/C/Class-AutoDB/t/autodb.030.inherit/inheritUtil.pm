package inheritUtil;
use t::lib;
use strict;
use Carp;
use autodbUtil;
use Exporter();

our @ISA=qw(Exporter);
our @EXPORT=(@autodbUtil::EXPORT,
	     qw($class2colls $class2transients $coll2keys label %test_args));

# class2colls for all classes in inherit tests
our $class2colls=
  {c1=>[qw(c1)],
   c2=>[qw(c1 c2)],
   c3=>[qw(c1 c2 c3)],
   t10=>[qw(t10)],
   t11=>[qw(t11)],
   t2=>[qw(t10 t11 t2)],
   t3=>[qw(t10 t11 t2 t3)],
   d1=>[qw(d1)],
   d20=>[qw(d1 d20)],
   d21=>[qw(d1 d21)],
   d3=>[qw(d1 d20 d21 d3)],
   d4=>[qw(d1 d20 d21 d3 d4)],
   d50=>[qw(d1 d20 d21 d3 d4 d50)],
   d51=>[qw(d1 d20 d21 d3 d4 d51)],
   d6=>[qw(d1 d20 d21 d3 d4 d50 d51 d6)],
   d7=>[qw(d1 d20 d21 d3 d4 d50 d51 d6 d7)],
   r1=>[qw(r1)],
   r20=>[qw(r1 r20)],
   r21=>[qw(r1 r21)],
   r22=>[qw(r1 r22)],
   r30=>[qw(r1 r20 r30)],
   r31=>[qw(r1 r21 r31)],
   r32=>[qw(r1 r22 r32)],
   r4=>[qw(r1 r20 r21 r22 r30 r31 r32 r4)],
   r5=>[qw(r1 r20 r21 r22 r30 r31 r32 r4 r5)],
};

# coll2keys for all collections in inherit tests
our $coll2keys=
  {c1=>[[qw(id name id name auto_c1 dflt_c1 other_c1 class_c1 syn_c1)],[]],
   c2=>[[qw(id name id name auto_c2 dflt_c2 other_c2 class_c2 syn_c2)],[]],
   c3=>[[qw(id name id name auto_c3 dflt_c3 other_c3 class_c3 syn_c3)],[]],
   t10=>[[qw(id name id name auto_t10 dflt_t10 other_t10 class_t10 syn_t10)],[]],
   t11=>[[qw(id name id name auto_t11 dflt_t11 other_t11 class_t11 syn_t11)],[]],
   t2=>[[qw(id name id name auto_t2 dflt_t2 other_t2 class_t2 syn_t2)],[]],
   t3=>[[qw(id name id name auto_t3 dflt_t3 other_t3 class_t3 syn_t3)],[]],
   d1=>[[qw(id name id name auto_d1 dflt_d1 other_d1 class_d1 syn_d1)],[]],
   d20=>[[qw(id name id name auto_d20 dflt_d20 other_d20 class_d20 syn_d20)],[]],
   d21=>[[qw(id name id name auto_d21 dflt_d21 other_d21 class_d21 syn_d21)],[]],
   d3=>[[qw(id name id name auto_d3 dflt_d3 other_d3 class_d3 syn_d3)],[]],
   d4=>[[qw(id name id name auto_d4 dflt_d4 other_d4 class_d4 syn_d4)],[]],
   d50=>[[qw(id name id name auto_d50 dflt_d50 other_d50 class_d50 syn_d50)],[]],
   d51=>[[qw(id name id name auto_d51 dflt_d51 other_d51 class_d51 syn_d51)],[]],
   d6=>[[qw(id name id name auto_d6 dflt_d6 other_d6 class_d6 syn_d6)],[]],
   d7=>[[qw(id name id name auto_d7 dflt_d7 other_d7 class_d7 syn_d7)],[]],
   r1=>[[qw(id name id name auto_r1 dflt_r1 other_r1 class_r1 syn_r1)],[]],
   r20=>[[qw(id name id name auto_r20 dflt_r20 other_r20 class_r20 syn_r20)],[]],
   r21=>[[qw(id name id name auto_r21 dflt_r21 other_r21 class_r21 syn_r21)],[]],
   r22=>[[qw(id name id name auto_r22 dflt_r22 other_r22 class_r22 syn_r22)],[]],
   r30=>[[qw(id name id name auto_r30 dflt_r30 other_r30 class_r30 syn_r30)],[]],
   r31=>[[qw(id name id name auto_r31 dflt_r31 other_r31 class_r31 syn_r31)],[]],
   r32=>[[qw(id name id name auto_r32 dflt_r32 other_r32 class_r32 syn_r32)],[]],
   r4=>[[qw(id name id name auto_r4 dflt_r4 other_r4 class_r4 syn_r4)],[]],
   r5=>[[qw(id name id name auto_r5 dflt_r5 other_r5 class_r5 syn_r5)],[]],
  };

# class2transients for all collections in inherit test
our $class2transients={};

# label sub for all inherit 'TestObject' tests
sub label {
  my $test=shift;
  my $object=$test->current_object;
#  $object->id.' '.$object->name if $object;
  (UNIVERSAL::can($object,'name')? $object->name:
   (UNIVERSAL::can($object,'desc')? $object->desc:
    (UNIVERSAL::can($object,'id')? $object->id: '')));
}

our %test_args=(class2colls=>$class2colls,class2transients=>$class2transients,
		coll2keys=>$coll2keys,label=>\&label);

1;
