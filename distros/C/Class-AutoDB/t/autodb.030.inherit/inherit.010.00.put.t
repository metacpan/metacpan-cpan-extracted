use t::lib;
use strict;
use Test::More;

use Class::AutoDB; 
use inheritUtil; use Chain; use Trio; use Diamond; use Ragged;

my($put_type)=@ARGV;
defined $put_type or $put_type='put';

# test all attributes initialied before any calls to _init_self
my @attr_groups=qw(auto other class syn dflt);
# convert list of attrs to format needed by 'new'
sub attrs {
  my %args=(attrs=>[@_]);
  for my $group (@attr_groups) {
    map {$args{$group.'_'.$_}=$_} @_;
  }
#  map {$args{"auto_$_"}=$_} @_;
  %args;
}

# create AutoDB database & SDBM files
my $autodb=new Class::AutoDB(database=>testdb,create=>1); 
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
tie_oid('create');

# %test_args, exported by inheritUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args,put_type=>$put_type);

# chain
my @objects=
  (new c1 (attrs qw(c1)),
   new c2 (attrs qw(c1 c2)),
   new c3 (attrs qw(c1 c2 c3)));
$test->test_put(labelprefix=>"$put_type: chain",objects=>\@objects,correct_diffs=>1);

# trio
my @objects=
  (new t10 (attrs qw(t10)),
   new t11 (attrs qw(t11)),
   new t2 (attrs qw(t10 t11 t2)),
   new t3 (attrs qw(t10 t11 t2 t3)));
$test->test_put(labelprefix=>"$put_type: trio",objects=>\@objects,correct_diffs=>1);

# diamond
my @objects=
  (new d1 (attrs qw(d1)),
   new d20 (attrs qw(d1 d20)),
   new d21 (attrs qw(d1 d21)),
   new d3 (attrs qw(d1 d20 d21 d3)),
   new d4 (attrs qw(d1 d20 d21 d3 d4)),
   new d50 (attrs qw(d1 d20 d21 d3 d4 d50)),
   new d51 (attrs qw(d1 d20 d21 d3 d4 d51)),
   new d6 (attrs qw(d1 d20 d21 d3 d4 d50 d51 d6)),
   new d7 (attrs qw(d1 d20 d21 d3 d4 d50 d51 d6 d7)));
$test->test_put(labelprefix=>"$put_type: diamond",objects=>\@objects,correct_diffs=>1);

# ragged DAG
my @objects=
  (new r1 (attrs qw(r1)),
   new r20 (attrs qw(r1 r20)),
   new r21 (attrs qw(r1 r21)),
   new r22 (attrs qw(r1 r22)),
   new r30 (attrs qw(r1 r20 r30)),
   new r31 (attrs qw(r1 r21 r31)),
   new r32 (attrs qw(r1 r22 r32)),
   new r4 (attrs qw(r1 r20 r21 r22 r30 r31 r32 r4)),
   new r5 (attrs qw(r1 r20 r21 r22 r30 r31 r32 r4 r5)));
$test->test_put(labelprefix=>"$put_type: ragged",objects=>\@objects,correct_diffs=>1);

done_testing();
