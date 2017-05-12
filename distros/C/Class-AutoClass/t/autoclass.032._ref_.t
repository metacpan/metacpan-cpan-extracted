use lib qw(t);
use strict;
use Class::AutoClass;
use Test::More;
use Test::Deep;
use autoclassUtil;

# sanity checks
note 'test class prefix is autoclass_032';
my $autoclass=new Class::AutoClass;
is(ref $autoclass,'Class::AutoClass','class is Class::AutoClass - sanity check');

# chain
use autoclass_032::chain::c1;
use autoclass_032::chain::c2;
use autoclass_032::chain::c3;
my $obj=new autoclass_032::chain::c1;
is(ref $obj,'autoclass_032::chain::c1','c1');
my $obj=new autoclass_032::chain::c2;
is(ref $obj,'autoclass_032::chain::c2','c2');
my $obj=new autoclass_032::chain::c3;
is(ref $obj,'autoclass_032::chain::c3','c3');

# trio
use autoclass_032::trio::t10;
use autoclass_032::trio::t11;
use autoclass_032::trio::t2;
use autoclass_032::trio::t3;
my $obj=new autoclass_032::trio::t10;
is(ref $obj,'autoclass_032::trio::t10','t10');
my $obj=new autoclass_032::trio::t11;
is(ref $obj,'autoclass_032::trio::t11','t11');
my $obj=new autoclass_032::trio::t2;
is(ref $obj,'autoclass_032::trio::t2','t2');
my $obj=new autoclass_032::trio::t3;
is(ref $obj,'autoclass_032::trio::t3','t3');

# diamond
use autoclass_032::diamond::d1;
use autoclass_032::diamond::d20;
use autoclass_032::diamond::d21;
use autoclass_032::diamond::d3;
use autoclass_032::diamond::d4;
use autoclass_032::diamond::d50;
use autoclass_032::diamond::d51;
use autoclass_032::diamond::d6;
use autoclass_032::diamond::d7;

my $obj=new autoclass_032::diamond::d1;
is(ref $obj,'autoclass_032::diamond::d1','d1');
my $obj=new autoclass_032::diamond::d20;
is(ref $obj,'autoclass_032::diamond::d20','d20');
my $obj=new autoclass_032::diamond::d21;
is(ref $obj,'autoclass_032::diamond::d21','d21');
my $obj=new autoclass_032::diamond::d3;
is(ref $obj,'autoclass_032::diamond::d3','d3');
my $obj=new autoclass_032::diamond::d4;
is(ref $obj,'autoclass_032::diamond::d4','d4');
my $obj=new autoclass_032::diamond::d50;
is(ref $obj,'autoclass_032::diamond::d50','d50');
my $obj=new autoclass_032::diamond::d51;
is(ref $obj,'autoclass_032::diamond::d51','d51');
my $obj=new autoclass_032::diamond::d6;
is(ref $obj,'autoclass_032::diamond::d6','d6');
my $obj=new autoclass_032::diamond::d7;
is(ref $obj,'autoclass_032::diamond::d7','d7');

# ragged DAG
use autoclass_032::ragged::r1;
use autoclass_032::ragged::r20;
use autoclass_032::ragged::r21;
use autoclass_032::ragged::r22;
use autoclass_032::ragged::r31;
use autoclass_032::ragged::r32;
use autoclass_032::ragged::r4;
use autoclass_032::ragged::r5;

my $obj=new autoclass_032::ragged::r1;
is(ref $obj,'autoclass_032::ragged::r1','r1');
my $obj=new autoclass_032::ragged::r20;
is(ref $obj,'autoclass_032::ragged::r20','r20');
my $obj=new autoclass_032::ragged::r21;
is(ref $obj,'autoclass_032::ragged::r21','r21');
my $obj=new autoclass_032::ragged::r22;
is(ref $obj,'autoclass_032::ragged::r22','r22');
my $obj=new autoclass_032::ragged::r30;
is(ref $obj,'autoclass_032::ragged::r30','r30');
my $obj=new autoclass_032::ragged::r31;
is(ref $obj,'autoclass_032::ragged::r31','r31');
my $obj=new autoclass_032::ragged::r32;
is(ref $obj,'autoclass_032::ragged::r32','r32');
my $obj=new autoclass_032::ragged::r4;
is(ref $obj,'autoclass_032::ragged::r4','r4');
my $obj=new autoclass_032::ragged::r5;
is(ref $obj,'autoclass_032::ragged::r5','r5');

done_testing();
